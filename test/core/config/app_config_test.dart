import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/config/app_config.dart';
import 'package:pondstat/core/config/app_config_provider.dart';

void main() {
  test('appConfigProvider returns a valid AppConfig', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final config = container.read(appConfigProvider);

    // It should be a ProdConfig since that's what we configured it to return by default
    expect(config, isA<ProdConfig>());
    expect(config.appId, isNotEmpty);
  });

  test('AppConfig can be easily mocked', () {
    final mockConfig = DevConfig(appId: 'mock-test-id');

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(mockConfig),
      ],
    );
    addTearDown(container.dispose);

    final config = container.read(appConfigProvider);

    expect(config, isA<DevConfig>());
    expect(config.appId, 'mock-test-id');
  });
}
