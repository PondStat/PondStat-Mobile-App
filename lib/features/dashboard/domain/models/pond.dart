import 'package:equatable/equatable.dart';

class Pond extends Equatable {
  final String id;
  final String name;
  final String species;
  final int stockingQuantity;
  final int targetCulturePeriodDays;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> roles;

  const Pond({
    required this.id,
    required this.name,
    required this.species,
    required this.stockingQuantity,
    required this.targetCulturePeriodDays,
    required this.ownerId,
    required this.memberIds,
    required this.roles,
  });

  factory Pond.fromJson(Map<String, dynamic> json, String id) {
    return Pond(
      id: id,
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      stockingQuantity: json['stockingQuantity'] as int? ?? 0,
      targetCulturePeriodDays: json['targetCulturePeriodDays'] as int? ?? 0,
      ownerId: json['ownerId'] as String? ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      roles: Map<String, String>.from(json['roles'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'stockingQuantity': stockingQuantity,
      'targetCulturePeriodDays': targetCulturePeriodDays,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'roles': roles,
      // createdAt is handled by server timestamp at creation time
    };
  }

  Pond copyWith({
    String? id,
    String? name,
    String? species,
    int? stockingQuantity,
    int? targetCulturePeriodDays,
    String? ownerId,
    List<String>? memberIds,
    Map<String, String>? roles,
  }) {
    return Pond(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      stockingQuantity: stockingQuantity ?? this.stockingQuantity,
      targetCulturePeriodDays: targetCulturePeriodDays ?? this.targetCulturePeriodDays,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      roles: roles ?? this.roles,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        species,
        stockingQuantity,
        targetCulturePeriodDays,
        ownerId,
        memberIds,
        roles,
      ];
}
