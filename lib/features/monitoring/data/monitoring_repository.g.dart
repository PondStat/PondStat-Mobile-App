// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitoring_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(monitoringRepository)
final monitoringRepositoryProvider = MonitoringRepositoryProvider._();

final class MonitoringRepositoryProvider
    extends
        $FunctionalProvider<
          MonitoringRepository,
          MonitoringRepository,
          MonitoringRepository
        >
    with $Provider<MonitoringRepository> {
  MonitoringRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monitoringRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monitoringRepositoryHash();

  @$internal
  @override
  $ProviderElement<MonitoringRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MonitoringRepository create(Ref ref) {
    return monitoringRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MonitoringRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MonitoringRepository>(value),
    );
  }
}

String _$monitoringRepositoryHash() =>
    r'083c6ce9321373be73f86de7152bba058d69dfc3';
