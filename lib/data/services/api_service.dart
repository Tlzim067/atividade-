import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_model.dart';

class ApiService {
  Future<List<CurrencyModel>> fetchCurrencies() async {
    final url = Uri.parse('https://open.er-api.com/v6/latest/USD');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final usdBrl = (rates['BRL'] as num).toDouble();
        final eurRate = (rates['EUR'] as num).toDouble();
        final eurBrl = eurRate > 0 ? usdBrl / eurRate : 0.0;
        return [
          CurrencyModel(name: 'USD/BRL', buy: usdBrl.toStringAsFixed(2), pctChange: '0.0'),
          CurrencyModel(name: 'EUR/BRL', buy: eurBrl.toStringAsFixed(2), pctChange: '0.0'),
          CurrencyModel(name: 'GBP/BRL', buy: ((rates['GBP'] as num?) != null ? usdBrl / (rates['GBP'] as num).toDouble() : 0.0).toStringAsFixed(2), pctChange: '0.0'),
        ];
      } else {
        throw Exception('Erro na API');
      }
    } catch (e) {
      throw Exception('Falha na conexão: \$e');
    }
  }
}
