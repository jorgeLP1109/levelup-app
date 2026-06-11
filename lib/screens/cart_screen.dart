import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/constants.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../services/api_service.dart';
import '../services/wompi_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!cart.isEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep, color: AppColors.textSecondary), onPressed: () => _confirmClear(context, cart)),
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Tu carrito está vacío', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Clases
                      if (cart.clases.isNotEmpty) ...[
                        _sectionHeader('Clases', Icons.fitness_center),
                        ...cart.clases.map((item) => _ServiceTile(item: item)),
                        const SizedBox(height: 12),
                      ],
                      // Rutas
                      if (cart.rutas.isNotEmpty) ...[
                        _sectionHeader('Transporte', Icons.directions_bus),
                        ...cart.rutas.map((item) => _ServiceTile(item: item)),
                        const SizedBox(height: 12),
                      ],
                      // Productos
                      if (cart.productos.isNotEmpty) ...[
                        _sectionHeader('Productos', Icons.shopping_bag),
                        ...cart.productos.map((item) => _ProductTile(item: item)),
                      ],
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, -4))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Desglose
                        if (cart.clases.isNotEmpty) _desgloseRow('Clases (${cart.clases.length})', cart.clases.fold(0.0, (s, i) => s + i.subtotal)),
                        if (cart.rutas.isNotEmpty) _desgloseRow('Transporte', cart.rutas.fold(0.0, (s, i) => s + i.subtotal)),
                        if (cart.productos.isNotEmpty) _desgloseRow('Productos (${cart.productos.fold(0, (s, i) => s + i.quantity)})', cart.productos.fold(0.0, (s, i) => s + i.subtotal)),
                        const Divider(color: AppColors.secondary, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('\$${cart.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _pagarConWompi(context),
                            icon: const Icon(Icons.payment),
                            label: const Text('Pagar con Wompi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _desgloseRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text('\$${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('Vaciar carrito', style: TextStyle(color: Colors.white)),
        content: const Text('¿Vaciar todos los items?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () { cart.clearCart(); Navigator.pop(ctx); }, child: const Text('Vaciar')),
        ],
      ),
    );
  }

  void _pagarConWompi(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _WompiWebCheckout()));
  }
}

// ─── TILES ───

class _ServiceTile extends StatelessWidget {
  final CartItem item;
  const _ServiceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(item.tipo == 'clase' ? Icons.fitness_center : Icons.directions_bus, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            if (item.descripcion != null) Text(item.descripcion!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ])),
          Text('\$${item.precio.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => cart.removeFromCart(item.id), child: const Icon(Icons.close, size: 16, color: AppColors.error)),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final CartItem item;
  const _ProductTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            Text('\$${item.precio.toStringAsFixed(0)} c/u', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ])),
          // Selector de cantidad
          Container(
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(onTap: () => cart.decrementQuantity(item.id), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16, color: AppColors.textSecondary))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                GestureDetector(onTap: () => cart.incrementQuantity(item.id), child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16, color: AppColors.accent))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('\$${item.subtotal.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          GestureDetector(onTap: () => cart.removeFromCart(item.id), child: const Icon(Icons.close, size: 16, color: AppColors.error)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WOMPI WEB CHECKOUT
// ═══════════════════════════════════════════════════════════════

class _WompiWebCheckout extends StatefulWidget {
  const _WompiWebCheckout();

  @override
  State<_WompiWebCheckout> createState() => _WompiWebCheckoutState();
}

class _WompiWebCheckoutState extends State<_WompiWebCheckout> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _paymentProcessed = false;

  // Llave pública Sandbox de Wompi Colombia
  static const _wompiPublicKey = 'pub_stagtest_g2u0HQd3ZMh05hsSgTS2lUV8t3s4mOt7';
  static const _redirectUrl = 'https://levelup-gym.com/payment-result';

  @override
  void initState() {
    super.initState();
    _initCheckout();
  }

  Future<void> _initCheckout() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final ref = 'LVL-${DateTime.now().millisecondsSinceEpoch}';
    final amountCents = cart.totalCentavos;
    final email = auth.user?.email ?? '';

    // Intentar crear intento en backend
    try {
      await WompiService().crearIntentoPago(
        items: cart.items.map((i) => i.toJson()).toList(),
        total: cart.totalPrice,
        email: email,
      );
    } catch (_) {}

    // URL del Webcheckout Sandbox de Wompi
    final checkoutUrl = 'https://checkout.wompi.co/p/?public-key=$_wompiPublicKey'
        '&currency=COP'
        '&amount-in-cents=$amountCents'
        '&reference=$ref'
        '&redirect-url=$_redirectUrl'
        '&customer-data:email=$email';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) {
          if (request.url.contains('payment-result') || request.url.contains(_redirectUrl)) {
            _handlePaymentResult(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  void _handlePaymentResult(String url) async {
    if (_paymentProcessed) return;
    _paymentProcessed = true;

    final cart = context.read<CartProvider>();
    final api = ApiService();

    // Inscribir en clases y rutas
    for (final item in List<CartItem>.from(cart.items)) {
      try {
        if (item.tipo == 'clase') await api.post('/classes/${item.id}/enroll');
        if (item.tipo == 'ruta') await api.post('/routes/${item.id}/enroll');
      } catch (_) {}
    }

    cart.clearCart();

    if (mounted) {
      context.read<ClassProvider>().fetchClasses();
      _showSuccess();
    }
  }

  void _showSuccess() {
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
            Text('¡Pago Exitoso!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success)),
            SizedBox(height: 12),
            Text('Tu pago fue procesado correctamente.\nYa estás inscrito en tus servicios.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // checkout
                Navigator.pop(context); // cart
              },
              child: const Text('Volver al Inicio'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pago Seguro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.science, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text('Sandbox', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('¿Cancelar pago?', style: TextStyle(color: Colors.white)),
        content: const Text('El proceso de pago se cancelará.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar pagando')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Salir')),
        ],
      ),
    );
  }
}
