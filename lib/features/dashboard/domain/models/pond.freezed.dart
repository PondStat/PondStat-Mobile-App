// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pond.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Pond {

 String get id; String get name; String get species; int get stockingQuantity; int get targetCulturePeriodDays; String get ownerId; List<String> get memberIds; Map<String, String> get roles;@TimestampConverter() DateTime? get createdAt;
/// Create a copy of Pond
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PondCopyWith<Pond> get copyWith => _$PondCopyWithImpl<Pond>(this as Pond, _$identity);

  /// Serializes this Pond to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pond&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.stockingQuantity, stockingQuantity) || other.stockingQuantity == stockingQuantity)&&(identical(other.targetCulturePeriodDays, targetCulturePeriodDays) || other.targetCulturePeriodDays == targetCulturePeriodDays)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&const DeepCollectionEquality().equals(other.memberIds, memberIds)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,species,stockingQuantity,targetCulturePeriodDays,ownerId,const DeepCollectionEquality().hash(memberIds),const DeepCollectionEquality().hash(roles),createdAt);

@override
String toString() {
  return 'Pond(id: $id, name: $name, species: $species, stockingQuantity: $stockingQuantity, targetCulturePeriodDays: $targetCulturePeriodDays, ownerId: $ownerId, memberIds: $memberIds, roles: $roles, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PondCopyWith<$Res>  {
  factory $PondCopyWith(Pond value, $Res Function(Pond) _then) = _$PondCopyWithImpl;
@useResult
$Res call({
 String id, String name, String species, int stockingQuantity, int targetCulturePeriodDays, String ownerId, List<String> memberIds, Map<String, String> roles,@TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$PondCopyWithImpl<$Res>
    implements $PondCopyWith<$Res> {
  _$PondCopyWithImpl(this._self, this._then);

  final Pond _self;
  final $Res Function(Pond) _then;

/// Create a copy of Pond
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? species = null,Object? stockingQuantity = null,Object? targetCulturePeriodDays = null,Object? ownerId = null,Object? memberIds = null,Object? roles = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as String,stockingQuantity: null == stockingQuantity ? _self.stockingQuantity : stockingQuantity // ignore: cast_nullable_to_non_nullable
as int,targetCulturePeriodDays: null == targetCulturePeriodDays ? _self.targetCulturePeriodDays : targetCulturePeriodDays // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self.memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Map<String, String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Pond].
extension PondPatterns on Pond {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pond value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pond() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pond value)  $default,){
final _that = this;
switch (_that) {
case _Pond():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pond value)?  $default,){
final _that = this;
switch (_that) {
case _Pond() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String species,  int stockingQuantity,  int targetCulturePeriodDays,  String ownerId,  List<String> memberIds,  Map<String, String> roles, @TimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pond() when $default != null:
return $default(_that.id,_that.name,_that.species,_that.stockingQuantity,_that.targetCulturePeriodDays,_that.ownerId,_that.memberIds,_that.roles,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String species,  int stockingQuantity,  int targetCulturePeriodDays,  String ownerId,  List<String> memberIds,  Map<String, String> roles, @TimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Pond():
return $default(_that.id,_that.name,_that.species,_that.stockingQuantity,_that.targetCulturePeriodDays,_that.ownerId,_that.memberIds,_that.roles,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String species,  int stockingQuantity,  int targetCulturePeriodDays,  String ownerId,  List<String> memberIds,  Map<String, String> roles, @TimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Pond() when $default != null:
return $default(_that.id,_that.name,_that.species,_that.stockingQuantity,_that.targetCulturePeriodDays,_that.ownerId,_that.memberIds,_that.roles,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pond extends Pond {
  const _Pond({required this.id, this.name = '', this.species = '', this.stockingQuantity = 0, this.targetCulturePeriodDays = 0, this.ownerId = '', final  List<String> memberIds = const [], final  Map<String, String> roles = const {}, @TimestampConverter() this.createdAt}): _memberIds = memberIds,_roles = roles,super._();
  factory _Pond.fromJson(Map<String, dynamic> json) => _$PondFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String species;
@override@JsonKey() final  int stockingQuantity;
@override@JsonKey() final  int targetCulturePeriodDays;
@override@JsonKey() final  String ownerId;
 final  List<String> _memberIds;
@override@JsonKey() List<String> get memberIds {
  if (_memberIds is EqualUnmodifiableListView) return _memberIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberIds);
}

 final  Map<String, String> _roles;
@override@JsonKey() Map<String, String> get roles {
  if (_roles is EqualUnmodifiableMapView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_roles);
}

@override@TimestampConverter() final  DateTime? createdAt;

/// Create a copy of Pond
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PondCopyWith<_Pond> get copyWith => __$PondCopyWithImpl<_Pond>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PondToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pond&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.stockingQuantity, stockingQuantity) || other.stockingQuantity == stockingQuantity)&&(identical(other.targetCulturePeriodDays, targetCulturePeriodDays) || other.targetCulturePeriodDays == targetCulturePeriodDays)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&const DeepCollectionEquality().equals(other._memberIds, _memberIds)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,species,stockingQuantity,targetCulturePeriodDays,ownerId,const DeepCollectionEquality().hash(_memberIds),const DeepCollectionEquality().hash(_roles),createdAt);

@override
String toString() {
  return 'Pond(id: $id, name: $name, species: $species, stockingQuantity: $stockingQuantity, targetCulturePeriodDays: $targetCulturePeriodDays, ownerId: $ownerId, memberIds: $memberIds, roles: $roles, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PondCopyWith<$Res> implements $PondCopyWith<$Res> {
  factory _$PondCopyWith(_Pond value, $Res Function(_Pond) _then) = __$PondCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String species, int stockingQuantity, int targetCulturePeriodDays, String ownerId, List<String> memberIds, Map<String, String> roles,@TimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$PondCopyWithImpl<$Res>
    implements _$PondCopyWith<$Res> {
  __$PondCopyWithImpl(this._self, this._then);

  final _Pond _self;
  final $Res Function(_Pond) _then;

/// Create a copy of Pond
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? species = null,Object? stockingQuantity = null,Object? targetCulturePeriodDays = null,Object? ownerId = null,Object? memberIds = null,Object? roles = null,Object? createdAt = freezed,}) {
  return _then(_Pond(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as String,stockingQuantity: null == stockingQuantity ? _self.stockingQuantity : stockingQuantity // ignore: cast_nullable_to_non_nullable
as int,targetCulturePeriodDays: null == targetCulturePeriodDays ? _self.targetCulturePeriodDays : targetCulturePeriodDays // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self._memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Map<String, String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
