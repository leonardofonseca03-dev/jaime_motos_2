import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ordem_servico.dart';
import '../services/pdf_service.dart';

class ComprovanteScreen extends StatefulWidget {
  final OrdemServico ordemServico;

  const ComprovanteScreen({super.key, required this.ordemServico});

  @override
  State<ComprovanteScreen> createState() => _ComprovanteScreenState();
}

class _ComprovanteScreenState extends State<ComprovanteScreen> {
  Future<void> _compartilharWhatsApp() async {
    final mensagem = '''
📋 ORDEM DE SERVIÇO — JAIME MOTOS

Cliente: ${widget.ordemServico.cliente.nome}
Moto: ${widget.ordemServico.modeloMoto} — ${widget.ordemServico.placa}
Status: ${widget.ordemServico.status}
Valor Total: R\$ ${widget.ordemServico.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}

Segue a Ordem de Serviço!
Jaime Motos — Oficina de Motos
''';

    var telefone = widget.ordemServico.cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!telefone.startsWith('55')) telefone = '55$telefone';

    final uri = Uri.parse('whatsapp://send?phone=$telefone&text=${Uri.encodeComponent(mensagem)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprovante / OS'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF25D366)),
            tooltip: 'Enviar por WhatsApp',
            onPressed: _compartilharWhatsApp,
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async => (await PdfService.gerarOrdemServicoPDF(widget.ordemServico)).save(),
        allowSharing: true,
        allowPrinting: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
      ),
    );
  }
}