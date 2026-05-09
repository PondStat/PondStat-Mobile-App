class EnvConfig {
  static const String appId = String.fromEnvironment(
    'APP_ID',
    defaultValue: 'pondstat-app-v1',
  );
}
