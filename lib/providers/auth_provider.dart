import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;
  UserModel? user;

  Future<void> login(
    String phone,
    String password, {
    required String role,
  }) async {
    user = await _authService.login(
      phone: phone,
      password: password,
      role: role,
    );
    notifyListeners();
  }
}
