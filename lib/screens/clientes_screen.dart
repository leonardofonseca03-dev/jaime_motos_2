import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';
import 'cliente_form_screen.dart';
import 'cliente_detalhes_screen.dart';

class ClientesScreen extends StatelessWidget {
  final ClienteService _service = ClienteService();

  ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClienteFormScreen()),
            ),
            tooltip: 'Novo Cliente',
          ),
        ],
      ),
      body: StreamBuilder<List<Cliente>>(
        stream: _service.getClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum cliente cadastrado ainda!', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }
          final clientes = snapshot.data!;
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClienteDetalhesScreen(cliente: cliente)),
                  ),
                  title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${cliente.telefone}${cliente.email != null ? ' • ${cliente.email}' : ''}'),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF97316),
                    child: Text(cliente.nome[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                      if (value == 'editar') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: cliente)),
                        );
                      } else if (value == 'excluir') {
                        _excluirCliente(context, cliente);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                      const PopupMenuItem(value: 'excluir', child: Text('Excluir', style: TextStyle(color: Colors.red))),
                    ],
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
          MaterialPageRoute(builder: (_) => const ClienteFormScreen()),
        ),
        backgroundColor: const Color(0xFFF97316),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _excluirCliente(BuildContext context, Cliente cliente) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text('Tem certeza que deseja excluir ${cliente.nome}?'),
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
        await _service.deleteCliente(cliente.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente excluído com sucesso!'), backgroundColor: Colors.green),
          );
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