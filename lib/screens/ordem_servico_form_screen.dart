import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ordem_servico.dart';
import '../models/cliente.dart';
import '../services/ordem_servico_service.dart';
import '../widgets/selecionar_cliente_modal.dart';
import '../widgets/adicionar_peca_modal.dart';

class OrdemServicoFormScreen extends StatefulWidget {
  final OrdemServico? ordemServico;

  const OrdemServicoFormScreen({super.key, this.ordemServico});

  @override
  State<OrdemServicoFormScreen> createState() => _OrdemServicoFormScreenState();
}

class _OrdemServicoFormScreenState extends State<OrdemServicoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Cliente? _clienteSelecionado;
  final _modeloController = TextEditingController();
  final _placaController = TextEditingController();
  final _corController = TextEditingController();
  final _anoFabController = TextEditingController();
  final _anoModController = TextEditingController();
  final _mecanicoController = TextEditingController();
  final _problemasController = TextEditingController();
  final _solucoesController = TextEditingController();
  final _valorServicoController = TextEditingController(text: '0');
  List<ItemOS> _pecas = [];
  String _status = 'Aberta';
  final OrdemServicoService _service = OrdemServicoService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.ordemServico != null) {
      final os = widget.ordemServico!;
      _clienteSelecionado = os.cliente;
      _modeloController.text = os.modeloMoto;
      _placaController.text = os.placa;
      _corController.text = os.cor;
      _anoFabController.text = os.anoFabricacao?.toString() ?? '';
      _anoModController.text = os.anoModelo?.toString() ?? '';
      _mecanicoController.text = os.mecanicoResponsavel;
      _problemasController.text = os.problemasApresentados;
      _solucoesController.text = os.solucoesAplicadas;
      _valorServicoController.text = os.valorServico.toString();
      _pecas = List.from(os.pecasUtilizadas);
      _status = os.status;
    }
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  int? _parseInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  double get _valorTotalPecas => _pecas.fold(0, (soma, item) => soma + item.valorTotal);
  double get _valorTotal => _valorTotalPecas + (_parseDouble(_valorServicoController.text) ?? 0);

  Future<void> _selecionarCliente() async {
    final cliente = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarClienteModal()),
    );
    if (cliente != null && cliente is Cliente) {
      setState(() => _clienteSelecionado = cliente);
    }
  }

  Future<void> _adicionarPeca() async {
    final peca = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdicionarPecaModal()),
    );
    if (peca != null && peca is ItemOS) {
      setState(() => _pecas.add(peca));
    }
  }

  void _removerPeca(int index) {
    setState(() => _pecas.removeAt(index));
  }

  void _alterarQuantidadePeca(int index, int delta) {
    setState(() {
      final novaQtd = _pecas[index].quantidade + delta;
      if (novaQtd >= 1) {
        _pecas[index].quantidade = novaQtd;
      }
    });
  }

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate() && _clienteSelecionado != null) {
      setState(() => _isLoading = true);
      try {
        final os = OrdemServico(
          id: widget.ordemServico?.id,
          cliente: _clienteSelecionado!,
          modeloMoto: _modeloController.text.trim(),
          placa: _placaController.text.trim(),
          cor: _corController.text.trim(),
          anoFabricacao: _parseInt(_anoFabController.text),
          anoModelo: _parseInt(_anoModController.text),
          mecanicoResponsavel: _mecanicoController.text.trim(),
          problemasApresentados: _problemasController.text.trim(),
          solucoesAplicadas: _solucoesController.text.trim(),
          pecasUtilizadas: _pecas,
          valorServico: _parseDouble(_valorServicoController.text) ?? 0,
          status: _status,
          dataAbertura: widget.ordemServico?.dataAbertura,
          dataConclusao: _status == 'Concluída' ? DateTime.now() : null,
        );

        final concluiu = widget.ordemServico?.status != 'Concluída' && _status == 'Concluída';

        if (widget.ordemServico == null) {
          await _service.addOrdemServico(os);
        } else {
          await _service.updateOrdemServico(os, baixaEstoque: concluiu);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OS ${widget.ordemServico == null ? 'criada' : 'atualizada'} com sucesso!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ordemServico == null ? 'Nova Ordem de Serviço' : 'Editar OS'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seleção de Cliente
              const Text('Cliente *', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selecionarCliente,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: _clienteSelecionado == null ? Border.all(color: Colors.red) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(_clienteSelecionado != null ? Icons.person : Icons.person_add, color: const Color(0xFF0F172A)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _clienteSelecionado != null ? _clienteSelecionado!.nome : 'Clique para selecionar um cliente',
                          style: TextStyle(color: _clienteSelecionado != null ? const Color(0xFF0F172A) : Colors.grey),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dados da Moto
              _buildTextField(_modeloController, 'Modelo da moto *', Icons.two_wheeler, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_placaController, 'Placa *', Icons.confirmation_number, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_corController, 'Cor *', Icons.color_lens, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_anoFabController, 'Ano Fab.', Icons.calendar_today, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_anoModController, 'Ano Modelo', Icons.calendar_month, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_mecanicoController, 'Mecânico responsável *', Icons.build, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 12),
              _buildTextField(_problemasController, 'Problemas apresentados *', Icons.report_problem, maxLines: 3, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 12),
              _buildTextField(_solucoesController, 'Soluções aplicadas', Icons.handyman, maxLines: 3),
              const SizedBox(height: 16),

              // Status
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'Aberta', child: Text('Aberta')),
                  DropdownMenuItem(value: 'Em andamento', child: Text('Em andamento')),
                  DropdownMenuItem(value: 'Concluída', child: Text('Concluída')),
                ],
                onChanged: (v) => setState(() => _status = v!),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // Peças utilizadas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Peças utilizadas', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  TextButton.icon(
                    onPressed: _adicionarPeca,
                    icon: const Icon(Icons.add, color: Color(0xFFF97316)),
                    label: const Text('Adicionar peça', style: TextStyle(color: Color(0xFFF97316))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_pecas.isEmpty)
                const Center(child: Text('Nenhuma peça adicionada', style: TextStyle(color: Colors.grey))),
                          ..._pecas.asMap().entries.map((entry) {
              final index = entry.key;
              final peca = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(peca.produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _removerPeca(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Botão diminuir
                          IconButton(
                            onPressed: () => _alterarQuantidadePeca(index, -1),
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF0F172A)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                          // Quantidade
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${peca.quantidade}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Botão aumentar
                          IconButton(
                            onPressed: () => _alterarQuantidadePeca(index, 1),
                            icon: const Icon(Icons.add_circle, color: Color(0xFFF97316)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                          const SizedBox(width: 12),
                          // Preço unitário
                          Text(
                            'R\$ ${peca.precoUnitario.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          // Valor total da peça
                          Text(
                            'R\$ ${peca.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
              const SizedBox(height: 12),
              _buildTextField(_valorServicoController, 'Valor da mão de obra (R\$)', Icons.build_circle, keyboardType: TextInputType.number),
              const SizedBox(height: 16),

              // Resumo de valores
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildResumo('Total peças', 'R\$ ${_valorTotalPecas.toStringAsFixed(2).replaceAll('.', ',')}'),
                    const SizedBox(height: 8),
                    _buildResumo('Mão de obra', 'R\$ ${(_parseDouble(_valorServicoController.text) ?? 0).toStringAsFixed(2).replaceAll('.', ',')}'),
                    const Divider(),
                    _buildResumo('TOTAL GERAL', 'R\$ ${_valorTotal.toStringAsFixed(2).replaceAll('.', ',')}', destaque: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Salvar OS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0F172A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }

  Widget _buildResumo(String label, String valor, {bool destaque = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: destaque ? 18 : 14, fontWeight: destaque ? FontWeight.bold : FontWeight.normal, color: destaque ? const Color(0xFFF97316) : const Color(0xFF0F172A))),
        Text(valor, style: TextStyle(fontSize: destaque ? 18 : 14, fontWeight: destaque ? FontWeight.bold : FontWeight.normal, color: destaque ? const Color(0xFFF97316) : const Color(0xFF0F172A))),
      ],
    );
  }
}