// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'measurement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Measurement {

 String get id; String get pondId; String get dateKey;@TimestampConverter() DateTime? get timestamp;@TimestampConverter() DateTime? get recordedAt; String get recordedBy; String get recorderName; String get type; String get parameter; double get value; String get unit; String get timeString; Map<String, double> get pointValues; Map<String, List<double>> get replicateValues; String? get notes; Map<String, dynamic>? get alert;// Edit metadata
@TimestampConverter() DateTime? get editedAt; String? get editedBy; String? get editorName;
/// Create a copy of Measurement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeasurementCopyWith<Measurement> get copyWith => _$MeasurementCopyWithImpl<Measurement>(this as Measurement, _$identity);

  /// Serializes this Measurement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Measurement&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.dateKey, dateKey) || other.dateKey == dateKey)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.recorderName, recorderName) || other.recorderName == recorderName)&&(identical(other.type, type) || other.type == type)&&(identical(other.parameter, parameter) || other.parameter == parameter)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.timeString, timeString) || other.timeString == timeString)&&const DeepCollectionEquality().equals(other.pointValues, pointValues)&&const DeepCollectionEquality().equals(other.replicateValues, replicateValues)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.alert, alert)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.editedBy, editedBy) || other.editedBy == editedBy)&&(identical(other.editorName, editorName) || other.editorName == editorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,pondId,dateKey,timestamp,recordedAt,recordedBy,recorderName,type,parameter,value,unit,timeString,const DeepCollectionEquality().hash(pointValues),const DeepCollectionEquality().hash(replicateValues),notes,const DeepCollectionEquality().hash(alert),editedAt,editedBy,editorName]);

@override
String toString() {
  return 'Measurement(id: $id, pondId: $pondId, dateKey: $dateKey, timestamp: $timestamp, recordedAt: $recordedAt, recordedBy: $recordedBy, recorderName: $recorderName, type: $type, parameter: $parameter, value: $value, unit: $unit, timeString: $timeString, pointValues: $pointValues, replicateValues: $replicateValues, notes: $notes, alert: $alert, editedAt: $editedAt, editedBy: $editedBy, editorName: $editorName)';
}


}

