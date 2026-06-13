import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String nombre;
  final String tipo; // 'clase', 'ruta', 'producto'
  final double precio;
  final String? descripcion;
  final String? fotoUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.precio,
    this.descripcion,
    this.fotoUrl,
    this.quantity = 1,
  });

  double get subtotal => precio * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idRef': id,
        'nombre': nombre,
        'tipo': tipo,
        'precio': precio,
        'cantidad': quantity,
      };
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  List<CartItem> get clases => _items.where((i) => i.tipo == 'clase').toList();
  List<CartItem> get rutas => _items.where((i) => i.tipo == 'ruta').toList();
  List<CartItem> get productos => _items.where((i) => i.tipo == 'producto').toList();

  /// Monto total en centavos (para Wompi)
  int get totalCentavos => (totalPrice * 100).round();

  bool isInCart(String id) => _items.any((item) => item.id == id);

  void addToCart(CartItem item) {
    final existing = _items.where((i) => i.id == item.id).firstOrNull;
    if (existing != null) {
      // Solo productos permiten sumar cantidad
      if (item.tipo == 'producto') {
        existing.quantity++;
        notifyListeners();
      }
      return;
    }
    _items.add(item);
    notifyListeners();
  }

  void removeFromCart(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void incrementQuantity(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item != null && item.tipo == 'producto') {
      item.quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item != null && item.tipo == 'producto') {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _items.remove(item);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
