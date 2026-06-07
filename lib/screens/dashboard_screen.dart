import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../models/gym_class.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  int _progressKey = 0;
  int _messagesKey = 0;
  int _routesKey = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ClassProvider>().fetchClasses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _HomeTab(),
          const _ClassesTab(),
          _ProgressTab(key: ValueKey(_progressKey)),
          _MessagesTab(key: ValueKey(_messagesKey)),
          _RoutesTab(key: ValueKey(_routesKey)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 2) _progressKey++;
          if (i == 3) _messagesKey++;
          if (i == 4) _routesKey++;
          setState(() => _currentIndex = i);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Clases'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Progreso'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Rutas'),
        ],
      ),
    );
  }
}

// ─── TAB INICIO ───
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final classProv = context.watch<ClassProvider>();
    final myClasses = classProv.getMyClasses(auth.user?.id ?? '');

    return RefreshIndicator(
      onRefresh: () => context.read<ClassProvider>().fetchClasses(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Saludo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${auth.user?.nombre ?? ""}! 👋',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bienvenido a Level Up',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Resumen
          Row(
            children: [
              _StatCard(
                icon: Icons.fitness_center,
                label: 'Mis Clases',
                value: '${myClasses.length}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.calendar_today,
                label: 'Disponibles',
                value: '${classProv.classes.length}',
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mis clases
          Text('Mis Clases Inscritas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (classProv.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (myClasses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No estás inscrito en ninguna clase')),
              ),
            )
          else
            ...myClasses.map((c) => _ClassCard(gymClass: c)),
        ],
      ),
    );
  }
}

// ─── TAB CLASES ───
class _ClassesTab extends StatelessWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final classProv = context.watch<ClassProvider>();
    final userId = auth.user?.id ?? '';

    return RefreshIndicator(
      onRefresh: () => context.read<ClassProvider>().fetchClasses(),
      child: classProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classProv.classes.length,
              itemBuilder: (context, index) {
                final c = classProv.classes[index];
                final isEnrolled = c.inscritos.any(
                  (i) => i is String ? i == userId : i['_id'] == userId,
                );
                return _ClassDetailCard(gymClass: c, isEnrolled: isEnrolled);
              },
            ),
    );
  }
}

