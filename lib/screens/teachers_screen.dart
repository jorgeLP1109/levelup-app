import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<dynamic> _teachers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().get('/teachers');
      setState(() => _teachers = res.data as List);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nuestros Profesores'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _teachers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_rounded, size: 72, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Aún no hay profesores registrados', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 8),
                        const Text('Pronto conocerás a nuestro equipo', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetch,
                    color: AppColors.accent,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _teachers.length,
                      itemBuilder: (_, index) => _TeacherCard(teacher: _teachers[index]),
                    ),
                  ),
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final dynamic teacher;
  const _TeacherCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final nombre = teacher['nombre'] ?? '';
    final disciplina = teacher['disciplina'] ?? '';
    final resena = teacher['resena'] ?? '';
    final fotoUrl = teacher['fotoUrl'] as String?;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.primaryLight,
                  child: _buildPhoto(fotoUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(disciplina, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    if (resena.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(resena, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _TeacherDetailScreen(teacher: teacher)));
  }

  Widget _buildPhoto(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      return const Center(child: Icon(Icons.person, color: AppColors.textSecondary, size: 36));
    }
    if (fotoUrl.startsWith('data:image')) {
      return Image.memory(base64Decode(fotoUrl.split(',').last), fit: BoxFit.cover, width: 72, height: 72);
    }
    return Image.network(fotoUrl, fit: BoxFit.cover, width: 72, height: 72,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.person, color: AppColors.textSecondary, size: 36)));
  }
}

// ═══════════════════════════════════════════════════════════════
// DETALLE DEL PROFESOR
// ═══════════════════════════════════════════════════════════════

class _TeacherDetailScreen extends StatelessWidget {
  final dynamic teacher;
  const _TeacherDetailScreen({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final nombre = teacher['nombre'] ?? '';
    final disciplina = teacher['disciplina'] ?? '';
    final resena = teacher['resena'] ?? '';
    final fotoUrl = teacher['fotoUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil del Profesor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Foto grande
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 140,
                  height: 140,
                  color: AppColors.primaryLight,
                  child: _buildPhotoBig(fotoUrl),
                ),
              ),
              const SizedBox(height: 20),

              // Nombre
              Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),

              // Disciplina badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(disciplina, style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 28),

              // Reseña
              if (resena.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_quote, color: AppColors.accent.withOpacity(0.6), size: 22),
                          const SizedBox(width: 8),
                          const Text('Acerca de', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(resena, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoBig(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      return const Center(child: Icon(Icons.person, color: AppColors.textSecondary, size: 64));
    }
    if (fotoUrl.startsWith('data:image')) {
      return Image.memory(base64Decode(fotoUrl.split(',').last), fit: BoxFit.cover, width: 140, height: 140);
    }
    return Image.network(fotoUrl, fit: BoxFit.cover, width: 140, height: 140,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.person, color: AppColors.textSecondary, size: 64)));
  }
}
