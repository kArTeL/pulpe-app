/// Envoltura estándar de toda respuesta paginada de la API.
class Pagina<T> {
  const Pagina({
    required this.items,
    required this.total,
    required this.pagina,
    required this.porPagina,
    required this.haySiguiente,
  });

  final List<T> items;
  final int total;
  final int pagina;
  final int porPagina;
  final bool haySiguiente;

  factory Pagina.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapear,
  ) =>
      Pagina<T>(
        items: (json['items'] as List<dynamic>)
            .map((e) => mapear(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        pagina: json['pagina'] as int,
        porPagina: json['por_pagina'] as int,
        haySiguiente: json['hay_siguiente'] as bool,
      );
}
