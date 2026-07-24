/// Build-time application configuration.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'BUDGIE_API_BASE_URL',
    defaultValue: 'https://budgiefastapi.onrender.com',
  );

  static const apiVersion = 'v1';

  static const enableVerboseLogging = bool.fromEnvironment(
    'BUDGIE_VERBOSE_LOGGING',
    defaultValue: false,
  );
}
