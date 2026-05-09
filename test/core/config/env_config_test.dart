import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/core/config/env_config.dart';

void main() {
  test('EnvConfig.appId returns default value when not provided', () {
    expect(EnvConfig.appId, 'pondstat-app-v1');
  });
}
