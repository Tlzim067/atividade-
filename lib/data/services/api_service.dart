import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_model.dart';

class ApiService {
  Future<List<CurrencyModel>> fetchCurrencies() async {
    final url = Uri.parse('https://economia.awesomeapi.com.br/last/USD-BRL,EUR-BRL,BTC-BRL');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return [
          CurrencyModel.fromJson(data['USDBRL']),
          CurrencyModel.fromJson(data['EURBRL']),
          CurrencyModel.fromJson(data['BTCBRL']),
        ];
      } else {
        throw Exception('Erro ao carregar dados da API');
      }
    } catch (e) {
      throw Exception('Falha na conexão de rede: $e');
    }
  }
}