// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finances_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(financesRepository)
final financesRepositoryProvider = FinancesRepositoryProvider._();

final class FinancesRepositoryProvider
    extends
        $FunctionalProvider<
          FinancesRepository,
          FinancesRepository,
          FinancesRepository
        >
    with $Provider<FinancesRepository> {
  FinancesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'financesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$financesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FinancesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FinancesRepository create(Ref ref) {
    return financesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FinancesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FinancesRepository>(value),
    );
  }
}

String _$financesRepositoryHash() =>
    r'5c06cc7dd38e964048d9cb084976cb1711fa312b';
