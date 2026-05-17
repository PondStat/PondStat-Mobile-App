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
    2661983524,
    2072218835,
    3248196962,
    759172593,
    502414692,
    3355455218,
    3410186735,
    2243314300,
    2093438312,
    1967886170,
    3726366054,
    4026821144,
    4060563494,
    3704643110,
    1835899430,
  ];

  static const List<int> _envieddataappId = <int>[
    2661983572,
    2072218812,
    3248196876,
    759172501,
    502414615,
    3355455110,
    3410186638,
    2243314184,
    2093438277,
    1967886139,
    3726365974,
    4026821224,
    4060563467,
    3704643152,
    1835899415,
  ];

  static final String appId = String.fromCharCodes(
    List<int>.generate(
      _envieddataappId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappId[i] ^ _enviedkeyappId[i]),
  );
}
