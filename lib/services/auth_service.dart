import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>> loginWithPassword({
    String? email,
    String? phone,
    required String password,
  }) async {
    final data =
        await _apiService.post(
              '/auth/login',
              body: {
                if (phone != null && phone.isNotEmpty) 'phone': phone,
                if (email != null && email.isNotEmpty) 'email': email,
                'password': password,
              },
            )
            as Map<String, dynamic>;
    return data;
  }

  Future<void> sendOtp(String email) async {
    await _apiService.post('/auth/send-otp', body: {'email': email});
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final data =
        await _apiService.post(
              '/auth/verify-otp',
              body: {'email': email, 'otp': otp},
            )
            as Map<String, dynamic>;
    return data;
  }

  Future<UserModel> me(String token) async {
    final data =
        await _apiService.get('/auth/me', token: token) as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}
