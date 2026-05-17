/// An abstract interface defining the required configuration variables
/// for the PondStat application.
abstract interface class AppConfig {
  String get appId;
  Duration get defaultTimeoutDuration;
  List<String> get defaultLoadingMessages;
}

/// The concrete implementation of AppConfig for the Production environment.
class ProdConfig implements AppConfig {
  @override
  final String appId;

  @override
  final Duration defaultTimeoutDuration = const Duration(seconds: 15);

  @override
  final List<String> defaultLoadingMessages = const [
    'Preparing the pond...',
    'Waking up the fish...',
    'Fetching water quality data...',
    'Calibrating sensors...',
    'Almost ready...',
  ];

  const ProdConfig({required this.appId});
}

/// The concrete implementation of AppConfig for the Development environment.
class DevConfig implements AppConfig {
  @override
  final String appId;

  @override
  final Duration defaultTimeoutDuration = const Duration(seconds: 15);

  @override
  final List<String> defaultLoadingMessages = const [
    'Preparing the pond...',
    'Waking up the fish...',
    'Fetching water quality data...',
    'Calibrating sensors...',
    'Almost ready...',
  ];

  const DevConfig({required this.appId});
}
