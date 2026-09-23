import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulpe_app/core/api_client.dart';
import 'package:pulpe_app/features/products/product_search_screen.dart';
import 'package:pulpe_app/features/products/products_repository.dart';
import 'package:pulpe_app/models/category.dart';
import 'package:pulpe_app/models/category_count.dart';
import 'package:pulpe_app/models/paged_result.dart';
import 'package:pulpe_app/models/product.dart';
import 'package:pulpe_app/models/product_search_result.dart';

class _UnusedApiClient extends ApiClient {}

class _FakeProductsRepository extends ProductsRepository {
  _FakeProductsRepository(this.responder) : super(_UnusedApiClient());

  final Future<ProductSearchResult> Function(String? q, String? category)
      responder;
  final List<String?> qCalls = [];

  @override
  Future<ProductSearchResult> search({
    String? q,
    String? category,
    int page = 1,
  }) {
    qCalls.add(q);
    return responder(q, category);
  }
}

Product _product(String id) => Product(
      id: id,
      sku: 'SKU-$id',
      name: 'Product $id',
      description: 'desc',
      price: 100000,
      stock: 5,
      active: true,
      category: const Category(id: 'cat1', slug: 'abarrotes', name: 'Abarrotes'),
      createdAt: DateTime(2026, 1, 1),
    );

ProductSearchResult _resultWithItems(List<String> ids) => ProductSearchResult(
      paged: PagedResult<Product>(
        items: ids.map(_product).toList(),
        total: ids.length,
        page: 1,
        perPage: 15,
        hasNext: false,
      ),
      categoryCounts: const [
        CategoryCount(
          category: Category(id: 'cat1', slug: 'abarrotes', name: 'Abarrotes'),
          count: 1,
        ),
      ],
    );

final _emptyResult = ProductSearchResult(
  paged: const PagedResult<Product>(
    items: [],
    total: 0,
    page: 1,
    perPage: 15,
    hasNext: false,
  ),
  categoryCounts: const [],
);

Widget _wrap(ProductsRepository repo) => ProviderScope(
      overrides: [productsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: ProductSearchScreen()),
    );

void main() {
  testWidgets('renders the fetched products once loading completes',
      (tester) async {
    final repo = _FakeProductsRepository(
      (q, category) async => _resultWithItems(['p1', 'p2']),
    );

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Product p1'), findsOneWidget);
    expect(find.text('Product p2'), findsOneWidget);
    expect(find.text('Abarrotes (1)'), findsOneWidget);
  });

  testWidgets('shows the empty state when no products match',
      (tester) async {
    final repo = _FakeProductsRepository((q, category) async => _emptyResult);

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('No products match your search.'), findsOneWidget);
  });

  testWidgets('shows an error with a retry button, and retry re-fetches',
      (tester) async {
    var shouldFail = true;
    final repo = _FakeProductsRepository((q, category) async {
      if (shouldFail) throw NetworkException('down');
      return _resultWithItems(['p1']);
    });

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not connect to the server.\nCheck that pulpe-api is running.'),
      findsOneWidget,
    );

    shouldFail = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Product p1'), findsOneWidget);
  });

  testWidgets('typing search text is debounced before fetching',
      (tester) async {
    final repo = _FakeProductsRepository(
      (q, category) async => _resultWithItems(['p1']),
    );

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    expect(repo.qCalls, [null]);

    await tester.enterText(find.byType(TextField), 'arroz');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.qCalls, [null], reason: 'fetch must not fire before debounce elapses');

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(repo.qCalls, [null, 'arroz']);
  });
}
