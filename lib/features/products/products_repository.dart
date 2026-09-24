import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/category.dart';
import '../../models/paged_result.dart';
import '../../models/product.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.dispose);
  return client;
});

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(apiClientProvider)),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(productsRepositoryProvider).categories(),
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

  /// `GET /products/search`. Page size is fixed at 15 server-side: this
  /// endpoint never takes a `per_page` param, unlike [list].
  Future<PagedResult<Product>> search({
    String? query,
    String? category,
    int page = 1,
  }) async {
    final json = await _api.get(
      '/products/search',
      query: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
      },
    );

    return PagedResult<Product>.fromJson(json, Product.fromJson);
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

final productsProvider = AsyncNotifierProvider<ProductsNotifier, ProductsState>(
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

/// State of a product search: free-text query + category filter, with the
/// same accumulated infinite-scroll pagination as [ProductsState].
class ProductSearchState {
  const ProductSearchState({
    this.query = '',
    this.category,
    this.products = const [],
    this.page = 0,
    this.hasNext = true,
    this.loadingMore = false,
  });

  final String query;
  final String? category;
  final List<Product> products;
  final int page;
  final bool hasNext;
  final bool loadingMore;

  ProductSearchState copyWith({
    String? query,
    String? category,
    List<Product>? products,
    int? page,
    bool? hasNext,
    bool? loadingMore,
  }) =>
      ProductSearchState(
        query: query ?? this.query,
        category: category ?? this.category,
        products: products ?? this.products,
        page: page ?? this.page,
        hasNext: hasNext ?? this.hasNext,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

final productSearchProvider =
    AsyncNotifierProvider<ProductSearchNotifier, ProductSearchState>(
  ProductSearchNotifier.new,
);

/// Changing the query text or the category filter restarts pagination from
/// page 1. A generation counter guards against a stale response (from a
/// search that's since been superseded by a newer one) overwriting newer
/// state - the same shape of guard [ProductsNotifier.loadMore] uses via
/// `loadingMore` to reject a duplicate request.
class ProductSearchNotifier extends AsyncNotifier<ProductSearchState> {
  static const _debounceDuration = Duration(milliseconds: 400);

  Timer? _debounceTimer;
  int _generation = 0;
  String _query = '';
  String? _category;

  String? get selectedCategory => _category;

  @override
  Future<ProductSearchState> build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return _fetchPage(1);
  }

  Future<ProductSearchState> _fetchPage(int page) async {
    final repo = ref.read(productsRepositoryProvider);
    final result = await repo.search(
      query: _query,
      category: _category,
      page: page,
    );

    return ProductSearchState(
      query: _query,
      category: _category,
      products: result.items,
      page: result.page,
      hasNext: result.hasNext,
    );
  }

  /// Debounced: only fires a request once the user pauses typing.
  void updateQuery(String value) {
    if (value == _query) return;
    _query = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _restartSearch);
  }

  /// Not debounced: a tap is a deliberate, discrete action.
  void selectCategory(String? category) {
    if (category == _category) return;
    _category = category;
    _debounceTimer?.cancel();
    _restartSearch();
  }

  void retry() {
    _debounceTimer?.cancel();
    _restartSearch();
  }

  void _restartSearch() {
    final generation = ++_generation;
    state = const AsyncValue.loading();
    unawaited(_runSearch(generation));
  }

  Future<void> _runSearch(int generation) async {
    final result = await AsyncValue.guard(() => _fetchPage(1));
    if (generation != _generation) return;
    state = result;
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNext || current.loadingMore) return;

    final generation = _generation;
    state = AsyncValue.data(current.copyWith(loadingMore: true));

    final result = await AsyncValue.guard(() => _fetchPage(current.page + 1));
    if (generation != _generation) return;

    result.when(
      data: (next) => state = AsyncValue.data(
        current.copyWith(
          products: [...current.products, ...next.products],
          page: next.page,
          hasNext: next.hasNext,
          loadingMore: false,
        ),
      ),
      loading: () {},
      error: (error, stack) => state = AsyncValue.error(error, stack),
    );
  }
}
