import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AccessQRScreen extends StatefulWidget {
  const AccessQRScreen({super.key});

  @override
  State<AccessQRScreen> createState() => _AccessQRScreenState();
}

class _AccessQRScreenState extends State<AccessQRScreen> {
  String? _token;
  DateTime? _expiresAt;
  bool _loading = true;
  bool _solvente = false;
  String? _error;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _generateToken();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateToken() async {
    setState(() { _loading = true; _error = null; });

    try {
      final api = ApiService();
      final res = await api.post('/access/generate');
      final data = res.data as Map<String, dynamic>;

      setState(() {
        _token = data['token'];
        _expiresAt = DateTime.parse(data['expiresAt']);
        _solvente = data['solvente'] ?? true;
        _loading = false;
        _secondsLeft = _expiresAt!.difference(DateTime.now()).inSeconds;
      });

      _startCountdown();
    } catch (e) {
      String msg = 'Error al generar acceso';
      try {
        final dynamic err = e;
        msg = err.response?.data['message'] ?? msg;
      } catch (_) {}

      setState(() {
        _loading = false;
        _solvente = false;
        _error = msg;
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }

      setState(() {
        _secondsLeft = _expiresAt!.difference(DateTime.now()).inSeconds;
      });

      if (_secondsLeft <= 0) {
        timer.cancel();
        // Auto-regenerar
        _generateToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Control de Acceso'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator(color: AppColors.accent)
              : !_solvente
                  ? _buildNoAccess()
                  : _buildQRCode(user),
        ),
      ),
    );
  }

  Widget _buildNoAccess() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block, size: 64, color: AppColors.error),
          ),
          const SizedBox(height: 24),
          const Text('Acceso Denegado', style: TextStyle(color: AppColors.error, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            _error ?? 'No estás solvente. Renueva tu mensualidad para acceder al gimnasio.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Renovar Mensualidad'),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text('Acceso Autorizado', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nombre
          Text(user?.nombre ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
            ),
            child: QrImageView(
              data: _token ?? '',
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 18,
                  color: _secondsLeft > 15 ? AppColors.accent : AppColors.accentGold,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expira en ${_secondsLeft}s',
                  style: TextStyle(
                    color: _secondsLeft > 15 ? AppColors.accent : AppColors.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Se regenera automáticamente',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Botón regenerar manual
          OutlinedButton.icon(
            onPressed: _generateToken,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Regenerar QR'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accent),
              foregroundColor: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Muestra este código al escáner de entrada del gimnasio para registrar tu acceso.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
