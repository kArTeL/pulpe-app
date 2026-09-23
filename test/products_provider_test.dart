import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulpe_app/core/api_client.dart';
import 'package:pulpe_app/features/products/products_repository.dart';

Map<String, dynamic> _product(String id, String name) => {
      'id': id,
      'sku': 'SKU-$id',
      'name': name,
      'description': 'Description for $name',
      'price': 1000,
      'stock': 5,
      'active': true,
      'image_url': null,
      'category': {'id': 'cat1', 'slug': 'abarrotes', 'name': 'Abarrotes'},
      'created_at': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _paged(List<Map<String, dynamic>> items) => {
      'items': items,
      'total': items.length,
      'page': 1,
      'per_page': 20,
      'has_next': false,
    };

/// Fake backend: /products returns products filtered in-memory by the
/// request's `search`/`category` query params, mirroring the real API's
/// contract so we can assert the notifier builds the right request and
/// resets pagination/state around it.
ProviderContainer _buildContainer() {
  final allProducts = [
    _product('1', 'Arroz Tío Pelón'),
    _product('2', 'Frijoles Rojos'),
  ];

  final client = MockClient((request) async {
    if (request.url.path == '/products') {
      final search = request.url.queryParameters['search'];
      final category = request.url.queryParameters['category'];

      var results = allProducts;
      if (search != null) {
        results = results
            .where((p) => (p['name'] as String)
                .toLowerCase()
                .contains(search.toLowerCase()))
            .toList();
      }
      if (category != null && category != 'abarrotes') {
        results = [];
      }

      return http.Response(
        jsonEncode(_paged(results)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    return http.Response(
      jsonEncode({'items': []}),
      404,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(ApiClient(client: client)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ProductsNotifier filtering', () {
    test('setSearch resets to page 1 and filters results', () async {
      final container = _buildContainer();

      await container.read(productsProvider.future);
      await container.read(productsProvider.notifier).setSearch('Arroz');

      final state = container.read(productsProvider).value!;
      expect(state.products, hasLength(1));
      expect(state.products.single.name, 'Arroz Tío Pelón');
      expect(state.page, 1);
      expect(state.search, 'Arroz');
    });

    test('setCategory resets to page 1 and filters results', () async {
      final container = _buildContainer();

      await container.read(productsProvider.future);
      await container
          .read(productsProvider.notifier)
          .setCategory('lacteos');

      final state = container.read(productsProvider).value!;
      expect(state.products, isEmpty);
      expect(state.category, 'lacteos');
    });

    test('clearing category back to null restores unfiltered results',
        () async {
      final container = _buildContainer();

      await container.read(productsProvider.future);
      await container
          .read(productsProvider.notifier)
          .setCategory('lacteos');
      await container.read(productsProvider.notifier).setCategory(null);

      final state = container.read(productsProvider).value!;
      expect(state.products, hasLength(2));
      expect(state.category, isNull);
    });

    test('a filtered result with zero matches yields an empty products list',
        () async {
      final container = _buildContainer();

      await container.read(productsProvider.future);
      await container
          .read(productsProvider.notifier)
          .setSearch('no such product');

      final state = container.read(productsProvider).value!;
      expect(state.products, isEmpty);
    });
  });
}
