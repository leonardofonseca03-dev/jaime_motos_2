import 'cliente.dart';
import 'produto.dart';

class ItemOS {
  Produto produto;
  int quantidade;
  double precoUnitario;

  ItemOS({
    required this.produto,
    required this.quantidade,
    required this.precoUnitario,
  });

  double get valorTotal => quantidade * precoUnitario;

  Map<String, dynamic> toMap() {
    return {
      'produtoId': produto.id,
      'produtoNome': produto.nome,
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
    };
  }
}

class OrdemServico {
  String? id;
  Cliente cliente;
  String modeloMoto;
  String placa;
  String cor;
  int? anoFabricacao;
  int? anoModelo;
  String mecanicoResponsavel;
  String problemasApresentados;
  String solucoesAplicadas;
  List<ItemOS> pecasUtilizadas;
  double valorServico;
  String status; // Aberta, Em andamento, Concluída
  DateTime? dataAbertura;
  DateTime? dataConclusao;

  OrdemServico({
    this.id,
    required this.cliente,
    required this.modeloMoto,
    required this.placa,
    required this.cor,
    this.anoFabricacao,
    this.anoModelo,
    required this.mecanicoResponsavel,
    required this.problemasApresentados,
    this.solucoesAplicadas = '',
    this.pecasUtilizadas = const [],
    this.valorServico = 0,
    this.status = 'Aberta',
    this.dataAbertura,
    this.dataConclusao,
  });

  double get valorTotalPecas => pecasUtilizadas.fold(0, (soma, item) => soma + item.valorTotal);
  double get valorTotal => valorTotalPecas + valorServico;

  factory OrdemServico.fromMap(Map<String, dynamic> map, String id, Cliente cliente) {
    final pecasList = map['pecasUtilizadas'] as List<dynamic>? ?? [];
    return OrdemServico(
      id: id,
      cliente: cliente,
      modeloMoto: map['modeloMoto'] ?? '',
      placa: map['placa'] ?? '',
      cor: map['cor'] ?? '',
      anoFabricacao: map['anoFabricacao'],
      anoModelo: map['anoModelo'],
      mecanicoResponsavel: map['mecanicoResponsavel'] ?? '',
      problemasApresentados: map['problemasApresentados'] ?? '',
      solucoesAplicadas: map['solucoesAplicadas'] ?? '',
      pecasUtilizadas: pecasList.map((p) => ItemOS(
        produto: Produto(id: p['produtoId'], nome: p['produtoNome'], categoria: '', precoCusto: 0, precoVenda: p['precoUnitario'], quantidadeEstoque: 0),
        quantidade: p['quantidade'],
        precoUnitario: p['precoUnitario'].toDouble(),
      )).toList(),
      valorServico: (map['valorServico'] ?? 0).toDouble(),
      status: map['status'] ?? 'Aberta',
      dataAbertura: map['dataAbertura'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dataAbertura']) : null,
      dataConclusao: map['dataConclusao'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dataConclusao']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': cliente.id,
      'clienteNome': cliente.nome,
      'modeloMoto': modeloMoto,
      'placa': placa,
      'cor': cor,
      'anoFabricacao': anoFabricacao,
      'anoModelo': anoModelo,
      'mecanicoResponsavel': mecanicoResponsavel,
      'problemasApresentados': problemasApresentados,
      'solucoesAplicadas': solucoesAplicadas,
      'pecasUtilizadas': pecasUtilizadas.map((p) => p.toMap()).toList(),
      'valorServico': valorServico,
      'status': status,
      'dataAbertura': dataAbertura?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'dataConclusao': dataConclusao?.millisecondsSinceEpoch,
    };
  }
}