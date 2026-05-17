// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loading_overlay_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoadingOverlayNotifier)
final loadingOverlayProvider = LoadingOverlayNotifierFamily._();

final class LoadingOverlayNotifierProvider
    extends $NotifierProvider<LoadingOverlayNotifier, LoadingOverlayState> {
  LoadingOverlayNotifierProvider._({
    required LoadingOverlayNotifierFamily super.from,
    required LoadingOverlayArgs super.argument,
  }) : super(
         retry: null,
         name: r'loadingOverlayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loadingOverlayNotifierHash();

  @override
  String toString() {
    return r'loadingOverlayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LoadingOverlayNotifier create() => LoadingOverlayNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadingOverlayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadingOverlayState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LoadingOverlayNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loadingOverlayNotifierHash() =>
    r'28e035fd5e2b028709518545c4e0be39b326d2b6';

final class LoadingOverlayNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          LoadingOverlayNotifier,
          LoadingOverlayState,
          LoadingOverlayState,
          LoadingOverlayState,
          LoadingOverlayArgs
        > {
  LoadingOverlayNotifierFamily._()
    : super(
        retry: null,
        name: r'loadingOverlayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LoadingOverlayNotifierProvider call(LoadingOverlayArgs arg) =>
      LoadingOverlayNotifierProvider._(argument: arg, from: this);

  @override
  String toString() => r'loadingOverlayProvider';
}

abstract class _$LoadingOverlayNotifier extends $Notifier<LoadingOverlayState> {
  late final _$args = ref.$arg as LoadingOverlayArgs;
  LoadingOverlayArgs get arg => _$args;

  LoadingOverlayState build(LoadingOverlayArgs arg);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LoadingOverlayState, LoadingOverlayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoadingOverlayState, LoadingOverlayState>,
              LoadingOverlayState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
