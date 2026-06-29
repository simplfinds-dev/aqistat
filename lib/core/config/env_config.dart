/// Secure environment configuration.
///
/// API keys are NEVER hardcoded. They are injected at build time via
/// --dart-define so they don't sit in source control or the compiled
/// asset bundle in plain text.
///
/// Run the app like this:
///   flutter run --dart-define=OWM_KEY=your_key --dart-define=WAQI_KEY=your_key
///
/// Or use a dart-define file:
///   flutter run --dart-define-from-file=env.json
class EnvConfig {
  EnvConfig._();

  static const String openWeatherKey =
      String.fromEnvironment('OWM_KEY', defaultValue: '');

  static const String waqiKey =
      String.fromEnvironment('WAQI_KEY', defaultValue: '');

  /// Whether the app has valid API keys configured.
  static bool get hasKeys =>
      openWeatherKey.isNotEmpty && waqiKey.isNotEmpty;

  /// Whether we are running in release mode.
  static const bool isProduction =
      bool.fromEnvironment('dart.vm.product');
}
