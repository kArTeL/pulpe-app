import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pulpe_app/core/api_client.dart';
import 'package:pulpe_app/features/products/products_repository.dart';
import 'package:pulpe_app/models/category_count.dart';
import 'package:pulpe_app/models/product_search_result.dart';
import 'package:pulpe_app/models/product.dart';

class _CapturingClient extends http.BaseClient {
  Uri? lastUri;

  final Map<String, dynamic> responseBody;

  _CapturingClient(this.responseBody);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    final body = utf8.encode(jsonEncode(responseBody));
    return http.StreamedResponse(
      Stream.value(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

Map<String, dynamic> _productJson() => {
      'id': 'p1',
      'sku': 'PLP-0002',
      'name': 'Frijoles Negros 900 g',
      'description': 'Frijoles negros en lata, 900 g.',
      'price': 125000,
      'stock': 10,
      'active': true,
      'image_url': null,
      'category': {'id': 'cat1', 'slug': 'abarrotes', 'name': 'Abarrotes'},
      'created_at': '2026-03-14T10:00:00.000Z',
    };

void main() {
  group('CategoryCount.fromJson', () {
    test('maps the API snake_case fields', () {
      final json = <String, dynamic>{
        'category': {'id': 'cat1', 'slug': 'abarrotes', 'name': 'Abarrotes'},
        'count': 7,
      };

      final categoryCount = CategoryCount.fromJson(json);

      expect(categoryCount.category.slug, 'abarrotes');
      expect(categoryCount.count, 7);
    });
  });

  group('ProductSearchResult.fromJson', () {
    test('maps items, pagination and category_counts', () {
      final json = <String, dynamic>{
        'items': [_productJson()],
        'total': 1,
        'page': 1,
        'per_page': 15,
        'has_next': false,
        'category_counts': [
          {
            'category': {'id': 'cat1', 'slug': 'abarrotes', 'name': 'Abarrotes'},
            'count': 1,
          },
        ],
      };

      final result =
          ProductSearchResult<Product>.fromJson(json, Product.fromJson);

      expect(result.items, hasLength(1));
      expect(result.total, 1);
      expect(result.perPage, 15);
      expect(result.hasNext, isFalse);
      expect(result.categoryCounts, hasLength(1));
      expect(result.categoryCounts.single.category.slug, 'abarrotes');
      expect(result.categoryCounts.single.count, 1);
    });
  });

  group('ProductsRepository.search', () {
    Map<String, dynamic> emptyResponse() => {
          'items': <dynamic>[],
          'total': 0,
          'page': 1,
          'per_page': 15,
          'has_next': false,
          'category_counts': <dynamic>[],
        };

    test('builds snake_case query params with q and category', () async {
      final client = _CapturingClient(emptyResponse());
      final repo = ProductsRepository(ApiClient(client: client));

      await repo.search(q: 'frijoles', category: 'abarrotes', page: 2, perPage: 15);

      final query = client.lastUri!.queryParameters;
      expect(client.lastUri!.path, '/products/search');
      expect(query['q'], 'frijoles');
      expect(query['category'], 'abarrotes');
      expect(query['page'], '2');
      expect(query['per_page'], '15');
    });

    test('omits q and category when null or empty', () async {
      final client = _CapturingClient(emptyResponse());
      final repo = ProductsRepository(ApiClient(client: client));

      await repo.search();

      final query = client.lastUri!.queryParameters;
      expect(query.containsKey('q'), isFalse);
      expect(query.containsKey('category'), isFalse);
      expect(query['page'], '1');
      expect(query['per_page'], '15');
    });

    test('omits q when empty string', () async {
      final client = _CapturingClient(emptyResponse());
      final repo = ProductsRepository(ApiClient(client: client));

      await repo.search(q: '', category: '');

      final query = client.lastUri!.queryParameters;
      expect(query.containsKey('q'), isFalse);
      expect(query.containsKey('category'), isFalse);
    });
  });
}
