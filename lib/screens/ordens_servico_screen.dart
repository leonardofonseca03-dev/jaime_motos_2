import 'package:flutter/material.dart';
import '../models/ordem_servico.dart';
import '../services/ordem_servico_service.dart';
import 'ordem_servico_form_screen.dart';
import 'ordem_servico_detalhes_screen.dart';

class OrdensServicoScreen extends StatelessWidget {
  final OrdemServicoService _service = OrdemServicoService();

  OrdensServicoScreen({super.key});

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarData(DateTime? data) {
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aberta': return Colors.orange;
      case 'Em andamento': return Colors.blue;
      case 'Concluída': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdemServicoFormScreen()),
            ),
            tooltip: 'Nova OS',
          ),
        ],
      ),
      body: StreamBuilder<List<OrdemServico>>(
        stream: _service.getOrdensServico(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma OS cadastrada ainda!', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }
          final ordens = snapshot.data!;
          return ListView.builder(
            itemCount: ordens.length,
            itemBuilder: (context, index) {
              final os = ordens[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrdemServicoDetalhesScreen(os: os)),
                  ),
                  title: Text(os.cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${os.modeloMoto} • ${os.placa}\n${_formatarData(os.dataAbertura)}'),
                  isThreeLine: true,
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(os.status).withOpacity(0.1),
                    child: Icon(Icons.description, color: _getStatusColor(os.status)),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatarMoeda(os.valorTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(os.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(os.status, style: TextStyle(fontSize: 11, color: _getStatusColor(os.status), fontWeight: FontWeight.bold)),
                      ),
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
          MaterialPageRoute(builder: (_) => const OrdemServicoFormScreen()),
        ),
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}