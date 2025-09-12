import 'roll.dart';

class LoyaltyRoll {
  final int id;
  final int rollId;
  final bool isAvailable;
  final String createdAt;
  final Roll? roll;

  LoyaltyRoll({
    required this.id,
    required this.rollId,
    required this.isAvailable,
    required this.createdAt,
    this.roll,
  });

  factory LoyaltyRoll.fromJson(Map<String, dynamic> json) {
    return LoyaltyRoll(
      id: json['id'],
      rollId: json['roll_id'],
      isAvailable: json['is_available'],
      createdAt: json['created_at'],
      roll: json['roll'] != null ? Roll.fromJson(json['roll']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roll_id': rollId,
      'is_available': isAvailable,
      'created_at': createdAt,
      'roll': roll?.toJson(),
    };
  }
}
