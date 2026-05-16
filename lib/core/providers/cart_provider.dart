import 'package:flutter/material.dart';
import '../../data/models/menu_model.dart';

class CartItem {
  final MenuModel menu;
  int quantity;

  CartItem({required this.menu, this.quantity = 1});

  double get totalPrice => menu.price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  int? _tableId;

  List<CartItem> get items => _items;
  int? get tableId => _tableId;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get tax {
    return subtotal * 0.10; // 10% tax
  }

  double get totalAmount {
    return subtotal + tax;
  }

  bool addItem(MenuModel menu, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.menu.id == menu.id);
    if (existingIndex >= 0) {
      final newQty = _items[existingIndex].quantity + quantity;
      if (newQty > menu.stock) {
        _items[existingIndex].quantity = menu.stock;
        notifyListeners();
        return false; // Limit reached
      }
      _items[existingIndex].quantity = newQty;
    } else {
      if (quantity > menu.stock) {
        _items.add(CartItem(menu: menu, quantity: menu.stock));
        notifyListeners();
        return false; // Limit reached
      }
      _items.add(CartItem(menu: menu, quantity: quantity));
    }
    notifyListeners();
    return true;
  }

  void removeItem(int menuId) {
    _items.removeWhere((item) => item.menu.id == menuId);
    notifyListeners();
  }

  bool updateQuantity(int menuId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(menuId);
      return true;
    }
    final index = _items.indexWhere((item) => item.menu.id == menuId);
    if (index >= 0) {
      if (newQuantity > _items[index].menu.stock) {
        _items[index].quantity = _items[index].menu.stock;
        notifyListeners();
        return false; // Limit reached
      }
      _items[index].quantity = newQuantity;
      notifyListeners();
      return true;
    }
    return false;
  }

  void clearCart() {
    _items.clear();
    _tableId = null;
    notifyListeners();
  }

  void setTableId(int id) {
    _tableId = id;
    notifyListeners();
  }
}
