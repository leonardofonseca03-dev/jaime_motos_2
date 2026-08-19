import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';
import 'cliente_form_screen.dart';

class ClienteDetalhesScreen extends StatelessWidget {
  final Cliente cliente;
  final ClienteService _service = ClienteService();

  ClienteDetalhesScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Cliente'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: cliente)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Excluir',
            onPressed: () => _excluirCliente(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar com a inicial do nome
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFF97316),
                child: Text(
                  cliente.nome[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildCampo('Nome completo', cliente.nome),
            _buildCampo('CPF/CNPJ', cliente.cpfCnpj),
            _buildCampo('Telefone', cliente.telefone),
            if (cliente.email != null && cliente.email!.isNotEmpty) _buildCampo('E-mail', cliente.email!),
            if (cliente.endereco != null && cliente.endereco!.isNotEmpty) _buildCampo('Endereço', cliente.endereco!),
            if (cliente.observacoes != null && cliente.observacoes!.isNotEmpty) _buildCampo('Observações', cliente.observacoes!),
            if (cliente.dataCadastro != null)
              _buildCampo(
                'Data de cadastro',
                '${cliente.dataCadastro!.day.toString().padLeft(2, '0')}/${cliente.dataCadastro!.month.toString().padLeft(2, '0')}/${cliente.dataCadastro!.year}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo(String label, String valor) {
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
              style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCliente(BuildContext context) async {
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