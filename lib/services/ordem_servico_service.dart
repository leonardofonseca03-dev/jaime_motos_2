import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ordem_servico.dart';
import '../models/cliente.dart';
import 'cliente_service.dart';
import 'produto_service.dart';

class OrdemServicoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'ordens_servico';
  final ClienteService _clienteService = ClienteService();
  final ProdutoService _produtoService = ProdutoService();

  Stream<List<OrdemServico>> getOrdensServico() {
    return _db
        .collection(collection)
        .orderBy('dataAbertura', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<OrdemServico> ordens = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final clienteId = data['clienteId'];
            final clienteDoc = await _db.collection('clientes').doc(clienteId).get();
            final cliente = Cliente.fromMap(clienteDoc.data()!, clienteDoc.id);
            ordens.add(OrdemServico.fromMap(data, doc.id, cliente));
          }
          return ordens;
        });
  }

  Future<void> addOrdemServico(OrdemServico os) async {
    await _db.collection(collection).add(os.toMap());
  }

  Future<void> updateOrdemServico(OrdemServico os, {bool baixaEstoque = false}) async {
    await _db.collection(collection).doc(os.id).update(os.toMap());

    // Se for concluir a OS, dá baixa no estoque
    if (baixaEstoque && os.status == 'Concluída') {
      for (var item in os.pecasUtilizadas) {
        final produtoDoc = await _db.collection('produtos').doc(item.produto.id).get();
        if (produtoDoc.exists) {
          final estoqueAtual = produtoDoc['quantidadeEstoque'] ?? 0;
          final novoEstoque = estoqueAtual - item.quantidade;
          await _db.collection('produtos').doc(item.produto.id).update({'quantidadeEstoque': novoEstoque});
        }
      }
    }
  }

  Future<void> deleteOrdemServico(String id) async {
    await _db.collection(collection).doc(id).delete();
  }
}