import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/produto.dart';
import '../services/produto_service.dart';

class ProdutoFormScreen extends StatefulWidget {
  final Produto? produto;

  const ProdutoFormScreen({super.key, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _precoCustoController = TextEditingController();
  final _porcentagemLucroController = TextEditingController();
  final _precoVendaController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final ProdutoService _service = ProdutoService();
  bool _isLoading = false;
  bool _calculandoAutomaticamente = false; // Evita loop infinito no cálculo

  @override
  void initState() {
    super.initState();

    // Adiciona listeners para cálculo automático
    _precoCustoController.addListener(_calcularPrecoVenda);
    _porcentagemLucroController.addListener(_calcularPrecoVenda);
    _precoVendaController.addListener(_calcularPorcentagemLucro);

    if (widget.produto != null) {
      _nomeController.text = widget.produto!.nome;
      _codigoController.text = widget.produto!.codigo ?? '';
      _categoriaController.text = widget.produto!.categoria;
      _marcaController.text = widget.produto!.marca ?? '';
      _precoCustoController.text = widget.produto!.precoCusto.toString();
      _precoVendaController.text = widget.produto!.precoVenda.toString();
      _quantidadeController.text = widget.produto!.quantidadeEstoque.toString();
      _descricaoController.text = widget.produto!.descricao ?? '';

      // Calcula a porcentagem de lucro inicial
      if (widget.produto!.precoCusto > 0) {
        final porcentagem = ((widget.produto!.precoVenda - widget.produto!.precoCusto) / widget.produto!.precoCusto) * 100;
        _porcentagemLucroController.text = porcentagem.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _precoCustoController.removeListener(_calcularPrecoVenda);
    _porcentagemLucroController.removeListener(_calcularPrecoVenda);
    _precoVendaController.removeListener(_calcularPorcentagemLucro);
    super.dispose();
  }

  // Calcula preço de venda a partir de custo + porcentagem
  void _calcularPrecoVenda() {
    if (_calculandoAutomaticamente) return;
    final custo = _parseDouble(_precoCustoController.text);
    final porcentagem = _parseDouble(_porcentagemLucroController.text);

    if (custo != null && porcentagem != null) {
      _calculandoAutomaticamente = true;
      final precoVenda = custo * (1 + porcentagem / 100);
      _precoVendaController.text = precoVenda.toStringAsFixed(2);
      _calculandoAutomaticamente = false;
    }
  }

  // Calcula porcentagem de lucro a partir de custo + preço de venda
  void _calcularPorcentagemLucro() {
    if (_calculandoAutomaticamente) return;
    final custo = _parseDouble(_precoCustoController.text);
    final venda = _parseDouble(_precoVendaController.text);

    if (custo != null && venda != null && custo > 0) {
      _calculandoAutomaticamente = true;
      final porcentagem = ((venda - custo) / custo) * 100;
      _porcentagemLucroController.text = porcentagem.toStringAsFixed(2);
      _calculandoAutomaticamente = false;
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

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final produto = Produto(
          id: widget.produto?.id,
          nome: _nomeController.text.trim(),
          codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
          categoria: _categoriaController.text.trim(),
          marca: _marcaController.text.trim().isEmpty ? null : _marcaController.text.trim(),
          precoCusto: _parseDouble(_precoCustoController.text) ?? 0,
          precoVenda: _parseDouble(_precoVendaController.text) ?? 0,
          quantidadeEstoque: _parseInt(_quantidadeController.text) ?? 0,
          descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
          dataCadastro: widget.produto?.dataCadastro,
        );

        if (widget.produto == null) {
          await _service.addProduto(produto);
        } else {
          await _service.updateProduto(produto);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Produto ${widget.produto == null ? 'cadastrado' : 'atualizado'} com sucesso!'), backgroundColor: Colors.green),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nomeController, 'Nome do produto *', Icons.inventory_2, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_codigoController, 'Código', Icons.qr_code)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_categoriaController, 'Categoria *', Icons.category, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_marcaController, 'Marca', Icons.branding_watermark),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_precoCustoController, 'Preço de custo *', Icons.attach_money, keyboardType: TextInputType.number, validator: (v) => _parseDouble(v!) == null ? 'Valor inválido' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_porcentagemLucroController, '% Lucro *', Icons.percent, keyboardType: TextInputType.number, validator: (v) => _parseDouble(v!) == null ? 'Valor inválido' : null)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_precoVendaController, 'Preço de venda *', Icons.payments, keyboardType: TextInputType.number, validator: (v) => _parseDouble(v!) == null ? 'Valor inválido' : null),
              const SizedBox(height: 12),
              _buildTextField(_quantidadeController, 'Quantidade em estoque *', Icons.numbers, keyboardType: TextInputType.number, validator: (v) => _parseInt(v!) == null ? 'Quantidade inválida' : null),
              const SizedBox(height: 12),
              _buildTextField(_descricaoController, 'Descrição', Icons.description, maxLines: 3),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
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
                        child: const Text('Salvar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
}