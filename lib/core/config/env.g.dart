// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// generated_from: .env
final class _Env {
  static const List<int> _enviedkeyappId = <int>[
    1311382689,
    1443060333,
    3753154175,
    3616896897,
    2283581497,
    1240423340,
    3196298702,
    3453225281,
    747041218,
    4186404900,
    2999468461,
    3069849052,
    165022239,
    1568251954,
    3648017232,
  ];

  static const List<int> _envieddataappId = <int>[
    1311382737,
    1443060226,
    3753154065,
    3616896997,
    2283581514,
    1240423384,
    3196298671,
    3453225269,
    747041263,
    4186404933,
    2999468509,
    3069849004,
    165022258,
    1568251972,
    3648017249,
  ];

  static final String appId = String.fromCharCodes(
    List<int>.generate(
      _envieddataappId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappId[i] ^ _enviedkeyappId[i]),
  );
}