/// @nodoc
abstract mixin class $MeasurementCopyWith<$Res>  {
  factory $MeasurementCopyWith(Measurement value, $Res Function(Measurement) _then) = _$MeasurementCopyWithImpl;
@useResult
$Res call({
 String id, String pondId, String dateKey,@TimestampConverter() DateTime? timestamp,@TimestampConverter() DateTime? recordedAt, String recordedBy, String recorderName, String type, String parameter, double value, String unit, String timeString, Map<String, double> pointValues, Map<String, List<double>> replicateValues, String? notes, Map<String, dynamic>? alert,@TimestampConverter() DateTime? editedAt, String? editedBy, String? editorName
});




}
/// @nodoc
class _$MeasurementCopyWithImpl<$Res>
    implements $MeasurementCopyWith<$Res> {
  _$MeasurementCopyWithImpl(this._self, this._then);

  final Measurement _self;
  final $Res Function(Measurement) _then;

/// Create a copy of Measurement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pondId = null,Object? dateKey = null,Object? timestamp = freezed,Object? recordedAt = freezed,Object? recordedBy = null,Object? recorderName = null,Object? type = null,Object? parameter = null,Object? value = null,Object? unit = null,Object? timeString = null,Object? pointValues = null,Object? replicateValues = null,Object? notes = freezed,Object? alert = freezed,Object? editedAt = freezed,Object? editedBy = freezed,Object? editorName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,dateKey: null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recordedBy: null == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String,recorderName: null == recorderName ? _self.recorderName : recorderName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,parameter: null == parameter ? _self.parameter : parameter // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,timeString: null == timeString ? _self.timeString : timeString // ignore: cast_nullable_to_non_nullable
as String,pointValues: null == pointValues ? _self.pointValues : pointValues // ignore: cast_nullable_to_non_nullable
as Map<String, double>,replicateValues: null == replicateValues ? _self.replicateValues : replicateValues // ignore: cast_nullable_to_non_nullable
as Map<String, List<double>>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,alert: freezed == alert ? _self.alert : alert // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,editedBy: freezed == editedBy ? _self.editedBy : editedBy // ignore: cast_nullable_to_non_nullable
as String?,editorName: freezed == editorName ? _self.editorName : editorName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Measurement].
extension MeasurementPatterns on Measurement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Measurement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Measurement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Measurement value)  $default,){
final _that = this;
switch (_that) {
case _Measurement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Measurement value)?  $default,){
final _that = this;
switch (_that) {
case _Measurement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pondId,  String dateKey, @TimestampConverter()  DateTime? timestamp, @TimestampConverter()  DateTime? recordedAt,  String recordedBy,  String recorderName,  String type,  String parameter,  double value,  String unit,  String timeString,  Map<String, double> pointValues,  Map<String, List<double>> replicateValues,  String? notes,  Map<String, dynamic>? alert, @TimestampConverter()  DateTime? editedAt,  String? editedBy,  String? editorName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Measurement() when $default != null:
return $default(_that.id,_that.pondId,_that.dateKey,_that.timestamp,_that.recordedAt,_that.recordedBy,_that.recorderName,_that.type,_that.parameter,_that.value,_that.unit,_that.timeString,_that.pointValues,_that.replicateValues,_that.notes,_that.alert,_that.editedAt,_that.editedBy,_that.editorName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pondId,  String dateKey, @TimestampConverter()  DateTime? timestamp, @TimestampConverter()  DateTime? recordedAt,  String recordedBy,  String recorderName,  String type,  String parameter,  double value,  String unit,  String timeString,  Map<String, double> pointValues,  Map<String, List<double>> replicateValues,  String? notes,  Map<String, dynamic>? alert, @TimestampConverter()  DateTime? editedAt,  String? editedBy,  String? editorName)  $default,) {final _that = this;
switch (_that) {
case _Measurement():
return $default(_that.id,_that.pondId,_that.dateKey,_that.timestamp,_that.recordedAt,_that.recordedBy,_that.recorderName,_that.type,_that.parameter,_that.value,_that.unit,_that.timeString,_that.pointValues,_that.replicateValues,_that.notes,_that.alert,_that.editedAt,_that.editedBy,_that.editorName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pondId,  String dateKey, @TimestampConverter()  DateTime? timestamp, @TimestampConverter()  DateTime? recordedAt,  String recordedBy,  String recorderName,  String type,  String parameter,  double value,  String unit,  String timeString,  Map<String, double> pointValues,  Map<String, List<double>> replicateValues,  String? notes,  Map<String, dynamic>? alert, @TimestampConverter()  DateTime? editedAt,  String? editedBy,  String? editorName)?  $default,) {final _that = this;
switch (_that) {
case _Measurement() when $default != null:
return $default(_that.id,_that.pondId,_that.dateKey,_that.timestamp,_that.recordedAt,_that.recordedBy,_that.recorderName,_that.type,_that.parameter,_that.value,_that.unit,_that.timeString,_that.pointValues,_that.replicateValues,_that.notes,_that.alert,_that.editedAt,_that.editedBy,_that.editorName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Measurement implements Measurement {
  const _Measurement({this.id = '', required this.pondId, this.dateKey = '', @TimestampConverter() this.timestamp, @TimestampConverter() this.recordedAt, this.recordedBy = '', this.recorderName = 'Unknown', required this.type, required this.parameter, required this.value, required this.unit, this.timeString = '', final  Map<String, double> pointValues = const {}, final  Map<String, List<double>> replicateValues = const {}, this.notes, final  Map<String, dynamic>? alert, @TimestampConverter() this.editedAt, this.editedBy, this.editorName}): _pointValues = pointValues,_replicateValues = replicateValues,_alert = alert;
  factory _Measurement.fromJson(Map<String, dynamic> json) => _$MeasurementFromJson(json);

@override@JsonKey() final  String id;
@override final  String pondId;
@override@JsonKey() final  String dateKey;
@override@TimestampConverter() final  DateTime? timestamp;
@override@TimestampConverter() final  DateTime? recordedAt;
@override@JsonKey() final  String recordedBy;
@override@JsonKey() final  String recorderName;
@override final  String type;
@override final  String parameter;
@override final  double value;
@override final  String unit;
@override@JsonKey() final  String timeString;
 final  Map<String, double> _pointValues;
@override@JsonKey() Map<String, double> get pointValues {
  if (_pointValues is EqualUnmodifiableMapView) return _pointValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pointValues);
}

 final  Map<String, List<double>> _replicateValues;
@override@JsonKey() Map<String, List<double>> get replicateValues {
  if (_replicateValues is EqualUnmodifiableMapView) return _replicateValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_replicateValues);
}

@override final  String? notes;
 final  Map<String, dynamic>? _alert;
@override Map<String, dynamic>? get alert {
  final value = _alert;
  if (value == null) return null;
  if (_alert is EqualUnmodifiableMapView) return _alert;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// Edit metadata
@override@TimestampConverter() final  DateTime? editedAt;
@override final  String? editedBy;
@override final  String? editorName;

/// Create a copy of Measurement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeasurementCopyWith<_Measurement> get copyWith => __$MeasurementCopyWithImpl<_Measurement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeasurementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Measurement&&(identical(other.id, id) || other.id == id)&&(identical(other.pondId, pondId) || other.pondId == pondId)&&(identical(other.dateKey, dateKey) || other.dateKey == dateKey)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.recorderName, recorderName) || other.recorderName == recorderName)&&(identical(other.type, type) || other.type == type)&&(identical(other.parameter, parameter) || other.parameter == parameter)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.timeString, timeString) || other.timeString == timeString)&&const DeepCollectionEquality().equals(other._pointValues, _pointValues)&&const DeepCollectionEquality().equals(other._replicateValues, _replicateValues)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._alert, _alert)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.editedBy, editedBy) || other.editedBy == editedBy)&&(identical(other.editorName, editorName) || other.editorName == editorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,pondId,dateKey,timestamp,recordedAt,recordedBy,recorderName,type,parameter,value,unit,timeString,const DeepCollectionEquality().hash(_pointValues),const DeepCollectionEquality().hash(_replicateValues),notes,const DeepCollectionEquality().hash(_alert),editedAt,editedBy,editorName]);

@override
String toString() {
  return 'Measurement(id: $id, pondId: $pondId, dateKey: $dateKey, timestamp: $timestamp, recordedAt: $recordedAt, recordedBy: $recordedBy, recorderName: $recorderName, type: $type, parameter: $parameter, value: $value, unit: $unit, timeString: $timeString, pointValues: $pointValues, replicateValues: $replicateValues, notes: $notes, alert: $alert, editedAt: $editedAt, editedBy: $editedBy, editorName: $editorName)';
}


}

/// @nodoc
abstract mixin class _$MeasurementCopyWith<$Res> implements $MeasurementCopyWith<$Res> {
  factory _$MeasurementCopyWith(_Measurement value, $Res Function(_Measurement) _then) = __$MeasurementCopyWithImpl;
@override @useResult
$Res call({
 String id, String pondId, String dateKey,@TimestampConverter() DateTime? timestamp,@TimestampConverter() DateTime? recordedAt, String recordedBy, String recorderName, String type, String parameter, double value, String unit, String timeString, Map<String, double> pointValues, Map<String, List<double>> replicateValues, String? notes, Map<String, dynamic>? alert,@TimestampConverter() DateTime? editedAt, String? editedBy, String? editorName
});




}
/// @nodoc
class __$MeasurementCopyWithImpl<$Res>
    implements _$MeasurementCopyWith<$Res> {
  __$MeasurementCopyWithImpl(this._self, this._then);

  final _Measurement _self;
  final $Res Function(_Measurement) _then;

/// Create a copy of Measurement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pondId = null,Object? dateKey = null,Object? timestamp = freezed,Object? recordedAt = freezed,Object? recordedBy = null,Object? recorderName = null,Object? type = null,Object? parameter = null,Object? value = null,Object? unit = null,Object? timeString = null,Object? pointValues = null,Object? replicateValues = null,Object? notes = freezed,Object? alert = freezed,Object? editedAt = freezed,Object? editedBy = freezed,Object? editorName = freezed,}) {
  return _then(_Measurement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pondId: null == pondId ? _self.pondId : pondId // ignore: cast_nullable_to_non_nullable
as String,dateKey: null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recordedBy: null == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String,recorderName: null == recorderName ? _self.recorderName : recorderName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,parameter: null == parameter ? _self.parameter : parameter // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,timeString: null == timeString ? _self.timeString : timeString // ignore: cast_nullable_to_non_nullable
as String,pointValues: null == pointValues ? _self._pointValues : pointValues // ignore: cast_nullable_to_non_nullable
as Map<String, double>,replicateValues: null == replicateValues ? _self._replicateValues : replicateValues // ignore: cast_nullable_to_non_nullable
as Map<String, List<double>>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,alert: freezed == alert ? _self._alert : alert // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,editedBy: freezed == editedBy ? _self.editedBy : editedBy // ignore: cast_nullable_to_non_nullable
as String?,editorName: freezed == editorName ? _self.editorName : editorName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
