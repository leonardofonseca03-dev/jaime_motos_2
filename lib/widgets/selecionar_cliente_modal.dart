import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';

class SelecionarClienteModal extends StatefulWidget {
  const SelecionarClienteModal({super.key});

  @override
  State<SelecionarClienteModal> createState() => _SelecionarClienteModalState();
}

class _SelecionarClienteModalState extends State<SelecionarClienteModal> {
  final ClienteService _service = ClienteService();
  final _buscaController = TextEditingController();
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Cliente'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _buscaController,
              onChanged: (v) => setState(() => _busca = v.toLowerCase()),
              decoration: InputDecoration(
                labelText: 'Buscar cliente',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Cliente>>(
              stream: _service.getClientes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum cliente cadastrado'));
                }

                final clientes = snapshot.data!.where((c) {
                  return c.nome.toLowerCase().contains(_busca) || c.telefone.contains(_busca);
                }).toList();

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    return ListTile(
                      title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(cliente.telefone),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF97316),
                        child: Text(cliente.nome[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      onTap: () => Navigator.pop(context, cliente),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}