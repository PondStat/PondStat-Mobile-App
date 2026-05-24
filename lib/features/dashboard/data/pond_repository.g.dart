// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pond_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pondRepository)
final pondRepositoryProvider = PondRepositoryProvider._();

final class PondRepositoryProvider
    extends $FunctionalProvider<PondRepository, PondRepository, PondRepository>
    with $Provider<PondRepository> {
  PondRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pondRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pondRepositoryHash();

  @$internal
  @override
  $ProviderElement<PondRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PondRepository create(Ref ref) {
    return pondRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PondRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PondRepository>(value),
    );
  }
}

String _$pondRepositoryHash() => r'1ff2fba09859fd4f311191e0a4d9fc17341d2fb5';
