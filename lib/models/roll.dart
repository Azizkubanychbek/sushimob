class Roll {
  final int id;
  final String name;
  final double salePrice;
  final double costPrice; // Changed from cost
  final List<RollIngredient>? ingredients;

  Roll({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.costPrice, // Changed from cost
    this.ingredients,
  });

  factory Roll.fromJson(Map<String, dynamic> json) {
    return Roll(
      id: json['id']?.toInt() ?? 0,
      name: json['name'] ?? '',
      salePrice: (json['sale_price'] ?? 0.0).toDouble(),
      costPrice: (json['cost_price'] ?? 0.0).toDouble(), // Changed from cost
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List)
              .map((e) => RollIngredient.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sale_price': salePrice,
      'cost_price': costPrice, // Changed from cost
      'ingredients': ingredients?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Roll(id: $id, name: $name, salePrice: $salePrice, costPrice: $costPrice)'; // Changed from cost
  }
}

class RollIngredient {
  final int rollId;
  final int ingredientId;
  final double amountPerRoll;
  final double cost;

  RollIngredient({
    required this.rollId,
    required this.ingredientId,
    required this.amountPerRoll,
    required this.cost,
  });

  factory RollIngredient.fromJson(Map<String, dynamic> json) {
    return RollIngredient(
      rollId: json['roll_id']?.toInt() ?? 0,
      ingredientId: json['ingredient_id']?.toInt() ?? 0,
      amountPerRoll: (json['amount_per_roll'] ?? 0.0).toDouble(),
      cost: (json['cost'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roll_id': rollId,
      'ingredient_id': ingredientId,
      'amount_per_roll': amountPerRoll,
      'cost': cost,
    };
  }
}
