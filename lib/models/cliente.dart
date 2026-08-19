class Cliente {
  String? id;
  String nome;
  String cpfCnpj;
  String telefone;
  String? email;
  String? endereco;
  String? observacoes;
  DateTime? dataCadastro;

  Cliente({
    this.id,
    required this.nome,
    required this.cpfCnpj,
    required this.telefone,
    this.email,
    this.endereco,
    this.observacoes,
    this.dataCadastro,
  });

  // Converter dados do Firestore para objeto Cliente
  factory Cliente.fromMap(Map<String, dynamic> map, String id) {
    return Cliente(
      id: id,
      nome: map['nome'] ?? '',
      cpfCnpj: map['cpfCnpj'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'],
      endereco: map['endereco'],
      observacoes: map['observacoes'],
      dataCadastro: map['dataCadastro'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataCadastro'])
          : null,
    );
  }

  // Converter objeto Cliente para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cpfCnpj': cpfCnpj,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'observacoes': observacoes,
      'dataCadastro': dataCadastro?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }
}