// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUser {

 String get id; String get fullName; String get email; String get role; String? get assignedPond; String? get fcmToken;@TimestampConverter() DateTime? get createdAt;@TimestampConverter() DateTime? get lastTokenUpdate;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.assignedPond, assignedPond) || other.assignedPond == assignedPond)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastTokenUpdate, lastTokenUpdate) || other.lastTokenUpdate == lastTokenUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,role,assignedPond,fcmToken,createdAt,lastTokenUpdate);

@override
String toString() {
  return 'AppUser(id: $id, fullName: $fullName, email: $email, role: $role, assignedPond: $assignedPond, fcmToken: $fcmToken, createdAt: $createdAt, lastTokenUpdate: $lastTokenUpdate)';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String email, String role, String? assignedPond, String? fcmToken,@TimestampConverter() DateTime? createdAt,@TimestampConverter() DateTime? lastTokenUpdate
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? role = null,Object? assignedPond = freezed,Object? fcmToken = freezed,Object? createdAt = freezed,Object? lastTokenUpdate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,assignedPond: freezed == assignedPond ? _self.assignedPond : assignedPond // ignore: cast_nullable_to_non_nullable
as String?,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastTokenUpdate: freezed == lastTokenUpdate ? _self.lastTokenUpdate : lastTokenUpdate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String email,  String role,  String? assignedPond,  String? fcmToken, @TimestampConverter()  DateTime? createdAt, @TimestampConverter()  DateTime? lastTokenUpdate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.role,_that.assignedPond,_that.fcmToken,_that.createdAt,_that.lastTokenUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String email,  String role,  String? assignedPond,  String? fcmToken, @TimestampConverter()  DateTime? createdAt, @TimestampConverter()  DateTime? lastTokenUpdate)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.id,_that.fullName,_that.email,_that.role,_that.assignedPond,_that.fcmToken,_that.createdAt,_that.lastTokenUpdate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String email,  String role,  String? assignedPond,  String? fcmToken, @TimestampConverter()  DateTime? createdAt, @TimestampConverter()  DateTime? lastTokenUpdate)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.role,_that.assignedPond,_that.fcmToken,_that.createdAt,_that.lastTokenUpdate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppUser implements AppUser {
  const _AppUser({this.id = '', this.fullName = 'New User', this.email = '', this.role = 'member', this.assignedPond, this.fcmToken, @TimestampConverter() this.createdAt, @TimestampConverter() this.lastTokenUpdate});
  factory _AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String fullName;
@override@JsonKey() final  String email;
@override@JsonKey() final  String role;
@override final  String? assignedPond;
@override final  String? fcmToken;
@override@TimestampConverter() final  DateTime? createdAt;
@override@TimestampConverter() final  DateTime? lastTokenUpdate;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.assignedPond, assignedPond) || other.assignedPond == assignedPond)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastTokenUpdate, lastTokenUpdate) || other.lastTokenUpdate == lastTokenUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,role,assignedPond,fcmToken,createdAt,lastTokenUpdate);

@override
String toString() {
  return 'AppUser(id: $id, fullName: $fullName, email: $email, role: $role, assignedPond: $assignedPond, fcmToken: $fcmToken, createdAt: $createdAt, lastTokenUpdate: $lastTokenUpdate)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String email, String role, String? assignedPond, String? fcmToken,@TimestampConverter() DateTime? createdAt,@TimestampConverter() DateTime? lastTokenUpdate
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? role = null,Object? assignedPond = freezed,Object? fcmToken = freezed,Object? createdAt = freezed,Object? lastTokenUpdate = freezed,}) {
  return _then(_AppUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,assignedPond: freezed == assignedPond ? _self.assignedPond : assignedPond // ignore: cast_nullable_to_non_nullable
as String?,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastTokenUpdate: freezed == lastTokenUpdate ? _self.lastTokenUpdate : lastTokenUpdate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
