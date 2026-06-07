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
      return c.inscritos.any((i) => i is String ? i == userId : i['_id'] == userId);
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
