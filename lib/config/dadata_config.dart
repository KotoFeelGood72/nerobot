/// Ключи DaData Suggestions API.
/// Передаются через `--dart-define-from-file=dart_defines.json`.
class DadataConfig {
  static const String apiKey = String.fromEnvironment(
    'DADATA_API_KEY',
    defaultValue: '',
  );

  static const String secretKey = String.fromEnvironment(
    'DADATA_SECRET_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => apiKey.isNotEmpty;
}
