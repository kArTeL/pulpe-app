import 'category_count.dart';
import 'paged_result.dart';
import 'product.dart';

/// The backend's JSON comes in snake_case. The mapping happens ONLY here,
/// in fromJson. The rest of the app uses normal Dart camelCase.
///
/// Wraps the paginated product search results together with the
/// `category_counts` sibling field. `categoryCounts` reflects only the
/// current `q` text filter, never the selected category.
class ProductSearchResult {
  const ProductSearchResult({
    required this.paged,
    required this.categoryCounts,
  });

  final PagedResult<Product> paged;
  final List<CategoryCount> categoryCounts;

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) =>
      ProductSearchResult(
        paged: PagedResult<Product>.fromJson(json, Product.fromJson),
        categoryCounts: (json['category_counts'] as List<dynamic>)
            .map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
