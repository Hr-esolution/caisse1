class AppConstant {
  // Base URL for API calls - use host IP for mobile simulators
  static String get baseUrl {
    const defaultUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://soyabox.ma',
    );

    // Override at runtime if needed:
    // flutter run --dart-define=API_BASE_URL=https://your-backend.example
    return defaultUrl;
  }

  static String get apiToken {
    return const String.fromEnvironment('API_TOKEN', defaultValue: '');
  }
}
