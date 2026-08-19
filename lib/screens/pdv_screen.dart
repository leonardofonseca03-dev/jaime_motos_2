import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

enum FormaPagamento { dinheiro, debito, credito, pix }

class _PdVScreenState extends State<PdVScreen> {
  final ProdutoService _produtoService = ProdutoService();
  final List<ItemCarrinho> _carrinho = [];
  String _pesquisa = '';
  final TextEditingController _pesquisaController = TextEditingController();

  // NOVOS CAMPOS
  double _descontoPorcento = 0;
  double _descontoValor = 0;
  bool _usarPorcento = true;
  FormaPagamento _formaPagamento = FormaPagamento.dinheiro;
  int _parcelas = 1;
  double _valorRecebido = 0;

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

  double get _totalBruto {
    return _carrinho.fold(0, (soma, item) => soma + item.subtotal);
  }

  double get _valorDesconto {
    if (_usarPorcento) {
      return _totalBruto * (_descontoPorcento / 100);
    }
    return _descontoValor;
  }

  double get _totalGeral {
    return (_totalBruto - _valorDesconto).clamp(0.0, double.infinity);
  }

  double get _troco {
    if (_formaPagamento == FormaPagamento.dinheiro && _valorRecebido >= _totalGeral) {
      return _valorRecebido - _totalGeral;
    }
    return 0;
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _finalizarVenda() async {
    if (_carrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione itens ao carrinho!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_formaPagamento == FormaPagamento.dinheiro && _valorRecebido < _totalGeral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor recebido insuficiente!'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Venda'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Bruto: ${_formatarMoeda(_totalBruto)}'),
              Text('Desconto: ${_formatarMoeda(_valorDesconto)}'),
              Text('TOTAL A PAGAR: ${_formatarMoeda(_totalGeral)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF97316))),
              const SizedBox(height: 8),
              Text('Pagamento: ${_nomeFormaPagamento(_formaPagamento)}'),
              if (_formaPagamento == FormaPagamento.credito) Text('Parcelas: $_parcelas x'),
              if (_formaPagamento == FormaPagamento.dinheiro) ...[
                Text('Valor Recebido: ${_formatarMoeda(_valorRecebido)}'),
                Text('Troco: ${_formatarMoeda(_troco)}', style: const TextStyle(color: Colors.green)),
              ],
            ],
          ),
        ),
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

      await FirebaseFirestore.instance.collection('vendas').add({
        'data': FieldValue.serverTimestamp(),
        'totalBruto': _totalBruto,
        'desconto': _valorDesconto,
        'totalGeral': _totalGeral,
        'formaPagamento': _nomeFormaPagamento(_formaPagamento),
        'parcelas': _parcelas,
        'itens': _carrinho
            .map((item) => {
                  'produtoId': item.produto.id,
                  'produtoNome': item.produto.nome,
                  'quantidade': item.quantidade,
                  'precoUnitario': item.produto.precoVenda,
                  'subtotal': item.subtotal,
                })
            .toList(),
      });

      if (!mounted) return;
      final itensVenda = _carrinho
          .map(
            (item) => ItemCarrinho(
              produto: item.produto,
              quantidade: item.quantidade,
            ),
          )
          .toList();
      final totalBruto = _totalBruto;
      final desconto = _valorDesconto;
      final totalGeral = _totalGeral;
      final valorRecebido = _valorRecebido;
      final troco = _troco;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprovanteVendaScreen(
            itens: itensVenda,
            totalBruto: totalBruto,
            desconto: desconto,
            totalGeral: totalGeral,
            formaPagamento: _formaPagamento,
            parcelas: _parcelas,
            valorRecebido: valorRecebido,
            troco: troco,
            data: DateTime.now(),
          ),
        ),
      );

      setState(() {
        _carrinho.clear();
        _pesquisaController.clear();
        _pesquisa = '';
        _descontoPorcento = 0;
        _descontoValor = 0;
        _valorRecebido = 0;
        _parcelas = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _nomeFormaPagamento(FormaPagamento fp) {
    return switch(fp) {
      FormaPagamento.dinheiro => 'Dinheiro',
      FormaPagamento.debito => 'Cartão de Débito',
      FormaPagamento.credito => 'Cartão de Crédito',
      FormaPagamento.pix => 'PIX',
    };
  }

  // 🔹 BOTÃO PERSONALIZADO SEM LISTRA E MELHOR ALINHADO
  Widget _botaoPagamento(FormaPagamento tipo, IconData icone, String rotulo) {
    final selecionado = _formaPagamento == tipo;
    return InkWell(
      onTap: () => setState(() {
        _formaPagamento = tipo;
        if (_formaPagamento != FormaPagamento.dinheiro) _valorRecebido = 0;
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFF8B5CF6) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selecionado ? const Color(0xFF8B5CF6) : Colors.grey[300]!, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: selecionado ? Colors.white : Colors.black87, size: 20),
            const SizedBox(width: 6),
            Text(rotulo, style: TextStyle(color: selecionado ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
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
                              Text(_formatarMoeda(produto.precoVenda), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
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
                  height: 150,
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
                                    Text(_formatarMoeda(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // 🔹 ÁREA DE DESCONTO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Text('Desconto:'),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('%'),
                        selected: _usarPorcento,
                        onSelected: (_) => setState(() => _usarPorcento = true),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('R\$'),
                        selected: !_usarPorcento,
                        onSelected: (_) => setState(() => _usarPorcento = false),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(hintText: '0', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                          onChanged: (v) {
                            final valor = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                            setState(() {
                              if (_usarPorcento) {
                                _descontoPorcento = valor.clamp(0, 100);
                              } else {
                                _descontoValor = valor;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('(- ${_formatarMoeda(_valorDesconto)})', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                      const SizedBox(height: 8),
                      // 🔹 FORMA DE PAGAMENTO ESTILIZADA
                      const Align(alignment: Alignment.centerLeft, child: Text('Forma de Pagamento:', style: TextStyle(fontWeight: FontWeight.w500))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _botaoPagamento(FormaPagamento.dinheiro, Icons.money, 'Dinheiro'),
                          _botaoPagamento(FormaPagamento.debito, Icons.credit_card, 'Débito'),
                          _botaoPagamento(FormaPagamento.credito, Icons.payment, 'Crédito'),
                          _botaoPagamento(FormaPagamento.pix, Icons.qr_code, 'PIX'),
                        ],
                      ),                      if (_formaPagamento == FormaPagamento.credito) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Parcelas:'),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _parcelas,
                              items: List.generate(12, (i) => i+1).map((n) => DropdownMenuItem(value: n, child: Text('$n x'))).toList(),
                              onChanged: (v) => setState(() => _parcelas = v ?? 1),
                            ),
                            const SizedBox(width: 16),
                            Text('Parcela: ${_formatarMoeda(_totalGeral / _parcelas)}'),
                          ],
                        ),
                      ],
                      if (_formaPagamento == FormaPagamento.dinheiro) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Valor Recebido:'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(hintText: '0,00', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                                onChanged: (v) {
                                  setState(() {
                                    _valorRecebido = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text('Troco: ${_formatarMoeda(_troco)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 🔹 TOTAL E BOTÃO
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Bruto: ${_formatarMoeda(_totalBruto)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('Desconto: - ${_formatarMoeda(_valorDesconto)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                            const SizedBox(height: 4),
                            Text('TOTAL A PAGAR', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                            Text(_formatarMoeda(_totalGeral), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text('Finalizar Venda', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _finalizarVenda,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}