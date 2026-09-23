/// App environment configuration.
///
/// The base URL is passed with --dart-define so the host isn't baked into the binary:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
class Config {
  const Config._();

  /// On the Android emulator, the host's localhost is 10.0.2.2.
  /// On the iOS simulator and on web, localhost works directly.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration timeout = Duration(seconds: 10);
}
