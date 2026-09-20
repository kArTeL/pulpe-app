/// Los JSON del backend vienen en snake_case. El mapeo se hace SOLO acá,
/// en fromJson. El resto de la app usa camelCase de Dart con normalidad.
class Categoria {
  const Categoria({
    required this.id,
    required this.slug,
    required this.nombre,
  });

  final String id;
  final String slug;
  final String nombre;

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as String,
        slug: json['slug'] as String,
        nombre: json['nombre'] as String,
      );
}
