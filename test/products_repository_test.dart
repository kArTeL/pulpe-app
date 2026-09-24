import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulpe_app/core/api_client.dart';
import 'package:pulpe_app/features/products/products_repository.dart';

Map<String, dynamic> _product({String id = 'p1'}) => {
      'id': id,
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

http.Response _searchResponse({
  List<Map<String, dynamic>> items = const [],
  int page = 1,
  bool hasNext = false,
}) =>
    http.Response.bytes(
      // http.Response's String constructor defaults to latin1 encoding; the
      // API sends UTF-8 and this fixture has non-ASCII bytes ("Tío Pelón"),
      // so encode explicitly and use the bytes constructor instead.
      utf8.encode(jsonEncode({
        'items': items,
        'total': items.length,
        'page': page,
        'per_page': 15,
        'has_next': hasNext,
      })),
      200,
    );

void main() {
  group('ProductsRepository.search', () {
    test('sends q, category and page, and omits absent params', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return _searchResponse();
      });
      final repository = ProductsRepository(ApiClient(client: client));

      await repository.search(query: 'arroz', category: 'abarrotes', page: 2);

      expect(capturedUri!.path, '/products/search');
      expect(capturedUri!.queryParameters['q'], 'arroz');
      expect(capturedUri!.queryParameters['category'], 'abarrotes');
      expect(capturedUri!.queryParameters['page'], '2');
      expect(capturedUri!.queryParameters.containsKey('per_page'), isFalse);
    });

    test('omits q and category when not provided', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return _searchResponse();
      });
      final repository = ProductsRepository(ApiClient(client: client));

      await repository.search();

      expect(capturedUri!.queryParameters.containsKey('q'), isFalse);
      expect(capturedUri!.queryParameters.containsKey('category'), isFalse);
      expect(capturedUri!.queryParameters['page'], '1');
    });

    test('parses the response with the existing PagedResult/Product models',
        () async {
      final client = MockClient(
        (request) async => _searchResponse(
          items: [_product(id: 'p1'), _product(id: 'p2')],
          page: 1,
          hasNext: true,
        ),
      );
      final repository = ProductsRepository(ApiClient(client: client));

      final result = await repository.search(query: 'arroz');

      expect(result.items, hasLength(2));
      expect(result.items.first.id, 'p1');
      expect(result.perPage, 15);
      expect(result.hasNext, isTrue);
    });

    test('empty items is a normal successful response, not an error',
        () async {
      final client = MockClient((request) async => _searchResponse());
      final repository = ProductsRepository(ApiClient(client: client));

      final result = await repository.search(query: 'nonexistent');

      expect(result.items, isEmpty);
      expect(result.hasNext, isFalse);
    });
  });
}
