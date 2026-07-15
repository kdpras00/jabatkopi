class MenuModel {
  final int id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String imageUrl;
  final bool isAvailable;
  final int stock;

  MenuModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.isAvailable,
    required this.stock,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      isAvailable: json['is_available'] == 1 || json['is_available'] == true || json['is_available'] == '1',
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
    );
  }
}
