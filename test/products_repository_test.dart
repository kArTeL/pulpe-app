import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulpe_app/core/api_client.dart';
import 'package:pulpe_app/features/products/products_repository.dart';

Map<String, dynamic> _pagedResponse({List<dynamic> items = const []}) => {
      'items': items,
      'total': items.length,
      'page': 1,
      'per_page': 20,
      'has_next': false,
    };

void main() {
  group('ProductsRepository.list query params', () {
    late Uri capturedUri;

    ProductsRepository buildRepository() {
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode(_pagedResponse()), 200);
      });
      return ProductsRepository(ApiClient(client: client));
    }

    test('omits search and category when not provided', () async {
      final repo = buildRepository();

      await repo.list(page: 1, perPage: 20);

      expect(capturedUri.queryParameters.containsKey('search'), isFalse);
      expect(capturedUri.queryParameters.containsKey('category'), isFalse);
    });

    test('omits search when it is empty or whitespace only', () async {
      final repo = buildRepository();

      await repo.list(page: 1, perPage: 20, search: '   ');

      expect(capturedUri.queryParameters.containsKey('search'), isFalse);
    });

    test('includes trimmed search as snake_case "search" param', () async {
      final repo = buildRepository();

      await repo.list(page: 1, perPage: 20, search: '  arroz  ');

      expect(capturedUri.queryParameters['search'], 'arroz');
    });

    test('omits category when null or empty', () async {
      final repo = buildRepository();

      await repo.list(page: 1, perPage: 20, category: '');

      expect(capturedUri.queryParameters.containsKey('category'), isFalse);
    });

    test('includes category as snake_case "category" param', () async {
      final repo = buildRepository();

      await repo.list(page: 1, perPage: 20, category: 'abarrotes');

      expect(capturedUri.queryParameters['category'], 'abarrotes');
    });

    test('sends search and category together with page/per_page', () async {
      final repo = buildRepository();

      await repo.list(
        page: 2,
        perPage: 10,
        search: 'leche',
        category: 'lacteos',
      );

      expect(capturedUri.queryParameters['page'], '2');
      expect(capturedUri.queryParameters['per_page'], '10');
      expect(capturedUri.queryParameters['search'], 'leche');
      expect(capturedUri.queryParameters['category'], 'lacteos');
    });
  });
}
