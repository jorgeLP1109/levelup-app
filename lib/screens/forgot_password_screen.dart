import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0: email, 1: código, 2: nueva contraseña
  bool _loading = false;
  String? _error;
  String? _success;

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(
                  _step == 0 ? Icons.email_outlined : _step == 1 ? Icons.pin_outlined : Icons.lock_reset,
                  size: 48,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 20),

              // Título del paso
              Text(
                _step == 0 ? 'Ingresa tu correo' : _step == 1 ? 'Verifica el código' : 'Nueva contraseña',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 0
                    ? 'Te enviaremos un código de verificación'
                    : _step == 1
                        ? 'Ingresa el código de 6 dígitos enviado a tu correo'
                        : 'Crea tu nueva contraseña',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Mensajes
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              if (_success != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(_success!, style: TextStyle(color: AppColors.success, fontSize: 13)),
                ),

              // Formulario según paso
              if (_step == 0) _buildEmailStep(),
              if (_step == 1) _buildCodeStep(),
              if (_step == 2) _buildPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email)),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendCode,
            child: _loading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enviar Código', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        TextField(
          controller: _codeCtrl,
          decoration: const InputDecoration(labelText: 'Código de 6 dígitos', prefixIcon: Icon(Icons.pin)),
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyCode,
            child: _loading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Verificar Código', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _sendCode,
          child: const Text('Reenviar código', style: TextStyle(color: AppColors.accent)),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        TextField(
          controller: _passCtrl,
          decoration: const InputDecoration(labelText: 'Nueva contraseña', prefixIcon: Icon(Icons.lock)),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmCtrl,
          decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_outline)),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _resetPassword,
            child: _loading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Cambiar Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa tu correo electrónico');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final api = ApiService();
      final res = await api.post('/auth/forgot-password', data: {'email': _emailCtrl.text.trim()});
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _step = 1;
          _success = 'Código enviado a ${_emailCtrl.text.trim()}';
        });
      }
    } catch (e) {
      // Incluso si da error, el backend puede haber enviado el código
      // (responde 200 siempre por seguridad)
      setState(() {
        _step = 1;
        _success = 'Si el correo está registrado, recibirás un código.';
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'Ingresa el código de 6 dígitos');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final api = ApiService();
      final res = await api.post('/auth/verify-code', data: {
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
      });
      if (res.data['valid'] == true) {
        setState(() { _step = 2; _success = 'Código verificado correctamente'; });
      }
    } catch (e) {
      String msg = 'Código inválido o expirado';
      try { final dynamic err = e; msg = err.response?.data['message'] ?? msg; } catch (_) {}
      setState(() => _error = msg);
    }

    setState(() => _loading = false);
  }

  Future<void> _resetPassword() async {
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final api = ApiService();
      await api.post('/auth/reset-password', data: {
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'newPassword': _passCtrl.text,
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardColor,
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppColors.success),
                SizedBox(height: 16),
                Text('¡Contraseña actualizada!', style: TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Ya puedes iniciar sesión con tu nueva contraseña.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Ir al Login'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      String msg = 'Error al cambiar la contraseña';
      try { final dynamic err = e; msg = err.response?.data['message'] ?? msg; } catch (_) {}
      setState(() => _error = msg);
    }

    setState(() => _loading = false);
  }
}
