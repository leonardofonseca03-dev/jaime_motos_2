class Produto {
  String? id;
  String nome;
  String? codigo;
  String categoria;
  String? marca;
  double precoCusto;
  double precoVenda;
  int quantidadeEstoque;
  String? descricao;
  DateTime? dataCadastro;

  Produto({
    this.id,
    required this.nome,
    this.codigo,
    required this.categoria,
    this.marca,
    required this.precoCusto,
    required this.precoVenda,
    required this.quantidadeEstoque,
    this.descricao,
    this.dataCadastro,
  });

  int get estoqueDisponivel => quantidadeEstoque;

  String get codigoBarras => codigo ?? '';

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'codigo': codigo,
      'categoria': categoria,
      'marca': marca,
      'precoCusto': precoCusto,
      'precoVenda': precoVenda,
      'quantidadeEstoque': quantidadeEstoque,
      'descricao': descricao,
      'dataCadastro': dataCadastro?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map, String id) {
    return Produto(
      id: id,
      nome: map['nome'] ?? '',
      codigo: map['codigo'],
      categoria: map['categoria'] ?? '',
      marca: map['marca'],
      precoCusto: (map['precoCusto'] ?? 0).toDouble(),
      precoVenda: (map['precoVenda'] ?? 0).toDouble(),
      quantidadeEstoque: (map['quantidadeEstoque'] ?? 0) as int,
      descricao: map['descricao'],
      dataCadastro: map['dataCadastro'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataCadastro'])
          : DateTime.now(),
    );
  }
}