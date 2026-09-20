/// Configuración de entorno de la app.
///
/// La URL base se pasa con --dart-define para no hornear el host en el binario:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
class Config {
  const Config._();

  /// En el emulador de Android, localhost del host es 10.0.2.2.
  /// En el simulador de iOS y en web, localhost funciona directo.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration timeout = Duration(seconds: 10);
}
