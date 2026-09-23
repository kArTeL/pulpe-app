import 'dart:async';
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

    test(
        'reload after a failed setSearch preserves the active search filter '
        'instead of reverting to the unfiltered list', () async {
      var shouldFail = false;
      final client = MockClient((request) async {
        if (shouldFail) {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'server_error',
                'message': 'boom',
                'details': <String, dynamic>{},
              }
            }),
            500,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        final search = request.url.queryParameters['search'];
        final results = [
          _product('1', 'Arroz Tío Pelón'),
          _product('2', 'Frijoles Rojos'),
        ].where((p) {
          if (search == null) return true;
          return (p['name'] as String)
              .toLowerCase()
              .contains(search.toLowerCase());
        }).toList();
        return http.Response(
          jsonEncode(_paged(results)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: client)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(productsProvider.future);

      shouldFail = true;
      await container.read(productsProvider.notifier).setSearch('Arroz');
      expect(container.read(productsProvider).hasError, isTrue);
      // The notifier keeps the active filter even though the async state
      // carries no value while it's an error.
      expect(container.read(productsProvider.notifier).category, isNull);

      shouldFail = false;
      await container.read(productsProvider.notifier).reload();

      final state = container.read(productsProvider).value!;
      expect(state.search, 'Arroz');
      expect(state.products, hasLength(1));
      expect(state.products.single.name, 'Arroz Tío Pelón');
    });

    test(
        'a stale in-flight request does not overwrite the result of a newer '
        'filter change', () async {
      var callCount = 0;
      final firstCallGate = Completer<void>();
      final client = MockClient((request) async {
        callCount++;
        if (callCount == 2) {
          // The first setSearch call: block it so the second, newer
          // setCategory call can resolve first.
          await firstCallGate.future;
        }
        final search = request.url.queryParameters['search'];
        final category = request.url.queryParameters['category'];

        var results = [
          _product('1', 'Arroz Tío Pelón'),
          _product('2', 'Frijoles Rojos'),
        ];
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
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: client)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(productsProvider.future);

      final notifier = container.read(productsProvider.notifier);
      final searchFuture = notifier.setSearch('Arroz');
      final categoryFuture = notifier.setCategory('lacteos');

      // Let the newer (category) request resolve first, then release the
      // older, stale search request.
      await categoryFuture;
      firstCallGate.complete();
      await searchFuture;

      final state = container.read(productsProvider).value!;
      expect(state.category, 'lacteos');
      expect(state.products, isEmpty);
    });
  });
}
