import 'app_roll.dart';

class Roll {
  final int id;
  final String name;
  final String description;
  final double salePrice;
  final double costPrice;
  final String imageUrl;
  final bool isPopular;
  final bool isNew;
  final List<RollIngredient>? ingredients;

  Roll({
    required this.id,
    required this.name,
    this.description = '',
    required this.salePrice,
    required this.costPrice,
    this.imageUrl = '',
    this.isPopular = false,
    this.isNew = false,
    this.ingredients,
  });

  factory Roll.fromJson(Map<String, dynamic> json) {
    return Roll(
      id: json['id']?.toInt() ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      salePrice: (json['sale_price'] ?? 0.0).toDouble(),
      costPrice: (json['cost_price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      isPopular: json['is_popular'] ?? false,
      isNew: json['is_new'] ?? false,
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
      'description': description,
      'sale_price': salePrice,
      'cost_price': costPrice,
      'image_url': imageUrl,
      'is_popular': isPopular,
      'is_new': isNew,
      'ingredients': ingredients?.map((e) => e.toJson()).toList(),
    };
  }

  // Метод для конвертации в AppRoll
  AppRoll toAppRoll() {
    return AppRoll.fromRoll(this, isPopular: isPopular, isNew: isNew);
  }

  @override
  String toString() {
    return 'Roll(id: $id, name: $name, salePrice: $salePrice, costPrice: $costPrice)';
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
