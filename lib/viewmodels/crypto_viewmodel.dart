import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';
import '../data/models/crypto_model.dart';

// Provedor do serviço de API
final apiServiceProvider = Provider((ref) => ApiService());

// Provedor que a tela vai escutar (Gerencia loading, erro e sucesso automaticamente)
final cryptoViewModelProvider = FutureProvider<List<CurrencyModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchCurrencies();
});
