import 'package:flutter_test/flutter_test.dart';
import 'package:pulpe_app/models/category_count.dart';

void main() {
  group('CategoryCount.fromJson', () {
    test('maps the API snake_case fields', () {
      final json = <String, dynamic>{
        'category': {'id': 'cat1', 'slug': 'abarrotes', 'name': 'Abarrotes'},
        'count': 7,
      };

      final categoryCount = CategoryCount.fromJson(json);

      expect(categoryCount.category.slug, 'abarrotes');
      expect(categoryCount.category.name, 'Abarrotes');
      expect(categoryCount.count, 7);
    });

    test('allows a zero count', () {
      final json = <String, dynamic>{
        'category': {'id': 'cat2', 'slug': 'lacteos', 'name': 'Lácteos'},
        'count': 0,
      };

      expect(CategoryCount.fromJson(json).count, 0);
    });
  });
}
