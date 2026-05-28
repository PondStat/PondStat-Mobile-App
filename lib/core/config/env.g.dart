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
    250790806,
    2847671988,
    3158278532,
    1995743389,
    3188133835,
    800361735,
    1945670286,
    2440831881,
    3781048524,
    2812239514,
    2257445326,
    3163048347,
    2362150988,
    2134064051,
    369222461,
  ];

  static const List<int> _envieddataappId = <int>[
    250790886,
    2847672027,
    3158278634,
    1995743481,
    3188133816,
    800361843,
    1945670383,
    2440831997,
    3781048545,
    2812239611,
    2257445310,
    3163048427,
    2362151009,
    2134064069,
    369222412,
  ];

  static final String appId = String.fromCharCodes(
    List<int>.generate(
      _envieddataappId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappId[i] ^ _enviedkeyappId[i]),
  );
}
