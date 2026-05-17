// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_parameter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomParameter {

 String get id; String get label; String get unit; String get type; String get category;@TimestampConverter() DateTime? get createdAt; String get createdBy;
/// Create a copy of CustomParameter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomParameterCopyWith<CustomParameter> get copyWith => _$CustomParameterCopyWithImpl<CustomParameter>(this as CustomParameter, _$identity);

  /// Serializes this CustomParameter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomParameter&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,unit,type,category,createdAt,createdBy);

@override
String toString() {
  return 'CustomParameter(id: $id, label: $label, unit: $unit, type: $type, category: $category, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $CustomParameterCopyWith<$Res>  {
  factory $CustomParameterCopyWith(CustomParameter value, $Res Function(CustomParameter) _then) = _$CustomParameterCopyWithImpl;
@useResult
$Res call({
 String id, String label, String unit, String type, String category,@TimestampConverter() DateTime? createdAt, String createdBy
});




}
/// @nodoc
class _$CustomParameterCopyWithImpl<$Res>
    implements $CustomParameterCopyWith<$Res> {
  _$CustomParameterCopyWithImpl(this._self, this._then);

  final CustomParameter _self;
  final $Res Function(CustomParameter) _then;

/// Create a copy of CustomParameter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? unit = null,Object? type = null,Object? category = null,Object? createdAt = freezed,Object? createdBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomParameter].
extension CustomParameterPatterns on CustomParameter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomParameter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomParameter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomParameter value)  $default,){
final _that = this;
switch (_that) {
case _CustomParameter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomParameter value)?  $default,){
final _that = this;
switch (_that) {
case _CustomParameter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String unit,  String type,  String category, @TimestampConverter()  DateTime? createdAt,  String createdBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomParameter() when $default != null:
return $default(_that.id,_that.label,_that.unit,_that.type,_that.category,_that.createdAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String unit,  String type,  String category, @TimestampConverter()  DateTime? createdAt,  String createdBy)  $default,) {final _that = this;
switch (_that) {
case _CustomParameter():
return $default(_that.id,_that.label,_that.unit,_that.type,_that.category,_that.createdAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String unit,  String type,  String category, @TimestampConverter()  DateTime? createdAt,  String createdBy)?  $default,) {final _that = this;
switch (_that) {
case _CustomParameter() when $default != null:
return $default(_that.id,_that.label,_that.unit,_that.type,_that.category,_that.createdAt,_that.createdBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomParameter implements CustomParameter {
  const _CustomParameter({this.id = '', required this.label, required this.unit, required this.type, required this.category, @TimestampConverter() this.createdAt, this.createdBy = ''});
  factory _CustomParameter.fromJson(Map<String, dynamic> json) => _$CustomParameterFromJson(json);

@override@JsonKey() final  String id;
@override final  String label;
@override final  String unit;
@override final  String type;
@override final  String category;
@override@TimestampConverter() final  DateTime? createdAt;
@override@JsonKey() final  String createdBy;

/// Create a copy of CustomParameter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomParameterCopyWith<_CustomParameter> get copyWith => __$CustomParameterCopyWithImpl<_CustomParameter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomParameterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomParameter&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,unit,type,category,createdAt,createdBy);

@override
String toString() {
  return 'CustomParameter(id: $id, label: $label, unit: $unit, type: $type, category: $category, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$CustomParameterCopyWith<$Res> implements $CustomParameterCopyWith<$Res> {
  factory _$CustomParameterCopyWith(_CustomParameter value, $Res Function(_CustomParameter) _then) = __$CustomParameterCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String unit, String type, String category,@TimestampConverter() DateTime? createdAt, String createdBy
});




}
/// @nodoc
class __$CustomParameterCopyWithImpl<$Res>
    implements _$CustomParameterCopyWith<$Res> {
  __$CustomParameterCopyWithImpl(this._self, this._then);

  final _CustomParameter _self;
  final $Res Function(_CustomParameter) _then;

/// Create a copy of CustomParameter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? unit = null,Object? type = null,Object? category = null,Object? createdAt = freezed,Object? createdBy = null,}) {
  return _then(_CustomParameter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
