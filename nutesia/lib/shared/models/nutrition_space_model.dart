import 'member_model.dart';

class NutritionSpaceModel {
  final String id;
  final String ownerUserId;
  final String mode; // "PERSONAL" | "FAMILY"
  final String activeProfileId;
  final int maxMembers;
  final List<MemberModel> profiles;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NutritionSpaceModel({
    required this.id,
    required this.ownerUserId,
    this.mode = 'PERSONAL',
    this.activeProfileId = '',
    this.maxMembers = 3,
    this.profiles = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFamilyMode => mode.toUpperCase() == 'FAMILY';
  bool get canAddMember => profiles.length < maxMembers;

  MemberModel? get activeProfile {
    if (profiles.isEmpty) return null;
    if (activeProfileId.isNotEmpty) {
      try {
        return profiles.firstWhere((p) => p.id == activeProfileId);
      } catch (_) {}
    }
    return profiles.first;
  }

  factory NutritionSpaceModel.fromJson(Map<String, dynamic> json) {
    var profs = <MemberModel>[];
    if (json['profiles'] != null && json['profiles'] is List) {
      profs = (json['profiles'] as List)
          .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return NutritionSpaceModel(
      id: json['id'] as String? ?? json['deviceId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      mode: (json['mode'] as String? ?? 'PERSONAL').toUpperCase(),
      activeProfileId: json['activeProfileId'] as String? ?? '',
      maxMembers: json['maxMembers'] as int? ?? 3,
      profiles: profs,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': id,
        'ownerUserId': ownerUserId,
        'mode': mode,
        'activeProfileId': activeProfileId,
        'maxMembers': maxMembers,
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  NutritionSpaceModel copyWith({
    String? id,
    String? ownerUserId,
    String? mode,
    String? activeProfileId,
    int? maxMembers,
    List<MemberModel>? profiles,
    DateTime? updatedAt,
  }) =>
      NutritionSpaceModel(
        id: id ?? this.id,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        mode: mode ?? this.mode,
        activeProfileId: activeProfileId ?? this.activeProfileId,
        maxMembers: maxMembers ?? this.maxMembers,
        profiles: profiles ?? this.profiles,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
