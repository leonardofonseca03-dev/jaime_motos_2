import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/produto_service.dart';
import 'produto_form_screen.dart';
import 'produto_detalhes_screen.dart';

class ProdutosScreen extends StatelessWidget {
  final ProdutoService _service = ProdutoService();

  ProdutosScreen({super.key});

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProdutoFormScreen()),
            ),
            tooltip: 'Novo Produto',
          ),
        ],
      ),
      body: StreamBuilder<List<Produto>>(
        stream: _service.getProdutos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado ainda!', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }
          final produtos = snapshot.data!;
          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProdutoDetalhesScreen(produto: produto)),
                  ),
                  title: Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${produto.categoria} • Estoque: ${produto.quantidadeEstoque}'),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF10B981),
                    child: const Icon(Icons.inventory_2, color: Colors.white),
                  ),
                  trailing: Text(
                    _formatarMoeda(produto.precoVenda),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProdutoFormScreen()),
        ),
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}