import 'roll.dart';

class LoyaltyCardUsage {
  final int id;
  final int userId;
  final int loyaltyCardId;
  final int rollId;
  final int? orderId;
  final String usedAt;
  final Roll? roll;
  final String? cardNumber;

  LoyaltyCardUsage({
    required this.id,
    required this.userId,
    required this.loyaltyCardId,
    required this.rollId,
    this.orderId,
    required this.usedAt,
    this.roll,
    this.cardNumber,
  });

  factory LoyaltyCardUsage.fromJson(Map<String, dynamic> json) {
    return LoyaltyCardUsage(
      id: json['id'],
      userId: json['user_id'],
      loyaltyCardId: json['loyalty_card_id'],
      rollId: json['roll_id'],
      orderId: json['order_id'],
      usedAt: json['used_at'],
      roll: json['roll'] != null ? Roll.fromJson(json['roll']) : null,
      cardNumber: json['card_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'loyalty_card_id': loyaltyCardId,
      'roll_id': rollId,
      'order_id': orderId,
      'used_at': usedAt,
      'roll': roll?.toJson(),
      'card_number': cardNumber,
    };
  }
}
