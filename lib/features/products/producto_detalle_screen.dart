import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formato.dart';
import '../../models/producto.dart';
import 'productos_repository.dart';

final productoDetalleProvider =
    FutureProvider.family<Producto, String>((ref, id) {
  return ref.watch(productosRepositoryProvider).detalle(id);
});

class ProductoDetalleScreen extends ConsumerWidget {
  const ProductoDetalleScreen({required this.productoId, super.key});

  final String productoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(productoDetalleProvider(productoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: detalle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No se pudo cargar el producto.'),
          ),
        ),
        data: (producto) => _Contenido(producto: producto),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(producto.nombre, style: tema.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(producto.sku, style: tema.textTheme.bodySmall),
        const SizedBox(height: 24),
        Text(
          Formato.precio(producto.precio),
          style: tema.textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        _Dato(etiqueta: 'Categoría', valor: producto.categoria.nombre),
        _Dato(
          etiqueta: 'Existencias',
          valor: producto.hayExistencias
              ? '${producto.existencias} unidades'
              : 'Sin existencias',
        ),
        const SizedBox(height: 24),
        Text('Descripción', style: tema.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(producto.descripcion, style: tema.textTheme.bodyMedium),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
            Text(valor, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
