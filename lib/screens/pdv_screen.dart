import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import '../models/produto.dart';
import '../services/produto_service.dart';
import 'comprovante_venda_screen.dart';

class PdVScreen extends StatefulWidget {
  const PdVScreen({super.key});

  @override
  State<PdVScreen> createState() => _PdVScreenState();
}

class ItemCarrinho {
  final Produto produto;
  int quantidade;

  ItemCarrinho({required this.produto, this.quantidade = 1});

  double get subtotal => produto.precoVenda * quantidade;
}

class _PdVScreenState extends State<PdVScreen> {
  final ProdutoService _produtoService = ProdutoService();
  List<ItemCarrinho> _carrinho = [];
  String _pesquisa = '';
  final TextEditingController _pesquisaController = TextEditingController();

  List<Produto> _filtrarProdutos(List<Produto> produtos) {
    if (_pesquisa.isEmpty) return produtos;
    return produtos.where((p) {
      final nome = p.nome.toLowerCase();
      final busca = _pesquisa.toLowerCase();
      return nome.contains(busca) || (p.codigo ?? '').contains(busca);
    }).toList();
  }

  void _adicionarAoCarrinho(Produto produto) {
    if (produto.estoqueDisponivel <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto sem estoque!'), backgroundColor: Colors.red),
      );
      return;
    }

    final index = _carrinho.indexWhere((item) => item.produto.id == produto.id);
    if (index >= 0) {
      final novaQtd = _carrinho[index].quantidade + 1;
      if (novaQtd <= produto.estoqueDisponivel) {
        setState(() => _carrinho[index].quantidade = novaQtd);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estoque insuficiente!'), backgroundColor: Colors.orange),
        );
      }
    } else {
      setState(() => _carrinho.add(ItemCarrinho(produto: produto)));
    }
  }

  void _alterarQuantidade(String? produtoId, int delta) {
    final index = _carrinho.indexWhere((item) => item.produto.id == produtoId);
    if (index < 0) return;

    final novaQtd = _carrinho[index].quantidade + delta;
    if (novaQtd <= 0) {
      setState(() => _carrinho.removeAt(index));
    } else if (novaQtd <= _carrinho[index].produto.estoqueDisponivel) {
      setState(() => _carrinho[index].quantidade = novaQtd);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estoque insuficiente!'), backgroundColor: Colors.orange),
      );
    }
  }

  double get _totalGeral {
    return _carrinho.fold(0, (soma, item) => soma + item.subtotal);
  }

  Future<void> _finalizarVenda() async {
    if (_carrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione itens ao carrinho!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar Venda'),
        content: Text('Total: R\$ ${_totalGeral.toStringAsFixed(2).replaceAll('.', ',')}\n\nDeseja confirmar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      for (final item in _carrinho) {
        await _produtoService.atualizarEstoque(item.produto.id!, item.quantidade);
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprovanteVendaScreen(
            itens: List.from(_carrinho),
            total: _totalGeral,
            data: DateTime.now(),
          ),
        ),
      );

      setState(() {
        _carrinho.clear();
        _pesquisaController.clear();
        _pesquisa = '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDV - Ponto de Venda'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _pesquisaController,
              decoration: InputDecoration(
                hintText: 'Buscar produto por nome ou código...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _pesquisa.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _pesquisa = ''))
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (valor) => setState(() => _pesquisa = valor),
            ),
          ),

          Expanded(
            flex: 3,
            child: StreamBuilder<List<Produto>>(
              stream: _produtoService.getProdutos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum produto cadastrado!', style: TextStyle(color: Colors.grey)));
                }
                final produtos = _filtrarProdutos(snapshot.data!);
                if (produtos.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado', style: TextStyle(color: Colors.grey)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _adicionarAoCarrinho(produto),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const Spacer(),
                              Text('Estoque: ${produto.estoqueDisponivel}', style: TextStyle(fontSize: 11, color: produto.estoqueDisponivel > 0 ? Colors.grey[600] : Colors.red)),
                              const SizedBox(height: 4),
                              Text('R\$ ${produto.precoVenda.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Text('Carrinho', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('${_carrinho.length} itens', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: _carrinho.isEmpty
                      ? const Center(child: Text('Toque em um produto para adicionar', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _carrinho.length,
                          itemBuilder: (context, index) {
                            final item = _carrinho[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(item.produto.nome, style: const TextStyle(fontWeight: FontWeight.w500))),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => _alterarQuantidade(item.produto.id, -1),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                    Text('${item.quantidade}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: Color(0xFFF97316), size: 20),
                                      onPressed: () => _alterarQuantidade(item.produto.id, 1),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          Text('R\$ ${_totalGeral.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text('Finalizar Venda', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _finalizarVenda,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}