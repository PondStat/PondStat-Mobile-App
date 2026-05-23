// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pond_sale.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PondSale {

 String get id; String get pondId; String get buyerName; String get productName; double get quantity; String get unit; double get pricePerUnit; double get totalAmount; String get recordedById; String get recordedByName;@TimestampConverter() DateTime? get timestamp; String get notes;
/// Create a copy of PondSale
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PondSaleCopyWith<PondSale> get copyWith => _$PondSaleCopyWithImpl<PondSale>(this as PondSale, _$identity);

  /// Serializes this PondSale to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PondSale&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.buyerName, buyerName) || other.buyerName == buyerName)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.pricePerUnit, pricePerUnit) || other.pricePerUnit == pricePerUnit)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.recordedById, recordedById) || other.recordedById == recordedById)&&(identical(other.recordedByName, recordedByName) || other.recordedByName == recordedByName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pondId,buyerName,productName,quantity,unit,pricePerUnit,totalAmount,recordedById,recordedByName,timestamp,notes);

@override
String toString() {
  return 'PondSale(id: $id, pondId: $pondId, buyerName: $buyerName, productName: $productName, quantity: $quantity, unit: $unit, pricePerUnit: $pricePerUnit, totalAmount: $totalAmount, recordedById: $recordedById, recordedByName: $recordedByName, timestamp: $timestamp, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $PondSaleCopyWith<$Res>  {
  factory $PondSaleCopyWith(PondSale value, $Res Function(PondSale) _then) = _$PondSaleCopyWithImpl;
@useResult
$Res call({
 String id, String pondId, String buyerName, String productName, double quantity, String unit, double pricePerUnit, double totalAmount, String recordedById, String recordedByName,@TimestampConverter() DateTime? timestamp, String notes
});




}
/// @nodoc
class _$PondSaleCopyWithImpl<$Res>
    implements $PondSaleCopyWith<$Res> {
  _$PondSaleCopyWithImpl(this._self, this._then);

  final PondSale _self;
  final $Res Function(PondSale) _then;

/// Create a copy of PondSale
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pondId = null,Object? buyerName = null,Object? productName = null,Object? quantity = null,Object? unit = null,Object? pricePerUnit = null,Object? totalAmount = null,Object? recordedById = null,Object? recordedByName = null,Object? timestamp = freezed,Object? notes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,buyerName: null == buyerName ? _self.buyerName : buyerName // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,pricePerUnit: null == pricePerUnit ? _self.pricePerUnit : pricePerUnit // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,recordedById: null == recordedById ? _self.recordedById : recordedById // ignore: cast_nullable_to_non_nullable
as String,recordedByName: null == recordedByName ? _self.recordedByName : recordedByName // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PondSale].
extension PondSalePatterns on PondSale {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PondSale value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PondSale() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PondSale value)  $default,){
final _that = this;
switch (_that) {
case _PondSale():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PondSale value)?  $default,){
final _that = this;
switch (_that) {
case _PondSale() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pondId,  String buyerName,  String productName,  double quantity,  String unit,  double pricePerUnit,  double totalAmount,  String recordedById,  String recordedByName, @TimestampConverter()  DateTime? timestamp,  String notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PondSale() when $default != null:
return $default(_that.id,_that.pondId,_that.buyerName,_that.productName,_that.quantity,_that.unit,_that.pricePerUnit,_that.totalAmount,_that.recordedById,_that.recordedByName,_that.timestamp,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pondId,  String buyerName,  String productName,  double quantity,  String unit,  double pricePerUnit,  double totalAmount,  String recordedById,  String recordedByName, @TimestampConverter()  DateTime? timestamp,  String notes)  $default,) {final _that = this;
switch (_that) {
case _PondSale():
return $default(_that.id,_that.pondId,_that.buyerName,_that.productName,_that.quantity,_that.unit,_that.pricePerUnit,_that.totalAmount,_that.recordedById,_that.recordedByName,_that.timestamp,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pondId,  String buyerName,  String productName,  double quantity,  String unit,  double pricePerUnit,  double totalAmount,  String recordedById,  String recordedByName, @TimestampConverter()  DateTime? timestamp,  String notes)?  $default,) {final _that = this;
switch (_that) {
case _PondSale() when $default != null:
return $default(_that.id,_that.pondId,_that.buyerName,_that.productName,_that.quantity,_that.unit,_that.pricePerUnit,_that.totalAmount,_that.recordedById,_that.recordedByName,_that.timestamp,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PondSale implements PondSale {
  const _PondSale({this.id = '', required this.pondId, required this.buyerName, required this.productName, this.quantity = 0.0, this.unit = 'kg', this.pricePerUnit = 0.0, this.totalAmount = 0.0, this.recordedById = '', this.recordedByName = 'Unknown', @TimestampConverter() this.timestamp, this.notes = ''});
  factory _PondSale.fromJson(Map<String, dynamic> json) => _$PondSaleFromJson(json);

@override@JsonKey() final  String id;
@override final  String pondId;
@override final  String buyerName;
@override final  String productName;
@override@JsonKey() final  double quantity;
@override@JsonKey() final  String unit;
@override@JsonKey() final  double pricePerUnit;
@override@JsonKey() final  double totalAmount;
@override@JsonKey() final  String recordedById;
@override@JsonKey() final  String recordedByName;
@override@TimestampConverter() final  DateTime? timestamp;
@override@JsonKey() final  String notes;

/// Create a copy of PondSale
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PondSaleCopyWith<_PondSale> get copyWith => __$PondSaleCopyWithImpl<_PondSale>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PondSaleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PondSale&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.buyerName, buyerName) || other.buyerName == buyerName)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.pricePerUnit, pricePerUnit) || other.pricePerUnit == pricePerUnit)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.recordedById, recordedById) || other.recordedById == recordedById)&&(identical(other.recordedByName, recordedByName) || other.recordedByName == recordedByName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pondId,buyerName,productName,quantity,unit,pricePerUnit,totalAmount,recordedById,recordedByName,timestamp,notes);

