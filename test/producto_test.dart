import 'package:flutter_test/flutter_test.dart';
import 'package:pulpe_app/models/producto.dart';

void main() {
  group('Producto.fromJson', () {
    final json = <String, dynamic>{
      'id': 'abc123',
      'sku': 'PLP-0001',
      'nombre': 'Arroz Tío Pelón 1.8 kg',
      'descripcion': 'Arroz marca Tío Pelón, presentación de 1.8 kg.',
      'precio': 215000,
      'existencias': 42,
      'activo': true,
      'imagen_url': null,
      'categoria': {'id': 'cat1', 'slug': 'abarrotes', 'nombre': 'Abarrotes'},
      'creado_en': '2026-03-14T10:00:00.000Z',
    };

    test('mapea los campos snake_case de la API', () {
      final producto = Producto.fromJson(json);

      expect(producto.sku, 'PLP-0001');
      expect(producto.precio, 215000);
      expect(producto.imagenUrl, isNull);
      expect(producto.categoria.slug, 'abarrotes');
      expect(producto.creadoEn.year, 2026);
    });

    test('hayExistencias refleja el inventario', () {
      expect(Producto.fromJson(json).hayExistencias, isTrue);

      final agotado = Producto.fromJson({...json, 'existencias': 0});
      expect(agotado.hayExistencias, isFalse);
    });
  });
}
