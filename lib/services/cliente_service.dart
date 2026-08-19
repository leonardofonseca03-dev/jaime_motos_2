import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente.dart';

class ClienteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'clientes';

  // Listar todos os clientes
  Stream<List<Cliente>> getClientes() {
    return _db
        .collection(collection)
        .orderBy('nome')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Cliente.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Adicionar novo cliente
  Future<void> addCliente(Cliente cliente) async {
    await _db.collection(collection).add(cliente.toMap());
  }

  // Atualizar cliente existente
  Future<void> updateCliente(Cliente cliente) async {
    await _db.collection(collection).doc(cliente.id).update(cliente.toMap());
  }

  // Excluir cliente
  Future<void> deleteCliente(String id) async {
    await _db.collection(collection).doc(id).delete();
  }
}