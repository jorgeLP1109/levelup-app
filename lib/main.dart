import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/class_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/teachers_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/access_qr_screen.dart';
import 'screens/ad_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Level2026App());
}

class Level2026App extends StatelessWidget {
  const Level2026App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/forgot-password': (_) => const ForgotPasswordScreen(),
          '/dashboard': (_) => const _DashboardWithAd(),
          '/profile': (_) => const ProfileScreen(),
          '/cart': (_) => const CartScreen(),
          '/teachers': (_) => const TeachersScreen(),
          '/shop': (_) => const ShopScreen(),
          '/access': (_) => const AccessQRScreen(),
        },
      ),
    );
  }
}

/// Wrapper que muestra Onboarding (primera vez) y Ad antes del Dashboard
class _DashboardWithAd extends StatefulWidget {
  const _DashboardWithAd();

  @override
  State<_DashboardWithAd> createState() => _DashboardWithAdState();
}

enum _AppState { loading, onboarding, ad, dashboard }

class _DashboardWithAdState extends State<_DashboardWithAd> {
  _AppState _state = _AppState.loading;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    const storage = FlutterSecureStorage();
    final onboardingDone = await storage.read(key: 'onboarding_complete');

    if (onboardingDone == null) {
      setState(() => _state = _AppState.onboarding);
    } else {
      setState(() => _state = _AppState.ad);
    }
  }

  void _onOnboardingComplete() {
    setState(() => _state = _AppState.ad);
  }

  void _onAdComplete() {
    setState(() => _state = _AppState.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AppState.loading:
        return const Scaffold(
          backgroundColor: Color(0xFF0A192F),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF64FFDA))),
        );
      case _AppState.onboarding:
        return OnboardingScreen(onComplete: _onOnboardingComplete);
      case _AppState.ad:
        return AdScreen(onComplete: _onAdComplete);
      case _AppState.dashboard:
        return const DashboardScreen();
    }
  }
}
