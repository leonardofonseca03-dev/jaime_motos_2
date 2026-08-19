import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/ordem_servico.dart';

class PdfService {
  static Future<pw.Document> gerarOrdemServicoPDF(OrdemServico os) async {
    final pdf = pw.Document();
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(os.dataAbertura ?? DateTime.now());
    final dataConclusao = os.dataConclusao != null
        ? DateFormat('dd/MM/yyyy').format(os.dataConclusao!)
        : 'Em andamento';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('JAIME MOTOS', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F97316'))),
                    pw.Text('Ordem de Serviço', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                    pw.Container(height: 3, color: PdfColor.fromHex('#0F172A')),
                    pw.SizedBox(height: 16),
                  ],
                ),
              ),

              // Dados da OS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nº OS: ${os.id?.substring(0, 8).toUpperCase() ?? '---'}', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Data: $dataFormatada'),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(color: _getStatusCor(os.status), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Text(os.status, style: const pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),

              // Dados do Cliente
              pw.Text('DADOS DO CLIENTE', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Text('Nome: ${os.cliente.nome}'),
              pw.Text('Telefone: ${os.cliente.telefone}'),
              if (os.cliente.email != null) pw.Text('E-mail: ${os.cliente.email}'),
              pw.SizedBox(height: 16),

              // Dados da Moto
              pw.Text('DADOS DA MOTO', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Text('Modelo: ${os.modeloMoto}'),
              pw.Text('Placa: ${os.placa} • Cor: ${os.cor}'),
              if (os.anoFabricacao != null || os.anoModelo != null)
                pw.Text('Ano: ${os.anoFabricacao ?? '---'} / ${os.anoModelo ?? '---'}'),
              pw.Text('Mecânico: ${os.mecanicoResponsavel}'),
              pw.Text('Conclusão: $dataConclusao'),
              pw.SizedBox(height: 16),

              // Problemas e Soluções
              pw.Text('PROBLEMAS APRESENTADOS', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Text(os.problemasApresentados),
              pw.SizedBox(height: 16),

              if (os.solucoesAplicadas.isNotEmpty) ...[
                pw.Text('SOLUÇÕES APLICADAS', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Container(height: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Text(os.solucoesAplicadas),
                pw.SizedBox(height: 16),
              ],

              // Peças
              pw.Text('PEÇAS UTILIZADAS', style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              if (os.pecasUtilizadas.isEmpty)
                pw.Text('Nenhuma peça utilizada', style: const pw.TextStyle(color: PdfColors.grey500))
              else ...[
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Produto', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qtd', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Unitário', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...os.pecasUtilizadas.map((peca) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(peca.produto.nome)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${peca.quantidade}')),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatarMoeda(peca.precoUnitario))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatarMoeda(peca.valorTotal))),
                      ],
                    )),
                  ],
                ),
              ],
              pw.SizedBox(height: 20),

              // Valores
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Total Peças:   ${_formatarMoeda(os.valorTotalPecas)}'),
                    pw.Text('Mão de Obra:   ${_formatarMoeda(os.valorServico)}'),
                    pw.SizedBox(height: 4),
                    pw.Container(width: 200, height: 2, color: PdfColors.black),
                    pw.Text('VALOR TOTAL:  ${_formatarMoeda(os.valorTotal)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F97316'))),
                  ],
                ),
              ),

              pw.Spacer(),

              // Rodapé
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(height: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    pw.Text('Jaime Motos — Oficina de Motos', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 11)),
                    pw.Text('Documento emitido em ${DateFormat('dd/MM/yyyy às HH:mm').format(DateTime.now())}', style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static PdfColor _getStatusCor(String status) {
    switch (status) {
      case 'Aberta': return PdfColor.fromHex('#F97316');
      case 'Em andamento': return PdfColor.fromHex('#3B82F6');
      case 'Concluída': return PdfColor.fromHex('#10B981');
      default: return PdfColors.grey;
    }
  }

  static String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}