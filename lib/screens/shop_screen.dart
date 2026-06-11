import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<dynamic> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().get('/products');
      setState(() => _products = res.data as List);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tienda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 6, top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Text('${cart.itemCount}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _products.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text('No hay productos disponibles', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (_, index) => _ProductCard(product: _products[index]),
                    ),
                  ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final nombre = product['nombre'] ?? '';
    final precio = (product['precio'] ?? 0).toDouble();
    final stock = product['stock'] ?? 0;
    final fotoUrl = product['fotoUrl'] as String?;
    final id = product['_id'] ?? '';
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(id);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: inCart ? AppColors.accent.withOpacity(0.5) : AppColors.secondary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  width: double.infinity,
                  color: AppColors.primaryLight,
                  child: _buildImage(fotoUrl),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Text('\$${precio.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        if (stock > 0)
                          GestureDetector(
                            onTap: () {
                              cart.addToCart(CartItem(id: id, nombre: nombre, tipo: 'producto', precio: precio, fotoUrl: fotoUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(inCart ? 'Cantidad actualizada' : 'Agregado al carrito'), duration: const Duration(seconds: 1)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: inCart ? AppColors.accent : AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: Icon(inCart ? Icons.check : Icons.add_shopping_cart, color: inCart ? AppColors.primary : AppColors.accent, size: 18),
                            ),
                          )
                        else
                          Text('Agotado', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ProductDetailScreen(product: product)));
  }

  Widget _buildImage(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      return const Center(child: Icon(Icons.shopping_bag, color: AppColors.textSecondary, size: 40));
    }
    if (fotoUrl.startsWith('data:image')) {
      return Image.memory(base64Decode(fotoUrl.split(',').last), fit: BoxFit.cover, width: double.infinity);
    }
    return Image.network(fotoUrl, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.shopping_bag, color: AppColors.textSecondary, size: 40)));
  }
}

// ═══ DETALLE DEL PRODUCTO ═══

class _ProductDetailScreen extends StatelessWidget {
  final dynamic product;
  const _ProductDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    final nombre = product['nombre'] ?? '';
    final descripcion = product['descripcion'] ?? '';
    final precio = (product['precio'] ?? 0).toDouble();
    final stock = product['stock'] ?? 0;
    final fotoUrl = product['fotoUrl'] as String?;
    final id = product['_id'] ?? '';
    final cart = context.watch<CartProvider>();
    final inCart = cart.isInCart(id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen grande
                    Container(
                      width: double.infinity,
                      height: 280,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildImage(fotoUrl),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre
                          Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          // Precio + Stock
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                child: Text('\$${precio.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (stock > 0 ? AppColors.success : AppColors.error).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  stock > 0 ? '$stock disponibles' : 'Agotado',
                                  style: TextStyle(color: stock > 0 ? AppColors.success : AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Descripción
                          if (descripcion.isNotEmpty) ...[
                            const Text('Descripción', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(14)),
                              child: Text(descripcion, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón fijo abajo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: stock > 0
                        ? () {
                            cart.addToCart(CartItem(id: id, nombre: nombre, tipo: 'producto', precio: precio, fotoUrl: fotoUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(inCart ? 'Cantidad actualizada' : 'Agregado al carrito'), duration: const Duration(seconds: 1)),
                            );
                          }
                        : null,
                    icon: Icon(inCart ? Icons.check : Icons.add_shopping_cart),
                    label: Text(inCart ? 'Agregar otro' : 'Añadir al Carrito', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      return const Center(child: Icon(Icons.shopping_bag, color: AppColors.textSecondary, size: 64));
    }
    if (fotoUrl.startsWith('data:image')) {
      return Image.memory(base64Decode(fotoUrl.split(',').last), fit: BoxFit.cover, width: double.infinity, height: 280);
    }
    return Image.network(fotoUrl, fit: BoxFit.cover, width: double.infinity, height: 280,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.shopping_bag, color: AppColors.textSecondary, size: 64)));
  }
}
