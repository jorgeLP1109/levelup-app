import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.waving_hand_rounded,
      title: '¡Bienvenido a Level Up!',
      description: 'Tu app de gimnasia artística. Aquí podrás gestionar tus clases, ver tu progreso y mucho más.',
      color: Color(0xFF1E3A5F),
    ),
    _OnboardingPage(
      icon: Icons.person_rounded,
      title: 'Completa tu Perfil',
      description: 'Ve a "Mi Perfil" para agregar tu foto, datos físicos, ficha médica y contacto de emergencia. Es importante para tu seguridad.',
      color: Color(0xFF00695C),
    ),
    _OnboardingPage(
      icon: Icons.fitness_center_rounded,
      title: 'Inscríbete en Clases',
      description: 'Explora las clases disponibles, agrégalas al carrito y completa el pago para inscribirte oficialmente.',
      color: Color(0xFF1B5E20),
    ),
    _OnboardingPage(
      icon: Icons.trending_up_rounded,
      title: 'Sigue tu Progreso',
      description: 'Tu profesor registrará tus avances. Podrás ver tu evolución en la sección "Mi Progreso".',
      color: Color(0xFF4A148C),
    ),
    _OnboardingPage(
      icon: Icons.directions_bus_rounded,
      title: 'Ruta de Transporte',
      description: 'Afíliate al servicio de transporte y rastrea en tiempo real la ubicación del conductor.',
      color: Color(0xFFE65100),
    ),
    _OnboardingPage(
      icon: Icons.qr_code_rounded,
      title: 'Acceso al Gimnasio',
      description: 'Usa el código QR de la sección "Acceso" para registrar tu entrada. Se genera automáticamente si estás solvente.',
      color: Color(0xFF1565C0),
    ),
    _OnboardingPage(
      icon: Icons.shopping_cart_rounded,
      title: 'Pagos y Tienda',
      description: 'Renueva tu mensualidad, compra artículos deportivos y gestiona todo desde el carrito de compras.',
      color: Color(0xFF880E4F),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _finish,
                  child: Text('Saltar', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Indicators + Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? AppColors.accent : AppColors.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLast ? _finish : _next,
                      child: Text(
                        isLast ? '¡Comenzar!' : 'Siguiente',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _finish() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'onboarding_complete', value: 'true');
    widget.onComplete();
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: color),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
