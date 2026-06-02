import '../core/constants.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel> login({
    required String phone,
    required String password,
    String role = UserRoles.user,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return UserModel(
      id: 'demo-user',
      name: 'Demo User',
      phone: phone,
      role: role,
    );
  }
}
