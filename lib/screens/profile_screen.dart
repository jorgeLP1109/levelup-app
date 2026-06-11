import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pesoCtrl;
  late TextEditingController _estaturaCtrl;
  late TextEditingController _alergiasCtrl;
  late TextEditingController _medicamentosCtrl;
  late TextEditingController _emergNombreCtrl;
  late TextEditingController _emergTelefonoCtrl;
  String? _tipoSangre;
  String? _fotoBase64;
  String? _fotoUrlActual;
  bool _saving = false;

  static const _tiposSangre = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _pesoCtrl = TextEditingController(text: user?.peso?.toString() ?? '');
    _estaturaCtrl = TextEditingController(text: user?.estatura?.toString() ?? '');
    _alergiasCtrl = TextEditingController(text: user?.alergias ?? '');
    _medicamentosCtrl = TextEditingController(text: user?.medicamentos ?? '');
    _emergNombreCtrl = TextEditingController(text: user?.contactoEmergenciaNombre ?? '');
    _emergTelefonoCtrl = TextEditingController(text: user?.contactoEmergenciaTelefono ?? '');
    _tipoSangre = user?.tipoSangre;
    _fotoUrlActual = user?.fotoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ─── FOTO DE PERFIL ───
              Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _buildAvatarImage(),
                    child: _fotoBase64 == null && (_fotoUrlActual == null || _fotoUrlActual!.isEmpty)
                        ? const Icon(Icons.person, size: 56, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _mostrarOpcionesFoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(user?.nombre ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(user?.email ?? '', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),

              // ─── DATOS FÍSICOS ───
              _sectionTitle('Datos Físicos'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pesoCtrl,
                      decoration: const InputDecoration(labelText: 'Peso (kg)', prefixIcon: Icon(Icons.monitor_weight)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _estaturaCtrl,
                      decoration: const InputDecoration(labelText: 'Estatura (cm)', prefixIcon: Icon(Icons.height)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── FICHA MÉDICA ───
              _sectionTitle('Ficha Médica'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipoSangre,
                decoration: const InputDecoration(labelText: 'Tipo de Sangre', prefixIcon: Icon(Icons.bloodtype)),
                items: _tiposSangre.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipoSangre = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alergiasCtrl,
                decoration: const InputDecoration(labelText: 'Alergias', prefixIcon: Icon(Icons.warning_amber), hintText: 'Ej: Penicilina, polen...'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicamentosCtrl,
                decoration: const InputDecoration(labelText: 'Medicamentos Especiales', prefixIcon: Icon(Icons.medication), hintText: 'Ej: Insulina, Salbutamol...'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // ─── CONTACTO DE EMERGENCIA ───
              _sectionTitle('Contacto de Emergencia'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergNombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del contacto *', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergTelefonoCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono de emergencia *', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 32),

              // ─── BOTÓN GUARDAR ───
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _guardarPerfil,
                  child: _saving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Actualizar Perfil', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _buildAvatarImage() {
    if (_fotoBase64 != null) {
      return MemoryImage(base64Decode(_fotoBase64!));
    }
    if (_fotoUrlActual != null && _fotoUrlActual!.isNotEmpty) {
      if (_fotoUrlActual!.startsWith('data:image')) {
        final base64Str = _fotoUrlActual!.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      }
      return NetworkImage(_fotoUrlActual!);
    }
    return null;
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cambiar Foto de Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Tomar Foto con la Cámara'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.secondary),
                title: const Text('Seleccionar de la Galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarImagen(ImageSource.gallery);
                },
              ),
              if (_fotoBase64 != null || (_fotoUrlActual != null && _fotoUrlActual!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text('Eliminar Foto'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _fotoBase64 = null;
                      _fotoUrlActual = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _fotoBase64 = base64Encode(bytes);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la imagen')),
        );
      }
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final api = ApiService();
      final body = <String, dynamic>{};

      if (_pesoCtrl.text.isNotEmpty) body['peso'] = double.tryParse(_pesoCtrl.text);
      if (_estaturaCtrl.text.isNotEmpty) body['estatura'] = double.tryParse(_estaturaCtrl.text);
      if (_tipoSangre != null) body['tipoSangre'] = _tipoSangre;
      if (_alergiasCtrl.text.isNotEmpty) body['alergias'] = _alergiasCtrl.text.trim();
      if (_medicamentosCtrl.text.isNotEmpty) body['medicamentos'] = _medicamentosCtrl.text.trim();
      body['contactoEmergenciaNombre'] = _emergNombreCtrl.text.trim();
      body['contactoEmergenciaTelefono'] = _emergTelefonoCtrl.text.trim();

      // Enviar foto como Base64 en fotoUrl
      if (_fotoBase64 != null) {
        body['fotoUrl'] = 'data:image/jpeg;base64,$_fotoBase64';
      } else if (_fotoUrlActual == null) {
        body['fotoUrl'] = '';
      }

      await api.put('/auth/profile', data: body);

      if (mounted) {
        await context.read<AuthProvider>().tryAutoLogin();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el perfil')),
        );
      }
    }

    setState(() => _saving = false);
  }
}
