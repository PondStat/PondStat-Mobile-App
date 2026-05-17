/// An abstract interface defining the required configuration variables
/// for the PondStat application.
abstract interface class AppConfig {
  String get appId;
  // Add other environment-specific configurations here (e.g., apiBaseUrl)
}

/// The concrete implementation of AppConfig for the Production environment.
class ProdConfig implements AppConfig {
  @override
  final String appId;

  const ProdConfig({required this.appId});
}

/// The concrete implementation of AppConfig for the Development environment.
class DevConfig implements AppConfig {
  @override
  final String appId;

  const DevConfig({required this.appId});
}
