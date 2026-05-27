class CurrencyModel {
  final String name;
  final String buy;
  final String pctChange;

  CurrencyModel({required this.name, required this.buy, required this.pctChange});

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      name: json['name'] ?? '',
      buy: double.parse(json['bid'] ?? '0').toStringAsFixed(2),
      pctChange: json['pctChange'] ?? '0',
    );
  }
}