import 'package:flutter/material.dart';
import '../models/gym_class.dart';
import '../services/api_service.dart';

class ClassProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<GymClass> _classes = [];
  bool _isLoading = false;
  String? _error;

  List<GymClass> get classes => _classes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<GymClass> getMyClasses(String userId) {
    return _classes.where((c) {
      return c.inscritos.any((i) {
        if (i is String) return i == userId;
        if (i is Map) {
          final user = i['user'];
          if (user is String) return user == userId;
          if (user is Map) return user['_id'] == userId;
        }
        return false;
      });
    }).toList();
  }

  /// Obtener clases vencidas del usuario
  List<GymClass> getVencidas(String userId) {
    final now = DateTime.now();
    return _classes.where((c) {
      return c.inscritos.any((i) {
        if (i is! Map) return false;
        final user = i['user'];
        final uid = user is String ? user : (user is Map ? user['_id'] : '');
        if (uid != userId) return false;
        final venc = DateTime.tryParse(i['fechaVencimiento'] ?? '');
        return venc != null && venc.isBefore(now);
      });
    }).toList();
  }

  Future<void> fetchClasses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('/classes');
      _classes = (res.data as List).map((c) => GymClass.fromJson(c)).toList();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar clases';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> enroll(String classId) async {
    try {
      await _api.post('/classes/$classId/enroll');
      await fetchClasses();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unenroll(String classId) async {
    try {
      await _api.post('/classes/$classId/unenroll');
      await fetchClasses();
      return true;
    } catch (_) {
      return false;
    }
  }
}
