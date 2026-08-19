import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'pdv_screen.dart';

class ComprovanteVendaScreen extends StatefulWidget {
  final List<ItemCarrinho> itens;
  final double totalBruto;
  final double desconto;
  final double totalGeral;
  final FormaPagamento formaPagamento;
  final int parcelas;
  final double valorRecebido;
  final double troco;
  final DateTime data;

  const ComprovanteVendaScreen({
    super.key,
    required this.itens,
    required this.totalBruto,
    required this.desconto,
    required this.totalGeral,
    required this.formaPagamento,
    required this.parcelas,
    required this.valorRecebido,
    required this.troco,
    required this.data,
  });

  @override
  State<ComprovanteVendaScreen> createState() => _ComprovanteVendaScreenState();
}

class _ComprovanteVendaScreenState extends State<ComprovanteVendaScreen> {
  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _nomeFormaPagamento(FormaPagamento fp) {
    return switch(fp) {
      FormaPagamento.dinheiro => 'Dinheiro',
      FormaPagamento.debito => 'Cartão de Débito',
      FormaPagamento.credito => 'Cartão de Crédito',
      FormaPagamento.pix => 'PIX',
    };
  }

  Future<Uint8List> _gerarPdf() async {
    final pdf = pw.Document();
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.data);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('JAIME MOTOS', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F97316'))),
                    pw.Text('COMPROVANTE DE VENDA', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                    pw.Container(height: 3, color: PdfColor.fromHex('#0F172A')),
                    pw.SizedBox(height: 12),
                    pw.Text('Data: $dataFormatada', style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),

              pw.Text('ITENS DA VENDA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Produto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Qtd', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Unitário', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...widget.itens.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(item.produto.nome)),
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('${item.quantidade}')),
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(_formatarMoeda(item.produto.precoVenda))),
                      pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(_formatarMoeda(item.subtotal))),
                    ],
                  )),
                ],
              ),

              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Total Bruto: ............ ${_formatarMoeda(widget.totalBruto)}'),
                    pw.Text('Desconto: ................. - ${_formatarMoeda(widget.desconto)}'),
                    pw.Container(width: 200, height: 1, color: PdfColors.black, margin: pw.EdgeInsets.symmetric(vertical: 4)),
                    pw.Text('TOTAL A PAGAR: ${_formatarMoeda(widget.totalGeral)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F97316'))),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Container(width: double.infinity, height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              pw.Text('FORMA DE PAGAMENTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_nomeFormaPagamento(widget.formaPagamento)),
              if (widget.formaPagamento == FormaPagamento.credito && widget.parcelas > 1)
                pw.Text('${widget.parcelas} x de ${_formatarMoeda(widget.totalGeral / widget.parcelas)}'),
              if (widget.formaPagamento == FormaPagamento.dinheiro) ...[
                pw.Text('Valor Recebido: ${_formatarMoeda(widget.valorRecebido)}'),
                pw.Text('Troco: ${_formatarMoeda(widget.troco)}'),
              ],

              pw.Spacer(),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(width: double.infinity, height: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    pw.Text('Jaime Motos — Oficina de Motos', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 11)),
                    pw.Text('Obrigado pela preferência!', style: pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _enviarPorWhatsApp() async {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(widget.data);
    String texto = '🧾 *COMPROVANTE DE VENDA - JAIME MOTOS*\n';
    texto += 'Data: $dataFormatada\n\n';
    texto += '*ITENS:*\n';
    for (var item in widget.itens) {
      texto += '• ${item.produto.nome} (${item.quantidade}x) — ${_formatarMoeda(item.subtotal)}\n';
    }
    texto += '\n*RESUMO:*\n';
    texto += 'Total Bruto: ${_formatarMoeda(widget.totalBruto)}\n';
    texto += 'Desconto: - ${_formatarMoeda(widget.desconto)}\n';
    texto += '*TOTAL: ${_formatarMoeda(widget.totalGeral)}*\n';
    texto += 'Pagamento: ${_nomeFormaPagamento(widget.formaPagamento)}\n';
    if (widget.formaPagamento == FormaPagamento.credito && widget.parcelas > 1) {
      texto += '${widget.parcelas} x de ${_formatarMoeda(widget.totalGeral / widget.parcelas)}\n';
    }
    if (widget.formaPagamento == FormaPagamento.dinheiro) {
      texto += 'Valor Recebido: ${_formatarMoeda(widget.valorRecebido)}\n';
      texto += 'Troco: ${_formatarMoeda(widget.troco)}\n';
    }

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprovante de Venda'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Enviar por WhatsApp',
            onPressed: _enviarPorWhatsApp,
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _gerarPdf(),
        allowSharing: true,
        allowPrinting: true,
        pdfPreviewPageDecoration: BoxDecoration(color: Colors.grey[100]),
      ),
    );
  }
}