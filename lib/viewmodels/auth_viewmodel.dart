import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/database/db_helper.dart';

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  final DBHelper _dbHelper = DBHelper.instance;

  Future<bool> register(String name, String email, String password) async {
    try {
      final user = UserModel(name: name, email: email, password: password);
      await _dbHelper.registerUser(user.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    final userData = await _dbHelper.loginUser(email, password);
    if (userData != null) {
      state = UserModel.fromMap(userData);
      return true;
    }
    return false;
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

// CORREÇÃO: valor inicial -1 indica "não autenticado" de forma explícita
final authUserIdProvider = StateProvider<int>((ref) => -1);