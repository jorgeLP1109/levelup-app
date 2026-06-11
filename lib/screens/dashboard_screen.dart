import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/cart_provider.dart';
import '../models/gym_class.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
// DASHBOARD PRINCIPAL — HUB CENTRAL
// ═══════════════════════════════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ClassProvider>().fetchClasses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _HomeHub(),
          const _ClassesView(),
          const _ProgressView(),
          const _MessagesView(),
          const _RoutesView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 'Inicio', 0),
                _navItem(Icons.fitness_center_rounded, 'Clases', 1),
                _navItem(Icons.trending_up_rounded, 'Progreso', 2),
                _navItem(Icons.chat_bubble_rounded, 'Mensajes', 3),
                _navItem(Icons.map_rounded, 'Rutas', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? AppColors.accent : AppColors.textSecondary, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppColors.accent : AppColors.textSecondary, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOME HUB — PANTALLA PRINCIPAL CON GRID
// ═══════════════════════════════════════════════════════════════

class _HomeHub extends StatelessWidget {
  const _HomeHub();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final classProv = context.watch<ClassProvider>();
    final cart = context.watch<CartProvider>();
    final user = auth.user;
    final myClasses = classProv.getMyClasses(user?.id ?? '');

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ─── HEADER ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.secondary,
                      backgroundImage: _getUserImage(user?.fotoUrl),
                      child: user?.fotoUrl == null || user!.fotoUrl!.isEmpty
                          ? const Icon(Icons.person, color: AppColors.accent, size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Saludo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¡Hola, ${user?.nombre?.split(' ').first ?? ''}!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        _PlanBadge(user: user),
                      ],
                    ),
                  ),
                  // Logout
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ),

          // ─── BANNER MENSUALIDAD ───
          if (user != null && user.mensualidadVencida)
            SliverToBoxAdapter(
              child: _AlertBanner(
                color: AppColors.error,
                icon: Icons.warning_rounded,
                text: 'Mensualidad vencida. Renueva desde el carrito o contacta administración.',
              ),
            )
          else if (user != null && user.mensualidadPorVencer)
            SliverToBoxAdapter(
              child: _AlertBanner(
                color: AppColors.accentGold,
                icon: Icons.access_time_rounded,
                text: 'Tu mensualidad vence en ${user.diasRestantes} días. ¡Evita perder tus clases!',
              ),
            ),

          // ─── GRID MENU ───
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                _MenuCard(
                  icon: Icons.fitness_center_rounded,
                  title: 'Mis Clases',
                  subtitle: '${myClasses.length} inscritas',
                  gradient: const [Color(0xFF1E3A5F), Color(0xFF2D5986)],
                  onTap: () => _goToTab(context, 1),
                ),
                _MenuCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Mi Progreso',
                  subtitle: 'Historial de avances',
                  gradient: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  onTap: () => _goToTab(context, 2),
                ),
                _MenuCard(
                  icon: Icons.mail_rounded,
                  title: 'Mensajes',
                  subtitle: 'Tablón de anuncios',
                  gradient: const [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                  onTap: () => _goToTab(context, 3),
                  showBadge: true,
                ),
                _MenuCard(
                  icon: Icons.directions_bus_rounded,
                  title: 'Ruta Transporte',
                  subtitle: 'Tracking en vivo',
                  gradient: const [Color(0xFFE65100), Color(0xFFFF8F00)],
                  onTap: () => _goToTab(context, 4),
                ),
                _MenuCard(
                  icon: Icons.school_rounded,
                  title: 'Profesores',
                  subtitle: 'Nuestro equipo',
                  gradient: const [Color(0xFF00695C), Color(0xFF00897B)],
                  onTap: () => Navigator.pushNamed(context, '/teachers'),
                ),
                _MenuCard(
                  icon: Icons.storefront_rounded,
                  title: 'Tienda',
                  subtitle: 'Artículos deportivos',
                  gradient: const [Color(0xFF4E342E), Color(0xFF6D4C41)],
                  onTap: () => Navigator.pushNamed(context, '/shop'),
                ),
                _MenuCard(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Carrito',
                  subtitle: '${cart.itemCount} items',
                  gradient: const [Color(0xFF880E4F), Color(0xFFAD1457)],
                  onTap: () => Navigator.pushNamed(context, '/cart'),
                  badgeCount: cart.itemCount,
                ),
              ],
            ),
          ),

          // ─── CLASES INSCRITAS (resumen rápido) ───
          if (myClasses.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Text('Próximas Clases', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = myClasses[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _QuickClassTile(gymClass: c),
                  );
                },
                childCount: myClasses.length > 3 ? 3 : myClasses.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  void _goToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_DashboardScreenState>();
    state?.setState(() => state._currentIndex = index);
  }

  ImageProvider? _getUserImage(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) return null;
    if (fotoUrl.startsWith('data:image')) {
      return MemoryImage(base64Decode(fotoUrl.split(',').last));
    }
    return NetworkImage(fotoUrl);
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS PREMIUM
// ═══════════════════════════════════════════════════════════════

