import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data as Map<String, dynamic>;
      await _api.saveToken(data['token']);
      _user = User.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e, 'Error al iniciar sesión');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
    required int edad,
    String? cedula,
    double? peso,
    bool isMinor = false,
    String? representantName,
    String? representantPhone,
    String? representantCedula,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'nombre': nombre,
        'email': email,
        'password': password,
        'edad': edad,
      };
      if (cedula != null) body['cedula'] = cedula;
      if (peso != null) body['peso'] = peso;
      if (isMinor) {
        body['isMinor'] = true;
        body['representantName'] = representantName;
        body['representantPhone'] = representantPhone;
        body['representantCedula'] = representantCedula;
      }

      final res = await _api.post('/auth/register', data: body);
      final data = res.data as Map<String, dynamic>;
      await _api.saveToken(data['token']);
      _user = User.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e, 'Error al registrarse');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.deleteToken();
    _user = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final token = await _api.getToken();
    if (token == null) return;

    try {
      final res = await _api.get('/auth/profile');
      _user = User.fromJson(res.data);
      notifyListeners();
    } catch (_) {
      await _api.deleteToken();
    }
  }

  String _extractError(dynamic e, String fallback) {
    try {
      if (e.response?.data != null && e.response.data['message'] != null) {
        return e.response.data['message'];
      }
    } catch (_) {}
    return fallback;
  }
}
