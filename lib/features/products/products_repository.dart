import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/category.dart';
import '../../models/paged_result.dart';
import '../../models/product.dart';
import '../../models/product_search_result.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.dispose);
  return client;
});

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(apiClientProvider)),
);

/// The only place where query param names get built.
/// If you add a parameter, it goes in snake_case and needs to be added
/// to the AGENTS.md table in both repos too.
class ProductsRepository {
  const ProductsRepository(this._api);

  final ApiClient _api;

  Future<PagedResult<Product>> list({
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _api.get(
      '/products',
      query: {
        'page': page,
        'per_page': perPage,
      },
    );

    return PagedResult<Product>.fromJson(json, Product.fromJson);
  }

  /// Search screen listing: free text (`q`) and an optional category slug,
  /// always at a fixed page size of 15. Returns both the paginated items
  /// and the per-category counts for the current `q`.
  Future<ProductSearchResult> search({
    String? q,
    String? category,
    int page = 1,
  }) async {
    final json = await _api.get(
      '/products',
      query: {
        'q': q,
        'category': category,
        'page': page,
        'per_page': 15,
      },
    );

    return ProductSearchResult.fromJson(json);
  }

  Future<Product> detail(String id) async {
    final json = await _api.get('/products/$id');
    return Product.fromJson(json);
  }

  Future<List<Category>> categories() async {
    final json = await _api.get('/categories');
    return (json['items'] as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// State of the listing. Keeps the accumulated pagination for infinite scroll.
class ProductsState {
  const ProductsState({
    this.products = const [],
    this.page = 0,
    this.hasNext = true,
    this.loadingMore = false,
  });

  final List<Product> products;
  final int page;
  final bool hasNext;
  final bool loadingMore;

  ProductsState copyWith({
    List<Product>? products,
    int? page,
    bool? hasNext,
    bool? loadingMore,
  }) =>
      ProductsState(
        products: products ?? this.products,
        page: page ?? this.page,
        hasNext: hasNext ?? this.hasNext,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, ProductsState>(
  ProductsNotifier.new,
);

class ProductsNotifier extends AsyncNotifier<ProductsState> {
  static const int _perPage = 20;

  @override
  Future<ProductsState> build() => _loadFirstPage();

  Future<ProductsState> _loadFirstPage() async {
    final repo = ref.read(productsRepositoryProvider);
    final result = await repo.list(page: 1, perPage: _perPage);

    return ProductsState(
      products: result.items,
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));

    try {
      final repo = ref.read(productsRepositoryProvider);
      final result = await repo.list(
        page: current.page + 1,
        perPage: _perPage,
      );

      state = AsyncValue.data(
        current.copyWith(
          products: [...current.products, ...result.items],
          page: result.page,
          hasNext: result.hasNext,
          loadingMore: false,
        ),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

/// State of the search screen: current inputs plus the latest result.
class ProductSearchState {
  const ProductSearchState({
    this.queryText = '',
    this.selectedCategorySlug,
    this.page = 1,
    this.result,
  });

  final String queryText;
  final String? selectedCategorySlug;
  final int page;
  final ProductSearchResult? result;

  ProductSearchState copyWith({
    String? queryText,
    String? selectedCategorySlug,
    bool clearSelectedCategory = false,
    int? page,
    ProductSearchResult? result,
  }) =>
      ProductSearchState(
        queryText: queryText ?? this.queryText,
        selectedCategorySlug: clearSelectedCategory
            ? null
            : (selectedCategorySlug ?? this.selectedCategorySlug),
        page: page ?? this.page,
        result: result ?? this.result,
      );
}

final productSearchProvider =
    AsyncNotifierProvider<ProductSearchNotifier, ProductSearchState>(
  ProductSearchNotifier.new,
);

/// Drives the search screen. Free-text changes are debounced before
/// triggering a fetch; category and page changes fetch immediately.
///
/// `categoryCounts` in the fetched result always reflects `queryText` only
/// (the backend computes it from `q` alone, never `category`), so it stays
/// stable across category switches by construction - see design.md.
class ProductSearchNotifier extends AsyncNotifier<ProductSearchState> {
  static const _debounceDuration = Duration(milliseconds: 400);

  Timer? _debounce;

  @override
  Future<ProductSearchState> build() {
    ref.onDispose(() => _debounce?.cancel());
    return _fetch(const ProductSearchState());
  }

  Future<ProductSearchState> _fetch(ProductSearchState inputs) async {
    final repo = ref.read(productsRepositoryProvider);
    final result = await repo.search(
      q: inputs.queryText.isEmpty ? null : inputs.queryText,
      category: inputs.selectedCategorySlug,
      page: inputs.page,
    );

    return inputs.copyWith(result: result);
  }

  void setQueryText(String text) {
    _debounce?.cancel();
    final current = state.valueOrNull ?? const ProductSearchState();
    final inputs = current.copyWith(queryText: text, page: 1);

    _debounce = Timer(_debounceDuration, () async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetch(inputs));
    });
  }

  Future<void> selectCategory(String? categorySlug) async {
    _debounce?.cancel();
    final current = state.valueOrNull ?? const ProductSearchState();
    final inputs = current.copyWith(
      selectedCategorySlug: categorySlug,
      clearSelectedCategory: categorySlug == null,
      page: 1,
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(inputs));
  }

  Future<void> goToPage(int page) async {
    _debounce?.cancel();
    final current = state.valueOrNull ?? const ProductSearchState();
    final inputs = current.copyWith(page: page);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(inputs));
  }

  Future<void> retry() async {
    _debounce?.cancel();
    final inputs = state.valueOrNull ?? const ProductSearchState();

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(inputs));
  }
}
