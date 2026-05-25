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
    947673971,
    1687329646,
    3387401404,
    3875140003,
    2635181849,
    485373437,
    10615268,
    754848946,
    2565000744,
    2321989456,
    2300646184,
    3831868856,
    409571981,
    103369360,
    3013125099,
  ];

  static const List<int> _envieddataappId = <int>[
    947673859,
    1687329537,
    3387401426,
    3875140039,
    2635181930,
    485373321,
    10615173,
    754848966,
    2565000709,
    2321989425,
    2300646232,
    3831868872,
    409572000,
    103369446,
    3013125082,
  ];

  static final String appId = String.fromCharCodes(
    List<int>.generate(
      _envieddataappId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappId[i] ^ _enviedkeyappId[i]),
  );
}
