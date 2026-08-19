import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/produto_service.dart';
import 'produto_form_screen.dart';

class ProdutoDetalhesScreen extends StatelessWidget {
  final Produto produto;
  final ProdutoService _service = ProdutoService();

  ProdutoDetalhesScreen({super.key, required this.produto});

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProdutoFormScreen(produto: produto)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Excluir',
            onPressed: () => _excluirProduto(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.inventory_2, size: 50, color: Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 24),
            _buildCampo('Nome do produto', produto.nome),
            if (produto.codigo != null && produto.codigo!.isNotEmpty) _buildCampo('Código', produto.codigo!),
            _buildCampo('Categoria', produto.categoria),
            if (produto.marca != null && produto.marca!.isNotEmpty) _buildCampo('Marca', produto.marca!),
            _buildCampo('Preço de custo', _formatarMoeda(produto.precoCusto)),
            _buildCampo('Preço de venda', _formatarMoeda(produto.precoVenda), corValor: const Color(0xFF10B981)),
            _buildCampo(
              'Porcentagem de lucro',
              produto.precoCusto > 0
                  ? '${((produto.precoVenda - produto.precoCusto) / produto.precoCusto * 100).toStringAsFixed(2)}%'
                  : 'N/A',
              corValor: const Color(0xFFF97316),
           ),
            _buildCampo('Quantidade em estoque', '${produto.quantidadeEstoque} unidades', corValor: produto.quantidadeEstoque < 5 ? Colors.red : const Color(0xFF0F172A)),            if (produto.descricao != null && produto.descricao!.isNotEmpty) _buildCampo('Descrição', produto.descricao!),
            if (produto.dataCadastro != null)
              _buildCampo(
                'Data de cadastro',
                '${produto.dataCadastro!.day.toString().padLeft(2, '0')}/${produto.dataCadastro!.month.toString().padLeft(2, '0')}/${produto.dataCadastro!.year}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo(String label, String valor, {Color? corValor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              valor,
              style: TextStyle(fontSize: 16, color: corValor ?? const Color(0xFF0F172A), fontWeight: corValor != null ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirProduto(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text('Tem certeza que deseja excluir ${produto.nome}?'),
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
        await _service.deleteProduto(produto.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído com sucesso!'), backgroundColor: Colors.green),
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