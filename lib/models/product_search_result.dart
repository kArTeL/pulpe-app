import 'category_count.dart';

/// Result wrapper for `GET /products/search`. Kept separate from
/// `PagedResult` (which is deliberately generic and shared by any plain
/// paginated listing) because search also carries `category_counts`.
class ProductSearchResult<T> {
  const ProductSearchResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.hasNext,
    required this.categoryCounts,
  });

  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final bool hasNext;
  final List<CategoryCount> categoryCounts;

  factory ProductSearchResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) map,
  ) =>
      ProductSearchResult<T>(
        items: (json['items'] as List<dynamic>)
            .map((e) => map(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        perPage: json['per_page'] as int,
        hasNext: json['has_next'] as bool,
        categoryCounts: (json['category_counts'] as List<dynamic>)
            .map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
