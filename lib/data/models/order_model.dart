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

  factory OrderItemModel.fromJson(Map json) {
    final menu = json['menu'] != null ? Map.from(json['menu']) : {};
    return OrderItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      menuId: int.tryParse(json['menu_id']?.toString() ?? '0') ?? 0,
      menuName: json['menu_name'] ?? menu['name'] ?? 'Item',
      price: double.tryParse((json['price'] ?? menu['price'])?.toString() ?? '0') ?? 0.0,
      qty: int.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final int? tableId;
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

  factory OrderModel.fromJson(Map json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final customer = json['customer'] != null ? Map.from(json['customer']) : {};
    return OrderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tableId: json['table_id'] != null ? int.tryParse(json['table_id'].toString()) : null,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? '',
      staffName: (json['staff_name'] == 'SISTEM' || json['staff_name'] == null) ? 'Jabat Kopi App' : json['staff_name'] as String,
      customerName: customer['name'] ?? json['customer_name'] ?? 'CUSTOMER TERHORMAT',
      createdAt: json['created_at'] ?? '',
      items: rawItems.map((item) => OrderItemModel.fromJson(item as Map)).toList(),
    );
  }
}
