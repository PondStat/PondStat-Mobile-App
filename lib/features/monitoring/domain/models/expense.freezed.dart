// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Expense {

 String get id; String get pondId; String get item; int get quantity; double get amountPerItem; double get totalAmount; String get buyerId; String get buyerName;@TimestampConverter() DateTime? get timestamp;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.item, item) || other.item == item)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amountPerItem, amountPerItem) || other.amountPerItem == amountPerItem)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.buyerName, buyerName) || other.buyerName == buyerName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pondId,item,quantity,amountPerItem,totalAmount,buyerId,buyerName,timestamp);

@override
String toString() {
  return 'Expense(id: $id, pondId: $pondId, item: $item, quantity: $quantity, amountPerItem: $amountPerItem, totalAmount: $totalAmount, buyerId: $buyerId, buyerName: $buyerName, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String pondId, String item, int quantity, double amountPerItem, double totalAmount, String buyerId, String buyerName,@TimestampConverter() DateTime? timestamp
});




}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pondId = null,Object? item = null,Object? quantity = null,Object? amountPerItem = null,Object? totalAmount = null,Object? buyerId = null,Object? buyerName = null,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,amountPerItem: null == amountPerItem ? _self.amountPerItem : amountPerItem // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,buyerName: null == buyerName ? _self.buyerName : buyerName // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pondId,  String item,  int quantity,  double amountPerItem,  double totalAmount,  String buyerId,  String buyerName, @TimestampConverter()  DateTime? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.pondId,_that.item,_that.quantity,_that.amountPerItem,_that.totalAmount,_that.buyerId,_that.buyerName,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pondId,  String item,  int quantity,  double amountPerItem,  double totalAmount,  String buyerId,  String buyerName, @TimestampConverter()  DateTime? timestamp)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.id,_that.pondId,_that.item,_that.quantity,_that.amountPerItem,_that.totalAmount,_that.buyerId,_that.buyerName,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pondId,  String item,  int quantity,  double amountPerItem,  double totalAmount,  String buyerId,  String buyerName, @TimestampConverter()  DateTime? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.pondId,_that.item,_that.quantity,_that.amountPerItem,_that.totalAmount,_that.buyerId,_that.buyerName,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expense implements Expense {
  const _Expense({this.id = '', required this.pondId, required this.item, this.quantity = 0, this.amountPerItem = 0.0, this.totalAmount = 0.0, this.buyerId = '', this.buyerName = 'Unknown', @TimestampConverter() this.timestamp});
  factory _Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

@override@JsonKey() final  String id;
@override final  String pondId;
@override final  String item;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  double amountPerItem;
@override@JsonKey() final  double totalAmount;
@override@JsonKey() final  String buyerId;
@override@JsonKey() final  String buyerName;
@override@TimestampConverter() final  DateTime? timestamp;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.item, item) || other.item == item)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amountPerItem, amountPerItem) || other.amountPerItem == amountPerItem)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.buyerName, buyerName) || other.buyerName == buyerName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pondId,item,quantity,amountPerItem,totalAmount,buyerId,buyerName,timestamp);

@override
String toString() {
  return 'Expense(id: $id, pondId: $pondId, item: $item, quantity: $quantity, amountPerItem: $amountPerItem, totalAmount: $totalAmount, buyerId: $buyerId, buyerName: $buyerName, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String pondId, String item, int quantity, double amountPerItem, double totalAmount, String buyerId, String buyerName,@TimestampConverter() DateTime? timestamp
});




}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pondId = null,Object? item = null,Object? quantity = null,Object? amountPerItem = null,Object? totalAmount = null,Object? buyerId = null,Object? buyerName = null,Object? timestamp = freezed,}) {
  return _then(_Expense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,amountPerItem: null == amountPerItem ? _self.amountPerItem : amountPerItem // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,buyerName: null == buyerName ? _self.buyerName : buyerName // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
