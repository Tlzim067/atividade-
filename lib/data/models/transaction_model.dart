class TransactionModel {
  final int? id;
  final int userId;
  final String title;
  final double amount; // Armazena o valor fracionado (ex: 13.3)
  final String type;   // 'Entrada' ou 'Saída'
  final String category;
  final String date;

  TransactionModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  // Converte o modelo em um Map para salvar no Banco de Dados (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
    };
  }

  // Cria um modelo a partir dos dados vindos do Banco de Dados
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(), // Garante a conversão para double
      type: map['type'],
      category: map['category'],
      date: map['date'],
    );
  }
}