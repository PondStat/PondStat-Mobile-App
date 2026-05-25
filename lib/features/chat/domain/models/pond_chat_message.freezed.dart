// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pond_chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PondChatMessage {

 String get id; String get pondId; String get senderId; String get senderName; String? get senderPhotoUrl; String get message; String? get imageUrl; String? get taggedParameter;@TimestampConverter() DateTime? get createdAt;
/// Create a copy of PondChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PondChatMessageCopyWith<PondChatMessage> get copyWith => _$PondChatMessageCopyWithImpl<PondChatMessage>(this as PondChatMessage, _$identity);

  /// Serializes this PondChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PondChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderPhotoUrl, senderPhotoUrl) || other.senderPhotoUrl == senderPhotoUrl)&&(identical(other.message, message) || other.message == message)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.taggedParameter, taggedParameter) || other.taggedParameter == taggedParameter)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pondId,senderId,senderName,senderPhotoUrl,message,imageUrl,taggedParameter,createdAt);

@override
String toString() {
  return 'PondChatMessage(id: $id, pondId: $pondId, senderId: $senderId, senderName: $senderName, senderPhotoUrl: $senderPhotoUrl, message: $message, imageUrl: $imageUrl, taggedParameter: $taggedParameter, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PondChatMessageCopyWith<$Res>  {
  factory $PondChatMessageCopyWith(PondChatMessage value, $Res Function(PondChatMessage) _then) = _$PondChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String pondId, String senderId, String senderName, String? senderPhotoUrl, String message, String? imageUrl, String? taggedParameter,@TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$PondChatMessageCopyWithImpl<$Res>
    implements $PondChatMessageCopyWith<$Res> {
  _$PondChatMessageCopyWithImpl(this._self, this._then);

  final PondChatMessage _self;
  final $Res Function(PondChatMessage) _then;

/// Create a copy of PondChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pondId = null,Object? senderId = null,Object? senderName = null,Object? senderPhotoUrl = freezed,Object? message = null,Object? imageUrl = freezed,Object? taggedParameter = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderPhotoUrl: freezed == senderPhotoUrl ? _self.senderPhotoUrl : senderPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,taggedParameter: freezed == taggedParameter ? _self.taggedParameter : taggedParameter // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PondChatMessage].
extension PondChatMessagePatterns on PondChatMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PondChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PondChatMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PondChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _PondChatMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PondChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _PondChatMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pondId,  String senderId,  String senderName,  String? senderPhotoUrl,  String message,  String? imageUrl,  String? taggedParameter, @TimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PondChatMessage() when $default != null:
return $default(_that.id,_that.pondId,_that.senderId,_that.senderName,_that.senderPhotoUrl,_that.message,_that.imageUrl,_that.taggedParameter,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pondId,  String senderId,  String senderName,  String? senderPhotoUrl,  String message,  String? imageUrl,  String? taggedParameter, @TimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PondChatMessage():
return $default(_that.id,_that.pondId,_that.senderId,_that.senderName,_that.senderPhotoUrl,_that.message,_that.imageUrl,_that.taggedParameter,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pondId,  String senderId,  String senderName,  String? senderPhotoUrl,  String message,  String? imageUrl,  String? taggedParameter, @TimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PondChatMessage() when $default != null:
return $default(_that.id,_that.pondId,_that.senderId,_that.senderName,_that.senderPhotoUrl,_that.message,_that.imageUrl,_that.taggedParameter,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PondChatMessage implements PondChatMessage {
  const _PondChatMessage({required this.id, required this.pondId, required this.senderId, required this.senderName, this.senderPhotoUrl, required this.message, this.imageUrl, this.taggedParameter, @TimestampConverter() this.createdAt});
  factory _PondChatMessage.fromJson(Map<String, dynamic> json) => _$PondChatMessageFromJson(json);

@override final  String id;
@override final  String pondId;
@override final  String senderId;
@override final  String senderName;
@override final  String? senderPhotoUrl;
@override final  String message;
@override final  String? imageUrl;
@override final  String? taggedParameter;
@override@TimestampConverter() final  DateTime? createdAt;

/// Create a copy of PondChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PondChatMessageCopyWith<_PondChatMessage> get copyWith => __$PondChatMessageCopyWithImpl<_PondChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PondChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PondChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderPhotoUrl, senderPhotoUrl) || other.senderPhotoUrl == senderPhotoUrl)&&(identical(other.message, message) || other.message == message)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.taggedParameter, taggedParameter) || other.taggedParameter == taggedParameter)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pondId,senderId,senderName,senderPhotoUrl,message,imageUrl,taggedParameter,createdAt);

@override
String toString() {
  return 'PondChatMessage(id: $id, pondId: $pondId, senderId: $senderId, senderName: $senderName, senderPhotoUrl: $senderPhotoUrl, message: $message, imageUrl: $imageUrl, taggedParameter: $taggedParameter, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PondChatMessageCopyWith<$Res> implements $PondChatMessageCopyWith<$Res> {
  factory _$PondChatMessageCopyWith(_PondChatMessage value, $Res Function(_PondChatMessage) _then) = __$PondChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String pondId, String senderId, String senderName, String? senderPhotoUrl, String message, String? imageUrl, String? taggedParameter,@TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$PondChatMessageCopyWithImpl<$Res>
    implements _$PondChatMessageCopyWith<$Res> {
  __$PondChatMessageCopyWithImpl(this._self, this._then);

  final _PondChatMessage _self;
  final $Res Function(_PondChatMessage) _then;

/// Create a copy of PondChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pondId = null,Object? senderId = null,Object? senderName = null,Object? senderPhotoUrl = freezed,Object? message = null,Object? imageUrl = freezed,Object? taggedParameter = freezed,Object? createdAt = freezed,}) {
  return _then(_PondChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderPhotoUrl: freezed == senderPhotoUrl ? _self.senderPhotoUrl : senderPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,taggedParameter: freezed == taggedParameter ? _self.taggedParameter : taggedParameter // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
