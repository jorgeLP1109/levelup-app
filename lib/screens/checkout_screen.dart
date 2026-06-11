import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/constants.dart';
import '../providers/cart_provider.dart';
import '../services/wompi_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String checkoutUrl;
  final String transactionId;

  const CheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.transactionId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: (request) {
          // Detectar redirect de Wompi al finalizar pago
          if (request.url.contains('estado') || request.url.contains('redirect')) {
            _verificarEstado();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _verificarEstado() async {
    final wompi = WompiService();

    try {
      final result = await wompi.consultarEstado(widget.transactionId);
      final status = result['status'] as String? ?? 'UNKNOWN';

      if (!mounted) return;
      setState(() => _paymentCompleted = true);

      if (status == 'APPROVED') {
        context.read<CartProvider>().clearCart();
      }

      _showResultDialog(status);
    } catch (_) {
      if (mounted) _showResultDialog('ERROR');
    }
  }

  void _showResultDialog(String status) {
    IconData icon;
    Color color;
    String title;
    String message;

    switch (status) {
      case 'APPROVED':
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'Pago Aprobado';
        message = '¡Tu pago fue procesado exitosamente! Ya estás inscrito.';
        break;
      case 'PENDING':
        icon = Icons.access_time;
        color = Colors.orange;
        title = 'Pago Pendiente';
        message = 'Tu pago está siendo procesado. Te notificaremos cuando se confirme.';
        break;
      case 'DECLINED':
      case 'REJECTED':
        icon = Icons.cancel;
        color = AppColors.error;
        title = 'Pago Rechazado';
        message = 'No se pudo procesar el pago. Intenta con otro método de pago.';
        break;
      default:
        icon = Icons.error_outline;
        color = AppColors.textSecondary;
        title = 'Estado Desconocido';
        message = 'No pudimos verificar el estado del pago. Contacta soporte.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Volver al dashboard
                if (status == 'APPROVED') {
                  Navigator.pop(context); // Cerrar cart también
                }
              },
              child: const Text('Aceptar'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago Seguro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmarSalida(context),
        ),
      ),
      body: _paymentCompleted
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }

  void _confirmarSalida(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar pago?'),
        content: const Text('Si sales ahora, se cancelará el proceso de pago.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar pagando')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