class _ClassDetailCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isEnrolled;

  const _ClassDetailCard({required this.gymClass, required this.isEnrolled});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    gymClass.nombre,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(
                    '\$${gymClass.precio.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(gymClass.profesor, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${gymClass.diasPorSemana} días/sem', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            // Horarios
            Wrap(
              spacing: 8,
              children: gymClass.horarios.map((h) => Chip(
                label: Text('${h.dia} ${h.horaInicio}-${h.horaFin}', style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.group, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${gymClass.inscritos.length} inscritos', style: TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnrolled ? AppColors.error : AppColors.primary,
                  ),
                  onPressed: () async {
                    final prov = context.read<ClassProvider>();
                    final success = isEnrolled
                        ? await prov.unenroll(gymClass.id)
                        : await prov.enroll(gymClass.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success
                            ? (isEnrolled ? 'Desinscripción exitosa' : 'Inscripción exitosa')
                            : 'Error al procesar'),
                      ));
                    }
                  },
                  child: Text(isEnrolled ? 'Desinscribirme' : 'Inscribirme'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB PROGRESO ───
class _ProgressTab extends StatefulWidget {
  const _ProgressTab({super.key});

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  List<dynamic> _progressList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final res = await api.get('/progress');
      setState(() => _progressList = res.data as List);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchProgress,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progressList.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.trending_up, size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text('Aún no hay registros de progreso',
                              style: TextStyle(color: AppColors.textSecondary)),
                          SizedBox(height: 8),
                          Text('Tu profesor registrará tus avances aquí',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _progressList.length,
                  itemBuilder: (context, index) {
                    final p = _progressList[index];
                    final clase = p['clase'];
                    final fecha = DateTime.tryParse(p['fecha'] ?? '') ?? DateTime.now();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events, color: AppColors.accent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    clase != null ? (clase['nombre'] ?? 'Clase') : 'Clase',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Text(
                                  '${fecha.day}/${fecha.month}/${fecha.year}',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                            if (clase != null && clase['profesor'] != null) ...[
                              const SizedBox(height: 4),
                              Text('Prof. ${clase['profesor']}',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                            const SizedBox(height: 8),
                            Text(p['descripcion'] ?? '', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── TAB MENSAJES ───
class _MessagesTab extends StatefulWidget {
  const _MessagesTab({super.key});

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final res = await api.get('/messages');
      setState(() => _messages = res.data as List);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchMessages,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.mail_outline, size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text('No hay mensajes', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final fecha = DateTime.tryParse(msg['fechaPublicacion'] ?? msg['createdAt'] ?? '') ?? DateTime.now();
                    final destinatarios = msg['destinatarios'] ?? 'todos';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.campaign, color: AppColors.accent, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    msg['titulo'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: destinatarios == 'todos'
                                        ? AppColors.primary.withOpacity(0.1)
                                        : AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    destinatarios == 'todos' ? 'General' : destinatarios == 'clients' ? 'Alumnos' : 'Conductores',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: destinatarios == 'todos' ? AppColors.primary : AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(msg['contenido'] ?? '', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              '${fecha.day}/${fecha.month}/${fecha.year}',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── TAB RUTAS ───
class _RoutesTab extends StatefulWidget {
  const _RoutesTab({super.key});

  @override
  State<_RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<_RoutesTab> {
  List<dynamic> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final res = await api.get('/routes');
      setState(() => _routes = res.data as List);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _handleEnroll(String routeId, double precio) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servicio Adicional'),
        content: Text(
          'El servicio de transporte tiene un costo adicional de \$${precio.toStringAsFixed(0)}.\n\n¿Deseas afiliarte a esta ruta?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ApiService();
      await api.post('/routes/$routeId/enroll');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Afiliación exitosa')),
        );
      }
      _fetchRoutes();
    } catch (e) {
      if (mounted) {
        String msg = 'Error al afiliarse';
        try {
          final dynamic err = e;
          msg = err.response?.data['message'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _handleUnenroll(String routeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desafiliarse'),
        content: const Text('¿Estás seguro de que deseas desafiliarte de esta ruta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desafiliarme'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ApiService();
      await api.post('/routes/$routeId/unenroll');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desafiliación exitosa')),
        );
      }
      _fetchRoutes();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id ?? '';

    return RefreshIndicator(
      onRefresh: _fetchRoutes,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.directions_bus, size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text('No hay rutas activas', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final r = _routes[index];
                    final conductor = r['conductor'] ?? {};
                    final vehiculo = r['vehiculo'] ?? {};
                    final horarios = r['horarios'] ?? {};
                    final coords = r['coordenadas'] ?? {};
                    final dias = (r['dias'] as List?)?.cast<String>() ?? [];
                    final precio = (r['precio'] ?? 20).toDouble();
                    final afiliados = r['afiliados'] as List? ?? [];
                    final isEnrolled = afiliados.any(
                      (a) => a is String ? a == userId : a['_id'] == userId,
                    );
                    final hasLocation = (coords['lat'] ?? 0) != 0 || (coords['lng'] ?? 0) != 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Conductor + Estado
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.directions_bus, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conductor['nombre'] ?? 'Conductor',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        '${vehiculo['modelo'] ?? ''} • ${vehiculo['placa'] ?? ''}',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hasLocation ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hasLocation ? Icons.gps_fixed : Icons.gps_off,
                                        size: 14,
                                        color: hasLocation ? Colors.green : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasLocation ? 'En ruta' : 'Sin señal',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: hasLocation ? Colors.green : Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Dias
                            if (dias.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                children: dias.map((d) => Chip(
                                  label: Text(d[0].toUpperCase() + d.substring(1), style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )).toList(),
                              ),
                            const SizedBox(height: 8),
                            // Info
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(conductor['telefono'] ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const SizedBox(width: 16),
                                const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${horarios['horaSalida'] ?? ''} - ${horarios['horaRetorno'] ?? ''}',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Precio + Botón
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '\$${precio.toStringAsFixed(0)}/mes',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 14),
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isEnrolled ? AppColors.error : AppColors.primary,
                                  ),
                                  onPressed: () => isEnrolled
                                      ? _handleUnenroll(r['_id'])
                                      : _handleEnroll(r['_id'], precio),
                                  child: Text(isEnrolled ? 'Desafiliarme' : 'Afiliarme'),
                                ),
                              ],
                            ),
                            if (hasLocation) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lat: ${(coords['lat'] as num).toStringAsFixed(5)}, Lng: ${(coords['lng'] as num).toStringAsFixed(5)}',
                                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── WIDGETS ───
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final GymClass gymClass;
  const _ClassCard({required this.gymClass});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.fitness_center, color: Colors.white),
        ),
        title: Text(gymClass.nombre),
        subtitle: Text('${gymClass.profesor} • ${gymClass.diasPorSemana} días/semana'),
        trailing: Text(
          gymClass.horarios.isNotEmpty ? gymClass.horarios.first.horaInicio : '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
