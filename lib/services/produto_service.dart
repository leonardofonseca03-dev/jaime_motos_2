import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto.dart';

class ProdutoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'produtos';

  Stream<List<Produto>> getProdutos() {
    return _db
        .collection(collection)
        .orderBy('nome')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Produto.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addProduto(Produto produto) async {
    await _db.collection(collection).add(produto.toMap());
  }

  Future<void> updateProduto(Produto produto) async {
    await _db.collection(collection).doc(produto.id).update(produto.toMap());
  }

  Future<void> deleteProduto(String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Future<void> atualizarEstoque(String produtoId, int quantidadeVendida) async {
    final doc = await _db.collection(collection).doc(produtoId).get();
    if (doc.exists) {
      final estoqueAtual = doc.data()?['quantidadeEstoque'] ?? 0;
      final novoEstoque = estoqueAtual - quantidadeVendida;
      await _db.collection(collection).doc(produtoId).update({
        'quantidadeEstoque': novoEstoque,
      });
    }
  }
}