import 'category.dart';

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.active,
    required this.category,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String sku;
  final String name;
  final String description;

  /// Colón cents. Always format with Format.price().
  final int price;
  final int stock;
  final bool active;
  final Category category;
  final DateTime createdAt;
  final String? imageUrl;

  bool get inStock => stock > 0;

  /// NOTE: the keys on the left are snake_case because that's how the API
  /// sends them. Don't "fix" them to camelCase: the backend won't recognize them.
  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        sku: json['sku'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        price: json['price'] as int,
        stock: json['stock'] as int,
        active: json['active'] as bool,
        imageUrl: json['image_url'] as String?,
        category: Category.fromJson(json['category'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