@override
String toString() {
  return 'PondSale(id: $id, pondId: $pondId, buyerName: $buyerName, productName: $productName, quantity: $quantity, unit: $unit, pricePerUnit: $pricePerUnit, totalAmount: $totalAmount, recordedById: $recordedById, recordedByName: $recordedByName, timestamp: $timestamp, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$PondSaleCopyWith<$Res> implements $PondSaleCopyWith<$Res> {
  factory _$PondSaleCopyWith(_PondSale value, $Res Function(_PondSale) _then) = __$PondSaleCopyWithImpl;
@override @useResult
$Res call({
 String id, String pondId, String buyerName, String productName, double quantity, String unit, double pricePerUnit, double totalAmount, String recordedById, String recordedByName,@TimestampConverter() DateTime? timestamp, String notes
});




}
/// @nodoc
class __$PondSaleCopyWithImpl<$Res>
    implements _$PondSaleCopyWith<$Res> {
  __$PondSaleCopyWithImpl(this._self, this._then);

  final _PondSale _self;
  final $Res Function(_PondSale) _then;

/// Create a copy of PondSale
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pondId = null,Object? buyerName = null,Object? productName = null,Object? quantity = null,Object? unit = null,Object? pricePerUnit = null,Object? totalAmount = null,Object? recordedById = null,Object? recordedByName = null,Object? timestamp = freezed,Object? notes = null,}) {
  return _then(_PondSale(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,buyerName: null == buyerName ? _self.buyerName : buyerName // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,pricePerUnit: null == pricePerUnit ? _self.pricePerUnit : pricePerUnit // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,recordedById: null == recordedById ? _self.recordedById : recordedById // ignore: cast_nullable_to_non_nullable
as String,recordedByName: null == recordedByName ? _self.recordedByName : recordedByName // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
