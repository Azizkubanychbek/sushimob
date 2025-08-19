class Set {
  final int id;
  final String name;
  final double costPrice;
  final double retailPrice;
  final double setPrice;
  final double discountPercent;
  final double grossProfit;
  final double marginPercent;
  final List<SetComposition>? composition;

  Set({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.retailPrice,
    required this.setPrice,
    required this.discountPercent,
    required this.grossProfit,
    required this.marginPercent,
    this.composition,
  });

  factory Set.fromJson(Map<String, dynamic> json) {
    return Set(
      id: json['id']?.toInt() ?? 0,
      name: json['name'] ?? '',
      costPrice: (json['cost_price'] ?? 0.0).toDouble(),
      retailPrice: (json['retail_price'] ?? 0.0).toDouble(),
      setPrice: (json['set_price'] ?? 0.0).toDouble(),
      discountPercent: (json['discount_percent'] ?? 0.0).toDouble(),
      grossProfit: (json['gross_profit'] ?? 0.0).toDouble(),
      marginPercent: (json['margin_percent'] ?? 0.0).toDouble(),
      composition: json['composition'] != null
          ? (json['composition'] as List)
              .map((e) => SetComposition.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'set_price': setPrice,
      'discount_percent': discountPercent,
      'gross_profit': grossProfit,
      'margin_percent': marginPercent,
      'composition': composition?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Set(id: $id, name: $name, setPrice: $setPrice, discountPercent: $discountPercent%)';
  }
}

class SetComposition {
  final int setId;
  final int rollId;
  final String rollName;

  SetComposition({
    required this.setId,
    required this.rollId,
    required this.rollName,
  });

  factory SetComposition.fromJson(Map<String, dynamic> json) {
    return SetComposition(
      setId: json['set_id']?.toInt() ?? 0,
      rollId: json['roll_id']?.toInt() ?? 0,
      rollName: json['roll_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_id': setId,
      'roll_id': rollId,
      'roll_name': rollName,
    };
  }
}
