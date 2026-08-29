import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class SessionService {
  SessionService({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _prefs = prefs;

  static const _tokenKey = 'auth_token';
  static const _loggedInKey = 'is_logged_in';
  static const _userKey = 'auth_user';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _roleKey = 'user_role';
  static const _reviewedProductKeysPrefix = 'reviewed_product_keys';

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sharedPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    final prefs = await _sharedPrefs;
    await _secureStorage.write(key: _tokenKey, value: token);
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userKey, user.toStorage());
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_emailKey, user.email ?? '');
    await prefs.setString(_roleKey, user.role);
  }

  Future<String?> getToken() => _secureStorage.read(key: _tokenKey);

  Future<String?> getUserRole() async {
    final prefs = await _sharedPrefs;
    return prefs.getString(_roleKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _sharedPrefs;
    final token = await getToken();
    return (prefs.getBool(_loggedInKey) ?? false) && token != null;
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await _sharedPrefs;
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    return UserModel.fromStorage(raw);
  }

  Future<void> clearSession() async {
    final prefs = await _sharedPrefs;
    final userId = prefs.getString(_userIdKey);
    await _secureStorage.delete(key: _tokenKey);
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    if (userId != null && userId.isNotEmpty) {
      await prefs.remove(_reviewedProductKeysScopedKey(userId));
    }
  }

  Future<Set<String>> getReviewedProductKeys({String? userId}) async {
    final prefs = await _sharedPrefs;
    final scopedKey = _reviewedProductKeysScopedKey(userId);
    return (prefs.getStringList(scopedKey) ?? const <String>[]).toSet();
  }

  Future<void> addReviewedProductKey({
    required String key,
    String? userId,
  }) async {
    final prefs = await _sharedPrefs;
    final scopedKey = _reviewedProductKeysScopedKey(userId);
    final keys = (prefs.getStringList(scopedKey) ?? const <String>[]).toSet();
    keys.add(key);
    await prefs.setStringList(scopedKey, keys.toList(growable: false));
  }

  Future<void> saveReviewedProductKeys({
    required Set<String> keys,
    String? userId,
  }) async {
    final prefs = await _sharedPrefs;
    final scopedKey = _reviewedProductKeysScopedKey(userId);
    await prefs.setStringList(scopedKey, keys.toList(growable: false));
  }

  String _reviewedProductKeysScopedKey(String? userId) {
    final scope = (userId ?? '').trim().isEmpty ? 'guest' : userId!.trim();
    return '${_reviewedProductKeysPrefix}_$scope';
  }
}
