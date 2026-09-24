import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulpe_app/core/api_client.dart';
import 'package:pulpe_app/features/products/products_repository.dart';

Map<String, dynamic> _product({required String id}) => {
      'id': id,
      'sku': 'PLP-$id',
      'name': 'Product $id',
      'description': 'Description of $id',
      'price': 1000,
      'stock': 5,
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
      utf8.encode(jsonEncode({
        'items': items,
        'total': items.length,
        'page': page,
        'per_page': 15,
        'has_next': hasNext,
      })),
      200,
    );

/// Polls until the provider is no longer in a loading state. Used instead
/// of relying on `productSearchProvider.future` because our notifier
/// reassigns `state` outside of `build()` (debounced search, retry).
Future<void> _waitUntilSettled(ProviderContainer container) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (container.read(productSearchProvider).isLoading) {
    if (DateTime.now().isAfter(deadline)) {
      fail('productSearchProvider did not settle in time');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('ProductSearchNotifier', () {
    test('changing the query resets pagination and discards prior results',
        () async {
      final client = MockClient((request) async {
        final q = request.url.queryParameters['q'];
        final page = int.parse(request.url.queryParameters['page']!);

        if (q == null) {
          if (page == 1) {
            return _searchResponse(
              items: [_product(id: 'p1'), _product(id: 'p2')],
              hasNext: true,
            );
          }
          if (page == 2) {
            return _searchResponse(items: [_product(id: 'p3')], page: 2);
          }
        }
        if (q == 'arroz' && page == 1) {
          return _searchResponse(items: [_product(id: 'p4')]);
        }
        throw StateError('unexpected request: ${request.url}');
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: client)),
        ],
      );
      addTearDown(container.dispose);

      await _waitUntilSettled(container);
      final notifier = container.read(productSearchProvider.notifier);

      await notifier.loadMore();
      var state = container.read(productSearchProvider).value!;
      expect(state.products.map((p) => p.id), ['p1', 'p2', 'p3']);
      expect(state.page, 2);

      notifier.updateQuery('arroz');
      // Debounce is 400ms; wait past it, then poll for settle.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await _waitUntilSettled(container);

      state = container.read(productSearchProvider).value!;
      expect(state.query, 'arroz');
      expect(state.products.map((p) => p.id), ['p4']);
      expect(state.page, 1);
    });

    test('changing the category resets pagination and discards prior results',
        () async {
      final client = MockClient((request) async {
        final category = request.url.queryParameters['category'];
        final page = int.parse(request.url.queryParameters['page']!);

        if (category == null) {
          if (page == 1) {
            return _searchResponse(
              items: [_product(id: 'p1'), _product(id: 'p2')],
              hasNext: true,
            );
          }
          if (page == 2) {
            return _searchResponse(items: [_product(id: 'p3')], page: 2);
          }
        }
        if (category == 'bebidas' && page == 1) {
          return _searchResponse(items: [_product(id: 'p5')]);
        }
        throw StateError('unexpected request: ${request.url}');
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: client)),
        ],
      );
      addTearDown(container.dispose);

      await _waitUntilSettled(container);
      final notifier = container.read(productSearchProvider.notifier);

      await notifier.loadMore();
      var state = container.read(productSearchProvider).value!;
      expect(state.products.map((p) => p.id), ['p1', 'p2', 'p3']);

      notifier.selectCategory('bebidas');
      await _waitUntilSettled(container);

      state = container.read(productSearchProvider).value!;
      expect(state.category, 'bebidas');
      expect(state.products.map((p) => p.id), ['p5']);
      expect(state.page, 1);
    });

    test('loadMore appends items and stops once has_next is false', () async {
      var page3Requests = 0;
      final client = MockClient((request) async {
        final page = int.parse(request.url.queryParameters['page']!);
        if (page == 1) {
          return _searchResponse(
            items: [_product(id: 'p1'), _product(id: 'p2')],
            hasNext: true,
          );
        }
        if (page == 2) {
          return _searchResponse(items: [_product(id: 'p3')], page: 2);
        }
        page3Requests++;
        return _searchResponse();
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: client)),
        ],
      );
      addTearDown(container.dispose);

      await _waitUntilSettled(container);
      final notifier = container.read(productSearchProvider.notifier);

      var state = container.read(productSearchProvider).value!;
      expect(state.hasNext, isTrue);

      await notifier.loadMore();
      state = container.read(productSearchProvider).value!;
      expect(state.products.map((p) => p.id), ['p1', 'p2', 'p3']);
      expect(state.hasNext, isFalse);

      await notifier.loadMore();
      expect(page3Requests, 0);
    });

    test('a stale response does not overwrite a newer search result', () async {
      final completers = {
        'a': Completer<http.Response>(),
        'b': Completer<http.Response>(),
      };

      final client = MockClient((request) async {
        final category = request.url.queryParameters['category'];
        if (category == null) {
          return _searchResponse(items: [_product(id: 'initial')]);
        }
        return completers[category]!.future;
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: client)),
        ],
      );
      addTearDown(container.dispose);

      await _waitUntilSettled(container);
      final notifier = container.read(productSearchProvider.notifier);

      notifier.selectCategory('a');
      notifier.selectCategory('b');

      completers['b']!.complete(
        _searchResponse(items: [_product(id: 'catB')]),
      );
      await _waitUntilSettled(container);

      expect(
        container.read(productSearchProvider).value!.products.map((p) => p.id),
        ['catB'],
      );

      completers['a']!.complete(
        _searchResponse(items: [_product(id: 'catA')]),
      );
      // Give the stale future a chance to resolve; it must not apply.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        container.read(productSearchProvider).value!.products.map((p) => p.id),
        ['catB'],
      );
    });

    test('retry re-issues the current query and category', () async {
      var attempt = 0;
      final client = MockClient((request) async {
        attempt++;
        if (attempt == 1) {
          throw Exception('boom');
        }
        return _searchResponse(items: [_product(id: 'recovered')]);
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: client)),
        ],
      );
      addTearDown(container.dispose);

      await _waitUntilSettled(container);
      expect(container.read(productSearchProvider).hasError, isTrue);

      container.read(productSearchProvider.notifier).retry();
      await _waitUntilSettled(container);

      expect(container.read(productSearchProvider).hasError, isFalse);
      expect(
        container.read(productSearchProvider).value!.products.map((p) => p.id),
        ['recovered'],
      );
    });
  });
}
