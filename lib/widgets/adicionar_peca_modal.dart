import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/produto.dart';
import '../models/ordem_servico.dart';
import '../services/produto_service.dart';

class AdicionarPecaModal extends StatefulWidget {
  const AdicionarPecaModal({super.key});

  @override
  State<AdicionarPecaModal> createState() => _AdicionarPecaModalState();
}

class _AdicionarPecaModalState extends State<AdicionarPecaModal> {
  final ProdutoService _service = ProdutoService();
  final _buscaController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '1');
  final _precoController = TextEditingController();
  String _busca = '';
  Produto? _produtoSelecionado;

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  int? _parseInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Peça'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _buscaController,
              onChanged: (v) => setState(() => _busca = v.toLowerCase()),
              decoration: InputDecoration(
                labelText: 'Buscar produto',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Selecione o produto:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Produto>>(
                stream: _service.getProdutos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum produto cadastrado'));
                  }

                  final produtos = snapshot.data!.where((p) {
                    return p.nome.toLowerCase().contains(_busca) || (p.codigo ?? '').contains(_busca);
                  }).toList();

                  return ListView.builder(
                    itemCount: produtos.length,
                    itemBuilder: (context, index) {
                      final produto = produtos[index];
                      final selecionado = _produtoSelecionado?.id == produto.id;
                      return ListTile(
                        title: Text(produto.nome, style: TextStyle(fontWeight: selecionado ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text('Estoque: ${produto.quantidadeEstoque} • R\$ ${produto.precoVenda.toStringAsFixed(2).replaceAll('.', ',')}'),
                        trailing: selecionado ? const Icon(Icons.check_circle, color: Color(0xFFF97316)) : null,
                        onTap: () {
                          setState(() {
                            _produtoSelecionado = produto;
                            _precoController.text = produto.precoVenda.toString();
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_produtoSelecionado != null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantidadeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _precoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: InputDecoration(
                        labelText: 'Preço unitário',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final qtd = _parseInt(_quantidadeController.text);
                  final preco = _parseDouble(_precoController.text);
                  if (_produtoSelecionado != null && qtd != null && preco != null && qtd > 0) {
                    final item = ItemOS(
                      produto: _produtoSelecionado!,
                      quantidade: qtd,
                      precoUnitario: preco,
                    );
                    Navigator.pop(context, item);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha todos os campos corretamente!'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Adicionar Peça', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}