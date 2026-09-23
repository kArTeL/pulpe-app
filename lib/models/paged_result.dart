/// Standard wrapper for every paginated API response.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.hasNext,
  });

  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final bool hasNext;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) map,
  ) =>
      PagedResult<T>(
        items: (json['items'] as List<dynamic>)
            .map((e) => map(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        perPage: json['per_page'] as int,
        hasNext: json['has_next'] as bool,
      );
}
