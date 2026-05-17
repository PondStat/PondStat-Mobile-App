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
    3144655308,
    445976207,
    1609028276,
    3162103432,
    1209569714,
    3120596499,
    3194669867,
    1684074568,
    1072915104,
    2888010651,
    1746736569,
    2164616361,
    1057683670,
    1781163553,
    2937249548,
  ];

  static const List<int> _envieddataappId = <int>[
    3144655292,
    445976288,
    1609028314,
    3162103532,
    1209569729,
    3120596583,
    3194669898,
    1684074556,
    1072915085,
    2888010746,
    1746736585,
    2164616409,
    1057683707,
    1781163607,
    2937249597,
  ];

  static final String appId = String.fromCharCodes(
    List<int>.generate(
      _envieddataappId.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddataappId[i] ^ _enviedkeyappId[i]),
  );
}
