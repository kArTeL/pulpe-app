/// The backend's JSON comes in snake_case. The mapping happens ONLY here,
/// in fromJson. The rest of the app uses normal Dart camelCase.
class Category {
  const Category({
    required this.id,
    required this.slug,
    required this.name,
  });

  final String id;
  final String slug;
  final String name;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
      );
}
