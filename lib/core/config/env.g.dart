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
    1899000054,
    2770367418,
    4041754346,
    4033956141,
    1275310063,
    2429470264,
    1084306806,
    12642090,
    3703306339,
    1193402000,
    3266946784,
    3698616896,
    4079463687,
    2116443016,
    4005927462,
  ];

  static const List<int> _envieddataappId = <int>[
    1898999942,
    2770367445,
    4041754244,
    4033956169,
    1275309980,
    2429470284,
    1084306711,
    12642142,
    3703306318,
    1193402097,
    3266946704,
    3698616880,
    4079463722,
    2116443134,
    4005927447,
  ];

  static final String appId = String.fromCharCodes(
    List<int>.generate(
      _envieddataappId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappId[i] ^ _enviedkeyappId[i]),
  );
}
