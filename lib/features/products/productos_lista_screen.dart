import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/formato.dart';
import '../../models/producto.dart';
import 'producto_detalle_screen.dart';
import 'productos_repository.dart';

class ProductosListaScreen extends ConsumerStatefulWidget {
  const ProductosListaScreen({super.key});

  @override
  ConsumerState<ProductosListaScreen> createState() =>
      _ProductosListaScreenState();
}

class _ProductosListaScreenState extends ConsumerState<ProductosListaScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alHacerScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_alHacerScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _alHacerScroll() {
    final cercaDelFinal =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 400;
    if (cercaDelFinal) {
      ref.read(productosProvider.notifier).cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(productosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EstadoError(
          error: error,
          alReintentar: () => ref.read(productosProvider.notifier).recargar(),
        ),
        data: (datos) {
          if (datos.productos.isEmpty) {
            return const _EstadoVacio();
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(productosProvider.notifier).recargar(),
            child: ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: datos.productos.length + (datos.cargandoMas ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, indice) {
                if (indice >= datos.productos.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return _FilaProducto(producto: datos.productos[indice]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(producto.nombre, style: tema.textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(producto.categoria.nombre, style: tema.textTheme.bodySmall),
            const SizedBox(width: 8),
            if (!producto.hayExistencias)
              Text(
                'Sin existencias',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
      trailing: Text(
        Formato.precio(producto.precio),
        style: tema.textTheme.titleMedium,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductoDetalleScreen(productoId: producto.id),
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Todavía no hay productos en el catálogo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _EstadoError extends StatelessWidget {
  const _EstadoError({required this.error, required this.alReintentar});

  final Object error;
  final VoidCallback alReintentar;

  String get _mensaje {
    if (error is RedException) {
      return 'No se pudo conectar con el servidor.\n'
          'Revisá que pulpe-api esté corriendo.';
    }
    if (error is ApiException) {
      return (error as ApiException).mensaje;
    }
    return 'Ocurrió un error inesperado.';
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_mensaje, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}
