// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pond_expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PondExpense {

 String get id; String get pondId; String get category; String get item; double get quantity; String get unit; double get amountPerUnit; double get totalAmount; String get recordedById; String get recordedByName;@TimestampConverter() DateTime? get timestamp; String get notes;
/// Create a copy of PondExpense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PondExpenseCopyWith<PondExpense> get copyWith => _$PondExpenseCopyWithImpl<PondExpense>(this as PondExpense, _$identity);

  /// Serializes this PondExpense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PondExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.category, category) || other.category == category)&&(identical(other.item, item) || other.item == item)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.amountPerUnit, amountPerUnit) || other.amountPerUnit == amountPerUnit)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.recordedById, recordedById) || other.recordedById == recordedById)&&(identical(other.recordedByName, recordedByName) || other.recordedByName == recordedByName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pondId,category,item,quantity,unit,amountPerUnit,totalAmount,recordedById,recordedByName,timestamp,notes);

@override
String toString() {
  return 'PondExpense(id: $id, pondId: $pondId, category: $category, item: $item, quantity: $quantity, unit: $unit, amountPerUnit: $amountPerUnit, totalAmount: $totalAmount, recordedById: $recordedById, recordedByName: $recordedByName, timestamp: $timestamp, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $PondExpenseCopyWith<$Res>  {
  factory $PondExpenseCopyWith(PondExpense value, $Res Function(PondExpense) _then) = _$PondExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String pondId, String category, String item, double quantity, String unit, double amountPerUnit, double totalAmount, String recordedById, String recordedByName,@TimestampConverter() DateTime? timestamp, String notes
});




}
/// @nodoc
class _$PondExpenseCopyWithImpl<$Res>
    implements $PondExpenseCopyWith<$Res> {
  _$PondExpenseCopyWithImpl(this._self, this._then);

  final PondExpense _self;
  final $Res Function(PondExpense) _then;

/// Create a copy of PondExpense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pondId = null,Object? category = null,Object? item = null,Object? quantity = null,Object? unit = null,Object? amountPerUnit = null,Object? totalAmount = null,Object? recordedById = null,Object? recordedByName = null,Object? timestamp = freezed,Object? notes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,amountPerUnit: null == amountPerUnit ? _self.amountPerUnit : amountPerUnit // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,recordedById: null == recordedById ? _self.recordedById : recordedById // ignore: cast_nullable_to_non_nullable
as String,recordedByName: null == recordedByName ? _self.recordedByName : recordedByName // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PondExpense].
extension PondExpensePatterns on PondExpense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PondExpense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PondExpense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PondExpense value)  $default,){
final _that = this;
switch (_that) {
case _PondExpense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PondExpense value)?  $default,){
final _that = this;
switch (_that) {
case _PondExpense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pondId,  String category,  String item,  double quantity,  String unit,  double amountPerUnit,  double totalAmount,  String recordedById,  String recordedByName, @TimestampConverter()  DateTime? timestamp,  String notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PondExpense() when $default != null:
return $default(_that.id,_that.pondId,_that.category,_that.item,_that.quantity,_that.unit,_that.amountPerUnit,_that.totalAmount,_that.recordedById,_that.recordedByName,_that.timestamp,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pondId,  String category,  String item,  double quantity,  String unit,  double amountPerUnit,  double totalAmount,  String recordedById,  String recordedByName, @TimestampConverter()  DateTime? timestamp,  String notes)  $default,) {final _that = this;
switch (_that) {
case _PondExpense():
return $default(_that.id,_that.pondId,_that.category,_that.item,_that.quantity,_that.unit,_that.amountPerUnit,_that.totalAmount,_that.recordedById,_that.recordedByName,_that.timestamp,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pondId,  String category,  String item,  double quantity,  String unit,  double amountPerUnit,  double totalAmount,  String recordedById,  String recordedByName, @TimestampConverter()  DateTime? timestamp,  String notes)?  $default,) {final _that = this;
switch (_that) {
case _PondExpense() when $default != null:
return $default(_that.id,_that.pondId,_that.category,_that.item,_that.quantity,_that.unit,_that.amountPerUnit,_that.totalAmount,_that.recordedById,_that.recordedByName,_that.timestamp,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PondExpense implements PondExpense {
  const _PondExpense({this.id = '', required this.pondId, required this.category, required this.item, this.quantity = 0.0, this.unit = '', this.amountPerUnit = 0.0, this.totalAmount = 0.0, this.recordedById = '', this.recordedByName = 'Unknown', @TimestampConverter() this.timestamp, this.notes = ''});
  factory _PondExpense.fromJson(Map<String, dynamic> json) => _$PondExpenseFromJson(json);

@override@JsonKey() final  String id;
@override final  String pondId;
@override final  String category;
@override final  String item;
@override@JsonKey() final  double quantity;
@override@JsonKey() final  String unit;
@override@JsonKey() final  double amountPerUnit;
@override@JsonKey() final  double totalAmount;
@override@JsonKey() final  String recordedById;
@override@JsonKey() final  String recordedByName;
@override@TimestampConverter() final  DateTime? timestamp;
@override@JsonKey() final  String notes;

/// Create a copy of PondExpense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PondExpenseCopyWith<_PondExpense> get copyWith => __$PondExpenseCopyWithImpl<_PondExpense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PondExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PondExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.category, category) || other.category == category)&&(identical(other.item, item) || other.item == item)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.amountPerUnit, amountPerUnit) || other.amountPerUnit == amountPerUnit)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.recordedById, recordedById) || other.recordedById == recordedById)&&(identical(other.recordedByName, recordedByName) || other.recordedByName == recordedByName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pondId,category,item,quantity,unit,amountPerUnit,totalAmount,recordedById,recordedByName,timestamp,notes);

@override
String toString() {
  return 'PondExpense(id: $id, pondId: $pondId, category: $category, item: $item, quantity: $quantity, unit: $unit, amountPerUnit: $amountPerUnit, totalAmount: $totalAmount, recordedById: $recordedById, recordedByName: $recordedByName, timestamp: $timestamp, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$PondExpenseCopyWith<$Res> implements $PondExpenseCopyWith<$Res> {
  factory _$PondExpenseCopyWith(_PondExpense value, $Res Function(_PondExpense) _then) = __$PondExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String pondId, String category, String item, double quantity, String unit, double amountPerUnit, double totalAmount, String recordedById, String recordedByName,@TimestampConverter() DateTime? timestamp, String notes
});




}
/// @nodoc
class __$PondExpenseCopyWithImpl<$Res>
    implements _$PondExpenseCopyWith<$Res> {
  __$PondExpenseCopyWithImpl(this._self, this._then);

  final _PondExpense _self;
  final $Res Function(_PondExpense) _then;

/// Create a copy of PondExpense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pondId = null,Object? category = null,Object? item = null,Object? quantity = null,Object? unit = null,Object? amountPerUnit = null,Object? totalAmount = null,Object? recordedById = null,Object? recordedByName = null,Object? timestamp = freezed,Object? notes = null,}) {
  return _then(_PondExpense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,amountPerUnit: null == amountPerUnit ? _self.amountPerUnit : amountPerUnit // ignore: cast_nullable_to_non_nullable
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
