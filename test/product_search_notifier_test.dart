import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulpe_app/core/api_client.dart';
import 'package:pulpe_app/features/products/products_repository.dart';
import 'package:pulpe_app/models/category.dart';
import 'package:pulpe_app/models/category_count.dart';
import 'package:pulpe_app/models/paged_result.dart';
import 'package:pulpe_app/models/product.dart';
import 'package:pulpe_app/models/product_search_result.dart';

/// A repository whose `search` calls are answered by hand-controlled
/// completers, so the test can resolve them out of the order they were
/// issued and check the notifier ignores the stale one.
class _ScriptedProductsRepository extends ProductsRepository {
  _ScriptedProductsRepository() : super(_UnusedApiClient());

  final _pending = <String, Completer<ProductSearchResult>>{};

  Completer<ProductSearchResult> pendingFor(String? category) {
    return _pending.putIfAbsent(
      category ?? '__all__',
      () => Completer<ProductSearchResult>(),
    );
  }

  @override
  Future<ProductSearchResult> search({
    String? q,
    String? category,
    int page = 1,
  }) {
    return pendingFor(category).future;
  }
}

class _UnusedApiClient extends ApiClient {}

ProductSearchResult _resultFor(String label) => ProductSearchResult(
      paged: PagedResult<Product>(
        items: const [],
        total: 0,
        page: 1,
        perPage: 15,
        hasNext: false,
      ),
      categoryCounts: [
        CategoryCount(
          category: Category(id: label, slug: label, name: label),
          count: 0,
        ),
      ],
    );

void main() {
  test(
    'a slower response from an earlier category selection does not '
    'overwrite a faster response from a later one',
    () async {
      final repo = _ScriptedProductsRepository();
      final container = ProviderContainer(
        overrides: [
          productsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Let the initial build() fetch resolve.
      repo.pendingFor(null).complete(_resultFor('initial'));
      await container.read(productSearchProvider.future);

      final notifier = container.read(productSearchProvider.notifier);

      // User selects category A (slow) then quickly selects category B.
      final selectA = notifier.selectCategory('a');
      final selectB = notifier.selectCategory('b');

      // B (issued last) resolves first.
      repo.pendingFor('b').complete(_resultFor('b'));
      await selectB;

      // A (issued first) resolves after, stale by the time it lands.
      repo.pendingFor('a').complete(_resultFor('a'));
      await selectA;

      final finalState = container.read(productSearchProvider).value!;

      expect(finalState.selectedCategorySlug, 'b');
      expect(finalState.result!.categoryCounts.single.category.slug, 'b');
    },
  );
}
