import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/categoria.dart';
import '../../models/pagina.dart';
import '../../models/producto.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final cliente = ApiClient();
  ref.onDispose(cliente.dispose);
  return cliente;
});

final productosRepositoryProvider = Provider<ProductosRepository>(
  (ref) => ProductosRepository(ref.watch(apiClientProvider)),
);

/// Único lugar donde se arman los nombres de los query params.
/// Si agregás un parámetro, va en snake_case y hay que agregarlo también
/// a la tabla de AGENTS.md en los dos repos.
class ProductosRepository {
  const ProductosRepository(this._api);

  final ApiClient _api;

  Future<Pagina<Producto>> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async {
    final json = await _api.get(
      '/productos',
      query: {
        'pagina': pagina,
        'por_pagina': porPagina,
      },
    );

    return Pagina<Producto>.fromJson(json, Producto.fromJson);
  }

  Future<Producto> detalle(String id) async {
    final json = await _api.get('/productos/$id');
    return Producto.fromJson(json);
  }

  Future<List<Categoria>> categorias() async {
    final json = await _api.get('/categorias');
    return (json['items'] as List<dynamic>)
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Estado del listado. Mantiene la paginación acumulada para el scroll infinito.
class ProductosState {
  const ProductosState({
    this.productos = const [],
    this.pagina = 0,
    this.haySiguiente = true,
    this.cargandoMas = false,
  });

  final List<Producto> productos;
  final int pagina;
  final bool haySiguiente;
  final bool cargandoMas;

  ProductosState copyWith({
    List<Producto>? productos,
    int? pagina,
    bool? haySiguiente,
    bool? cargandoMas,
  }) =>
      ProductosState(
        productos: productos ?? this.productos,
        pagina: pagina ?? this.pagina,
        haySiguiente: haySiguiente ?? this.haySiguiente,
        cargandoMas: cargandoMas ?? this.cargandoMas,
      );
}

final productosProvider =
    AsyncNotifierProvider<ProductosNotifier, ProductosState>(
  ProductosNotifier.new,
);

class ProductosNotifier extends AsyncNotifier<ProductosState> {
  static const int _porPagina = 20;

  @override
  Future<ProductosState> build() => _cargarPrimeraPagina();

  Future<ProductosState> _cargarPrimeraPagina() async {
    final repo = ref.read(productosRepositoryProvider);
    final resultado = await repo.listar(pagina: 1, porPagina: _porPagina);

    return ProductosState(
      productos: resultado.items,
      pagina: resultado.pagina,
      haySiguiente: resultado.haySiguiente,
    );
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_cargarPrimeraPagina);
  }

  Future<void> cargarMas() async {
    final actual = state.valueOrNull;
    if (actual == null || !actual.haySiguiente || actual.cargandoMas) return;

    state = AsyncValue.data(actual.copyWith(cargandoMas: true));

    try {
      final repo = ref.read(productosRepositoryProvider);
      final resultado = await repo.listar(
        pagina: actual.pagina + 1,
        porPagina: _porPagina,
      );

      state = AsyncValue.data(
        actual.copyWith(
          productos: [...actual.productos, ...resultado.items],
          pagina: resultado.pagina,
          haySiguiente: resultado.haySiguiente,
          cargandoMas: false,
        ),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}
