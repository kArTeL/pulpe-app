import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulpe_app/core/api_client.dart';
import 'package:pulpe_app/features/products/product_search_screen.dart';
import 'package:pulpe_app/features/products/products_repository.dart';

http.Response _jsonResponse(Map<String, dynamic> body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
    );

http.Response _searchResponse({
  List<Map<String, dynamic>> items = const [],
  bool hasNext = false,
}) =>
    _jsonResponse({
      'items': items,
      'total': items.length,
      'page': 1,
      'per_page': 15,
      'has_next': hasNext,
    });

Future<void> _pumpScreen(WidgetTester tester, http.Client client) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(client: client)),
      ],
      child: const MaterialApp(home: ProductSearchScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  group('ProductSearchScreen', () {
    testWidgets('shows an empty state when the search has no matches',
        (tester) async {
      final client = MockClient((request) async {
        if (request.url.path == '/categories') {
          return _jsonResponse({'items': <Map<String, dynamic>>[]});
        }
        return _searchResponse();
      });

      await _pumpScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('No products match your search.'), findsOneWidget);
    });

    testWidgets(
        'shows an error state with a retry control that recovers on tap',
        (tester) async {
      var attempt = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/categories') {
          return _jsonResponse({'items': <Map<String, dynamic>>[]});
        }
        attempt++;
        if (attempt == 1) {
          // ApiClient wraps any transport-level failure as NetworkException.
          throw Exception('boom');
        }
        return _searchResponse();
      });

      await _pumpScreen(tester, client);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not connect to the server.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not connect to the server.'),
        findsNothing,
      );
      expect(find.text('No products match your search.'), findsOneWidget);
    });
  });
}
