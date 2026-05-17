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
    719039094,
    2016098333,
    503756257,
    425766143,
    1060506938,
    980420897,
    256722730,
    3955437908,
    1250014536,
    3698506621,
    3665090861,
    3512117639,
    3516141002,
    2003979633,
    2799610344,
  ];

  static const List<int> _envieddataappId = <int>[
    719038982,
    2016098418,
    503756175,
    425766043,
    1060506953,
    980420949,
    256722763,
    3955437856,
    1250014565,
    3698506524,
    3665090909,
    3512117751,
    3516141031,
    2003979527,
    2799610329,
  ];

  static final String appId = String.fromCharCodes(
    List<int>.generate(
      _envieddataappId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappId[i] ^ _enviedkeyappId[i]),
  );
}
