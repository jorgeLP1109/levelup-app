import '../services/api_service.dart';

class WompiService {
  final ApiService _api = ApiService();

  /// Crea un intento de pago en el backend y retorna la URL del checkout de Wompi
  Future<Map<String, dynamic>> crearIntentoPago({
    required List<Map<String, dynamic>> items,
    required double total,
    required String email,
  }) async {
    final res = await _api.post('/wompi/crear-intento', data: {
      'items': items,
      'total': total,
      'email': email,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Consulta el estado de una transacción
  Future<Map<String, dynamic>> consultarEstado(String transactionId) async {
    final res = await _api.get('/wompi/estado/$transactionId');
    return res.data as Map<String, dynamic>;
  }
}
