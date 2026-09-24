import 'category.dart';

/// The backend's JSON comes in snake_case. The mapping happens ONLY here,
/// in fromJson. The rest of the app uses normal Dart camelCase.
class CategoryCount {
  const CategoryCount({
    required this.category,
    required this.count,
  });

  final Category category;
  final int count;

  factory CategoryCount.fromJson(Map<String, dynamic> json) => CategoryCount(
        category: Category.fromJson(json['category'] as Map<String, dynamic>),
        count: json['count'] as int,
      );
}
