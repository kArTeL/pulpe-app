import 'categoria.dart';

class Producto {
  const Producto({
    required this.id,
    required this.sku,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.existencias,
    required this.activo,
    required this.categoria,
    required this.creadoEn,
    this.imagenUrl,
  });

  final String id;
  final String sku;
  final String nombre;
  final String descripcion;

  /// Céntimos de colón. Formatear siempre con Formato.precio().
  final int precio;
  final int existencias;
  final bool activo;
  final Categoria categoria;
  final DateTime creadoEn;
  final String? imagenUrl;

  bool get hayExistencias => existencias > 0;

  /// OJO: las llaves de la izquierda son snake_case porque así las manda la API.
  /// No las "corrijas" a camelCase: el backend no las va a reconocer.
  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'] as String,
        sku: json['sku'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String,
        precio: json['precio'] as int,
        existencias: json['existencias'] as int,
        activo: json['activo'] as bool,
        imagenUrl: json['imagen_url'] as String?,
        categoria: Categoria.fromJson(json['categoria'] as Map<String, dynamic>),
        creadoEn: DateTime.parse(json['creado_en'] as String),
      );
}