class _PlanBadge extends StatelessWidget {
  final dynamic user;
  const _PlanBadge({this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    final vencida = user.mensualidadVencida;
    final porVencer = user.mensualidadPorVencer;
    final color = vencida ? AppColors.error : porVencer ? AppColors.accentGold : AppColors.success;
    final text = vencida ? 'Plan Vencido' : porVencer ? 'Vence pronto' : 'Plan Activo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _AlertBanner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool showBadge;
  final int badgeCount;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.accent.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                  ],
                ),
              ),
              if (showBadge || badgeCount > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: Text(
                      badgeCount > 0 ? '$badgeCount' : '!',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickClassTile extends StatelessWidget {
  final GymClass gymClass;
  const _QuickClassTile({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fitness_center, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gymClass.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${gymClass.profesor} • ${gymClass.diasPorSemana}d/sem',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (gymClass.horarios.isNotEmpty)
            Text(gymClass.horarios.first.horaInicio, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VISTAS DE CADA SECCIÓN (mantienen funcionalidad existente)
// ═══════════════════════════════════════════════════════════════

class _ClassesView extends StatelessWidget {
  const _ClassesView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final classProv = context.watch<ClassProvider>();
    final userId = auth.user?.id ?? '';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Text('Clases Disponibles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, color: AppColors.textSecondary), onPressed: () => classProv.fetchClasses()),
              ],
            ),
          ),
          Expanded(
            child: classProv.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : RefreshIndicator(
                    onRefresh: () => classProv.fetchClasses(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: classProv.classes.length,
                      itemBuilder: (context, index) {
                        final c = classProv.classes[index];
                        final isEnrolled = c.inscritos.any((i) => i is String ? i == userId : i['_id'] == userId);
                        return _ClassCard2(gymClass: c, isEnrolled: isEnrolled);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard2 extends StatelessWidget {
  final GymClass gymClass;
  final bool isEnrolled;
  const _ClassCard2({required this.gymClass, required this.isEnrolled});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEnrolled ? AppColors.accent.withOpacity(0.4) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(gymClass.nombre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('\$${gymClass.precio.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${gymClass.profesor} • ${gymClass.diasPorSemana} días/sem', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: gymClass.horarios.map((h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: Text('${h.dia} ${h.horaInicio}-${h.horaFin}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.group, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${gymClass.inscritos.length} inscritos', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              if (isEnrolled)
                TextButton(
                  onPressed: () async {
                    final ok = await context.read<ClassProvider>().unenroll(gymClass.id);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Desinscripción exitosa' : 'Error')));
                  },
                  child: const Text('Desinscribirme', style: TextStyle(color: AppColors.error)),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    final cart = context.read<CartProvider>();
                    if (cart.isInCart(gymClass.id)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya está en el carrito')));
                    } else {
                      cart.addToCart(CartItem(id: gymClass.id, nombre: gymClass.nombre, tipo: 'clase', precio: gymClass.precio, descripcion: '${gymClass.profesor} • ${gymClass.diasPorSemana}d/sem'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clase agregada al carrito')));
                    }
                  },
                  child: const Text('Inscribirme'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PROGRESO ───
class _ProgressView extends StatefulWidget {
  const _ProgressView();
  @override
  State<_ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<_ProgressView> {
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try { final res = await ApiService().get('/progress'); _list = res.data as List; } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Text('Mi Progreso', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _list.isEmpty
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.trending_up, size: 60, color: AppColors.textSecondary), SizedBox(height: 12), Text('Aún no hay registros', style: TextStyle(color: AppColors.textSecondary))]))
                    : RefreshIndicator(onRefresh: _fetch, child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _list.length,
                        itemBuilder: (_, i) {
                          final p = _list[i]; final clase = p['clase']; final fecha = DateTime.tryParse(p['fecha'] ?? '') ?? DateTime.now();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(14)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.emoji_events, color: AppColors.accentGold, size: 20), const SizedBox(width: 8),
                                Expanded(child: Text(clase?['nombre'] ?? 'Clase', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                Text('${fecha.day}/${fecha.month}/${fecha.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ]),
                              const SizedBox(height: 6),
                              Text(p['descripcion'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ]),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}

// ─── MENSAJES ───
class _MessagesView extends StatefulWidget {
  const _MessagesView();
  @override
  State<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<_MessagesView> {
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try { final res = await ApiService().get('/messages'); _list = res.data as List; } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Text('Mensajes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _list.isEmpty
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mail_outline, size: 60, color: AppColors.textSecondary), SizedBox(height: 12), Text('No hay mensajes', style: TextStyle(color: AppColors.textSecondary))]))
                    : RefreshIndicator(onRefresh: _fetch, child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _list.length,
                        itemBuilder: (_, i) {
                          final msg = _list[i]; final fecha = DateTime.tryParse(msg['fechaPublicacion'] ?? msg['createdAt'] ?? '') ?? DateTime.now();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(14)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.campaign, color: AppColors.accentGold, size: 20), const SizedBox(width: 8),
                                Expanded(child: Text(msg['titulo'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              ]),
                              const SizedBox(height: 8),
                              Text(msg['contenido'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text('${fecha.day}/${fecha.month}/${fecha.year}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ]),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}

// ─── RUTAS ───
class _RoutesView extends StatefulWidget {
  const _RoutesView();
  @override
  State<_RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<_RoutesView> {
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try { final res = await ApiService().get('/routes'); _list = res.data as List; } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id ?? '';

    // Filtrar: solo la ruta a la que está afiliado
    final myRoute = _list.where((r) {
      final afiliados = r['afiliados'] as List? ?? [];
      return afiliados.any((a) => a is String ? a == userId : a['_id'] == userId);
    }).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Text('Mi Ruta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : myRoute.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_bus, size: 60, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            const Text('No estás afiliado a una ruta', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            const Text('Afíliate desde la sección de rutas disponibles', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => _showAllRoutes(context),
                              child: const Text('Ver Rutas Disponibles'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: myRoute.length,
                          itemBuilder: (_, i) {
                            final r = myRoute[i];
                            return _MyRouteCard(route: r, onRefresh: _fetch);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAllRoutes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Rutas Disponibles', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _list.length,
                itemBuilder: (_, i) {
                  final r = _list[i];
                  final conductor = r['conductor'] ?? {};
                  final precio = (r['precio'] ?? 20).toDouble();
                  final dias = (r['dias'] as List?)?.cast<String>() ?? [];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(conductor['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(dias.join(', '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ])),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                              backgroundColor: AppColors.cardColor,
                              title: const Text('Afiliarme', style: TextStyle(color: Colors.white)),
                              content: Text('Costo: \$${precio.toStringAsFixed(0)}/mes', style: const TextStyle(color: AppColors.textSecondary)),
                              actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmar'))],
                            ));
                            if (ok == true) {
                              try { await ApiService().post('/routes/${r['_id']}/enroll'); _fetch(); } catch (_) {}
                            }
                          },
                          child: Text('\$${precio.toStringAsFixed(0)}'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRouteCard extends StatelessWidget {
  final dynamic route;
  final VoidCallback onRefresh;
  const _MyRouteCard({required this.route, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final conductor = route['conductor'] ?? {};
    final vehiculo = route['vehiculo'] ?? {};
    final horarios = route['horarios'] ?? {};
    final dias = (route['dias'] as List?)?.cast<String>() ?? [];
    final coords = route['coordenadas'] ?? {};
    final hasLoc = (coords['lat'] ?? 0) != 0 || (coords['lng'] ?? 0) != 0;

    return GestureDetector(
      onTap: () => _openTracking(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.directions_bus, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(conductor['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${vehiculo['modelo'] ?? ''} • ${vehiculo['placa'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: (hasLoc ? AppColors.success : AppColors.textMuted).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(hasLoc ? Icons.gps_fixed : Icons.gps_off, size: 12, color: hasLoc ? AppColors.success : AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(hasLoc ? 'En ruta' : 'Sin señal', style: TextStyle(fontSize: 10, color: hasLoc ? AppColors.success : AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          if (dias.isNotEmpty) Wrap(spacing: 6, children: dias.map((d) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)), child: Text(d[0].toUpperCase() + d.substring(1), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))).toList()),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(conductor['telefono'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${horarios['horaSalida'] ?? ''} - ${horarios['horaRetorno'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          // Botón de tracking
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openTracking(context),
              icon: Icon(hasLoc ? Icons.location_on : Icons.location_searching, size: 18),
              label: Text(hasLoc ? 'Ver ubicación del conductor' : 'Esperando señal GPS...'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: hasLoc ? AppColors.accent : AppColors.textSecondary),
                foregroundColor: hasLoc ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _openTracking(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _RouteTrackingScreen(route: route)));
  }
}

// ═══ PANTALLA DE TRACKING EN VIVO ═══
class _RouteTrackingScreen extends StatefulWidget {
  final dynamic route;
  const _RouteTrackingScreen({required this.route});

  @override
  State<_RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<_RouteTrackingScreen> {
  late dynamic _route;
  bool _polling = true;

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    _startPolling();
  }

  Future<void> _startPolling() async {
    while (_polling && mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      try {
        final res = await ApiService().get('/routes/${_route['_id']}');
        if (mounted) setState(() => _route = res.data);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _polling = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conductor = _route['conductor'] ?? {};
    final vehiculo = _route['vehiculo'] ?? {};
    final coords = _route['coordenadas'] ?? {};
    final lat = (coords['lat'] ?? 0).toDouble();
    final lng = (coords['lng'] ?? 0).toDouble();
    final hasLoc = lat != 0 || lng != 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ubicación del Conductor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info del conductor
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_pin_circle, color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(conductor['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('${vehiculo['modelo'] ?? ''} • ${vehiculo['placa'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(hasLoc ? Icons.gps_fixed : Icons.gps_off, size: 14, color: hasLoc ? AppColors.success : AppColors.error),
                    const SizedBox(width: 4),
                    Text(hasLoc ? 'Señal activa' : 'Sin señal GPS', style: TextStyle(fontSize: 12, color: hasLoc ? AppColors.success : AppColors.error)),
                  ]),
                ])),
              ]),
            ),

            // Mapa
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: hasLoc
                      ? Stack(
                          children: [
                            // Mapa embebido con Google Maps
                            Image.network(
                              'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x400&markers=color:red%7C$lat,$lng&key=YOUR_KEY',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => _mapPlaceholder(lat, lng),
                            ),
                            // Coordenadas overlay
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.location_on, color: AppColors.accent, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Lat: ${lat.toStringAsFixed(5)}  Lng: ${lng.toStringAsFixed(5)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                                  const Spacer(),
                                  const Icon(Icons.refresh, color: AppColors.accent, size: 14),
                                  const SizedBox(width: 4),
                                  const Text('5s', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                ]),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_searching, size: 56, color: AppColors.textSecondary.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text('Esperando señal GPS del conductor...', style: TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              const Text('Se actualiza cada 5 segundos', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              const SizedBox(height: 20),
                              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapPlaceholder(double lat, double lng) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map, size: 48, color: AppColors.accent),
            const SizedBox(height: 12),
            const Text('Conductor en movimiento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Lat: ${lat.toStringAsFixed(5)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text('Lng: ${lng.toStringAsFixed(5)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            const Text('Actualizando cada 5s...', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
