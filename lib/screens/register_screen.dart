import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _repNameCtrl = TextEditingController();
  final _repPhoneCtrl = TextEditingController();
  final _repCedulaCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isMinor = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo *'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cedulaCtrl,
                decoration: const InputDecoration(labelText: 'Cédula'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña *'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _edadCtrl,
                decoration: const InputDecoration(labelText: 'Edad *'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pesoCtrl,
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('¿Es menor de edad?'),
                value: _isMinor,
                onChanged: (v) => setState(() => _isMinor = v),
              ),
              if (_isMinor) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _repNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del representante *'),
                  validator: _isMinor ? (v) => v!.isEmpty ? 'Requerido' : null : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _repPhoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono del representante *'),
                  keyboardType: TextInputType.phone,
                  validator: _isMinor ? (v) => v!.isEmpty ? 'Requerido' : null : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _repCedulaCtrl,
                  decoration: const InputDecoration(labelText: 'Cédula del representante *'),
                  validator: _isMinor ? (v) => v!.isEmpty ? 'Requerido' : null : null,
                ),
              ],
              const SizedBox(height: 8),
              if (auth.error != null)
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _register,
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrarse'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().register(
          nombre: _nombreCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          edad: int.parse(_edadCtrl.text.trim()),
          cedula: _cedulaCtrl.text.isNotEmpty ? _cedulaCtrl.text.trim() : null,
          peso: _pesoCtrl.text.isNotEmpty ? double.tryParse(_pesoCtrl.text.trim()) : null,
          isMinor: _isMinor,
          representantName: _isMinor ? _repNameCtrl.text.trim() : null,
          representantPhone: _isMinor ? _repPhoneCtrl.text.trim() : null,
          representantCedula: _isMinor ? _repCedulaCtrl.text.trim() : null,
        );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}
