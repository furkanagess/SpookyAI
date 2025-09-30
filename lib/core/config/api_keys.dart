class ApiKeys {
  ApiKeys._();

  // Production version - use environment variable
  static const String stability = String.fromEnvironment(
    'STABILITY_API_KEY',
    defaultValue: '',
  );
}
