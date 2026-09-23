import 'package:flutter_test/flutter_test.dart';
import 'package:pulpe_app/models/product.dart';

void main() {
  group('Product.fromJson', () {
    final json = <String, dynamic>{
      'id': 'abc123',
      'sku': 'PLP-0001',
      'name': 'Arroz Tío Pelón 1.8 kg',
      'description': 'Arroz marca Tío Pelón, presentación de 1.8 kg.',
      'price': 215000,
      'stock': 42,
      'active': true,
      'image_url': null,
      'category': {'id': 'cat1', 'slug': 'abarrotes', 'name': 'Abarrotes'},
      'created_at': '2026-03-14T10:00:00.000Z',
    };

    test('maps the API snake_case fields', () {
      final product = Product.fromJson(json);

      expect(product.sku, 'PLP-0001');
      expect(product.price, 215000);
      expect(product.imageUrl, isNull);
      expect(product.category.slug, 'abarrotes');
      expect(product.createdAt.year, 2026);
    });

    test('inStock reflects the inventory', () {
      expect(Product.fromJson(json).inStock, isTrue);

      final soldOut = Product.fromJson({...json, 'stock': 0});
      expect(soldOut.inStock, isFalse);
    });
  });
}
