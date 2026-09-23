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
