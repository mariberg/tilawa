/// Compile-time configuration injected via --dart-define-from-file=config.json.
/// Values are baked into the JS at build time and never appear as readable assets.
class AppConfig {
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String apiKey = String.fromEnvironment('API_KEY');
  static const String tokenHost = String.fromEnvironment('TOKEN_HOST');
  static const String clientId = String.fromEnvironment('CLIENT_ID');
  static const String clientSecret = String.fromEnvironment('CLIENT_SECRET');
  static const String scopes = String.fromEnvironment('SCOPES');
  static const String redirectUri = String.fromEnvironment(
    'REDIRECT_URI',
    defaultValue: 'http://localhost:5000/auth/callback',
  );
}
