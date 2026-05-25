// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'7d0f50c16beb0324be30ecd2d591e12151c30a8b';

@ProviderFor(pondMessages)
final pondMessagesProvider = PondMessagesFamily._();

final class PondMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PondChatMessage>>,
          List<PondChatMessage>,
          Stream<List<PondChatMessage>>
        >
    with
        $FutureModifier<List<PondChatMessage>>,
        $StreamProvider<List<PondChatMessage>> {
  PondMessagesProvider._({
    required PondMessagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pondMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pondMessagesHash();

  @override
  String toString() {
    return r'pondMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<PondChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PondChatMessage>> create(Ref ref) {
    final argument = this.argument as String;
    return pondMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PondMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pondMessagesHash() => r'a8c6e4739cefbb21c3058c4ecd33a64046a77343';

final class PondMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<PondChatMessage>>, String> {
  PondMessagesFamily._()
    : super(
        retry: null,
        name: r'pondMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PondMessagesProvider call(String pondId) =>
      PondMessagesProvider._(argument: pondId, from: this);

  @override
  String toString() => r'pondMessagesProvider';
}
