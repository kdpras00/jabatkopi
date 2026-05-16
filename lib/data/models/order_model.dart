class OrderItemModel {
  final int id;
  final int menuId;
  final String menuName;
  final double price;
  final int qty;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.price,
    required this.qty,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final menu = json['menu'] as Map<String, dynamic>? ?? {};
    return OrderItemModel(
      id: json['id'] ?? 0,
      menuId: json['menu_id'] ?? 0,
      menuName: menu['name'] ?? 'Item',
      price: (menu['price'] ?? 0).toDouble(),
      qty: json['qty'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class OrderModel {
  final int id;
  final int tableId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String staffName;
  final String customerName;
  final String createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.tableId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.staffName,
    required this.customerName,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final customer = json['customer'] as Map<String, dynamic>? ?? {};
    return OrderModel(
      id: json['id'] ?? 0,
      tableId: json['table_id'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? '',
      staffName: json['staff_name'] ?? 'SISTEM',
      customerName: customer['name'] ?? 'CUSTOMER TERHORMAT',
      createdAt: json['created_at'] ?? '',
      items: rawItems.map((item) => OrderItemModel.fromJson(item)).toList(),
    );
  }
}
