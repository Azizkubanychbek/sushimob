class LoyaltyCard {
  final int id;
  final int userId;
  final String cardNumber;
  final int filledRolls;
  final bool isCompleted;
  final String createdAt;
  final String? completedAt;
  final double progressPercent;

  LoyaltyCard({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.filledRolls,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.progressPercent,
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) {
    return LoyaltyCard(
      id: json['id'],
      userId: json['user_id'],
      cardNumber: json['card_number'],
      filledRolls: json['filled_rolls'],
      isCompleted: json['is_completed'],
      createdAt: json['created_at'],
      completedAt: json['completed_at'],
      progressPercent: json['progress_percent']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'card_number': cardNumber,
      'filled_rolls': filledRolls,
      'is_completed': isCompleted,
      'created_at': createdAt,
      'completed_at': completedAt,
      'progress_percent': progressPercent,
    };
  }
}
