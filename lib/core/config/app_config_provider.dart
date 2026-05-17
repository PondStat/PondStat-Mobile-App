import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/config/app_config.dart';
import 'package:pondstat/core/config/env.dart';

/// Provides the active [AppConfig] for the application.
/// This reads the obfuscated values from the generated Env class.
/// 
/// We can easily switch to a DevConfig or mock it during testing.
final appConfigProvider = Provider<AppConfig>((ref) {
  // In a more complex setup, you might check a flag here to return
  // a DevConfig vs a ProdConfig. For now, we return ProdConfig
  // with the secure Env variable.
  return ProdConfig(
    appId: Env.appId,
  );
});
