import 'package:flutter_test/flutter_test.dart';
import 'package:pulpe_app/models/product_search_result.dart';

void main() {
  group('ProductSearchResult.fromJson', () {
    final json = <String, dynamic>{
      'items': [
        {
          'id': 'abc123',
          'sku': 'PLP-0001',
          'name': 'Arroz Tío Pelón 1.8 kg',
          'description': 'Arroz marca Tío Pelón, presentación de 1.8 kg.',
          'price': 215000,
          'stock': 42,
          'active': true,
          'image_url': null,
          'category': {
            'id': 'cat1',
            'slug': 'abarrotes',
            'name': 'Abarrotes',
          },
          'created_at': '2026-03-14T10:00:00.000Z',
        },
      ],
      'total': 1,
      'page': 1,
      'per_page': 15,
      'has_next': false,
      'category_counts': [
        {
          'category': {'id': 'cat1', 'slug': 'abarrotes', 'name': 'Abarrotes'},
          'count': 1,
        },
        {
          'category': {'id': 'cat2', 'slug': 'lacteos', 'name': 'Lácteos'},
          'count': 0,
        },
      ],
    };

    test('maps the paginated fields', () {
      final result = ProductSearchResult.fromJson(json);

      expect(result.paged.items, hasLength(1));
      expect(result.paged.items.first.sku, 'PLP-0001');
      expect(result.paged.total, 1);
      expect(result.paged.page, 1);
      expect(result.paged.perPage, 15);
      expect(result.paged.hasNext, isFalse);
    });

    test('maps category_counts', () {
      final result = ProductSearchResult.fromJson(json);

      expect(result.categoryCounts, hasLength(2));
      expect(result.categoryCounts[0].category.slug, 'abarrotes');
      expect(result.categoryCounts[0].count, 1);
      expect(result.categoryCounts[1].category.slug, 'lacteos');
      expect(result.categoryCounts[1].count, 0);
    });
  });
}
