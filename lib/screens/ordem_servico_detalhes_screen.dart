import 'package:flutter/material.dart';
import '../models/ordem_servico.dart';
import '../services/ordem_servico_service.dart';
import 'ordem_servico_form_screen.dart';
import 'comprovante_screen.dart';

class OrdemServicoDetalhesScreen extends StatelessWidget {
  final OrdemServico os;
  final OrdemServicoService _service = OrdemServicoService();

  OrdemServicoDetalhesScreen({super.key, required this.os});

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'N/A';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aberta': return Colors.orange;
      case 'Em andamento': return Colors.blue;
      case 'Concluída': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Detalhes da OS'),
  backgroundColor: const Color(0xFF0F172A),
  foregroundColor: Colors.white,
  actions: [
    IconButton(
      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
      tooltip: 'Comprovante PDF',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ComprovanteScreen(ordemServico: os)),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.edit),
      tooltip: 'Editar',
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrdemServicoFormScreen(ordemServico: os)),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      tooltip: 'Excluir',
      onPressed: () => _excluirOS(context),
    ),
  ],
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(os.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(os.status)),
                ),
                child: Text(
                  os.status.toUpperCase(),
                  style: TextStyle(color: _getStatusColor(os.status), fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dados do Cliente
            _buildSecao('Dados do Cliente'),
            _buildCampo('Nome', os.cliente.nome),
            _buildCampo('Telefone', os.cliente.telefone),
            if (os.cliente.email != null) _buildCampo('E-mail', os.cliente.email!),
            const SizedBox(height: 16),

            // Dados da Moto
            _buildSecao('Dados da Moto'),
            _buildCampo('Modelo', os.modeloMoto),
            _buildCampo('Placa', os.placa),
            _buildCampo('Cor', os.cor),
            if (os.anoFabricacao != null) _buildCampo('Ano Fabricação', os.anoFabricacao.toString()),
            if (os.anoModelo != null) _buildCampo('Ano Modelo', os.anoModelo.toString()),
            const SizedBox(height: 16),

            // Dados da OS
            _buildSecao('Dados da OS'),
            _buildCampo('Mecânico responsável', os.mecanicoResponsavel),
            _buildCampo('Data de abertura', _formatarData(os.dataAbertura)),
            if (os.dataConclusao != null) _buildCampo('Data de conclusão', _formatarData(os.dataConclusao)),
            const SizedBox(height: 16),

            // Problemas e Soluções
            _buildSecao('Problemas Apresentados'),
            _buildCampoTexto(os.problemasApresentados),
            const SizedBox(height: 16),
            _buildSecao('Soluções Aplicadas'),
            _buildCampoTexto(os.solucoesAplicadas.isEmpty ? 'Nenhuma solução registrada' : os.solucoesAplicadas),
            const SizedBox(height: 16),

            // Peças utilizadas
            _buildSecao('Peças Utilizadas'),
            if (os.pecasUtilizadas.isEmpty)
              const Center(child: Text('Nenhuma peça utilizada', style: TextStyle(color: Colors.grey))),
            ...os.pecasUtilizadas.map((peca) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(peca.produto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${peca.quantidade}x ${_formatarMoeda(peca.precoUnitario)}'),
                trailing: Text(_formatarMoeda(peca.valorTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
            )),
            const SizedBox(height: 16),

            // Valores
            _buildSecao('Valores'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildResumo('Total peças', _formatarMoeda(os.valorTotalPecas)),
                  const SizedBox(height: 8),
                  _buildResumo('Mão de obra', _formatarMoeda(os.valorServico)),
                  const Divider(),
                  _buildResumo('TOTAL GERAL', _formatarMoeda(os.valorTotal), destaque: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        titulo,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildCampo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
            child: Text(valor, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoTexto(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Text(texto, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A))),
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

  Future<void> _excluirOS(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir OS?'),
        content: const Text('Tem certeza que deseja excluir esta ordem de serviço?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteOrdemServico(os.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OS excluída com sucesso!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}