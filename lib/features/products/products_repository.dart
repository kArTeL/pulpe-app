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

/// The only place where query param names get built.
/// If you add a parameter, it goes in snake_case and needs to be added
/// to the AGENTS.md table in both repos too.
class ProductsRepository {
  const ProductsRepository(this._api);

  final ApiClient _api;

  Future<PagedResult<Product>> list({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
  }) async {
    final json = await _api.get(
      '/products',
      query: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
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
}

/// State of the listing. Keeps the accumulated pagination for infinite scroll,
/// plus the active search/category filters.
class ProductsState {
  const ProductsState({
    this.products = const [],
    this.page = 0,
    this.hasNext = true,
    this.loadingMore = false,
    this.search = '',
    this.category,
  });

  final List<Product> products;
  final int page;
  final bool hasNext;
  final bool loadingMore;
  final String search;
  final String? category;

  ProductsState copyWith({
    List<Product>? products,
    int? page,
    bool? hasNext,
    bool? loadingMore,
    String? search,
    String? category,
  }) =>
      ProductsState(
        products: products ?? this.products,
        page: page ?? this.page,
        hasNext: hasNext ?? this.hasNext,
        loadingMore: loadingMore ?? this.loadingMore,
        search: search ?? this.search,
        category: category ?? this.category,
      );
}

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.categories();
});

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, ProductsState>(
  ProductsNotifier.new,
);

class ProductsNotifier extends AsyncNotifier<ProductsState> {
  static const int _perPage = 20;

  String _search = '';
  String? _category;
  int _requestId = 0;

  @override
  Future<ProductsState> build() => _loadFirstPage(
        search: _search,
        category: _category,
      );

  Future<ProductsState> _loadFirstPage({
    required String search,
    required String? category,
  }) async {
    final repo = ref.read(productsRepositoryProvider);
    final result = await repo.list(
      page: 1,
      perPage: _perPage,
      search: search,
      category: category,
    );

    return ProductsState(
      products: result.items,
      page: result.page,
      hasNext: result.hasNext,
      search: search,
      category: category,
    );
  }

  Future<void> reload() async {
    final requestId = ++_requestId;
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _loadFirstPage(search: _search, category: _category),
    );
    if (requestId != _requestId) return;
    state = result;
  }

  Future<void> setSearch(String value) async {
    if (_search == value) return;
    _search = value;
    final requestId = ++_requestId;

    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _loadFirstPage(search: value, category: _category),
    );
    if (requestId != _requestId) return;
    state = result;
  }

  Future<void> setCategory(String? slug) async {
    if (_category == slug) return;
    _category = slug;
    final requestId = ++_requestId;

    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _loadFirstPage(search: _search, category: slug),
    );
    if (requestId != _requestId) return;
    state = result;
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNext || current.loadingMore) return;

    final requestId = ++_requestId;
    state = AsyncValue.data(current.copyWith(loadingMore: true));

    try {
      final repo = ref.read(productsRepositoryProvider);
      final result = await repo.list(
        page: current.page + 1,
        perPage: _perPage,
        search: current.search,
        category: current.category,
      );

      if (requestId != _requestId) return;
      state = AsyncValue.data(
        current.copyWith(
          products: [...current.products, ...result.items],
          page: result.page,
          hasNext: result.hasNext,
          loadingMore: false,
        ),
      );
    } catch (error, stack) {
      if (requestId != _requestId) return;
      state = AsyncValue.error(error, stack);
    }
  }
}
