import 'app_set.dart';

class Set {
  final int id;
  final String name;
  final String description;
  final double costPrice;
  final double setPrice;
  final double discountPercent;
  final String imageUrl;
  final bool isPopular;
  final bool isNew;
  final List<SetComposition>? composition;

  Set({
    required this.id,
    required this.name,
    this.description = '',
    required this.costPrice,
    required this.setPrice,
    this.discountPercent = 0.0,
    this.imageUrl = '',
    this.isPopular = false,
    this.isNew = false,
    this.composition,
  });

  factory Set.fromJson(Map<String, dynamic> json) {
    return Set(
      id: json['id']?.toInt() ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      costPrice: (json['cost_price'] ?? 0.0).toDouble(),
      setPrice: (json['set_price'] ?? 0.0).toDouble(),
      discountPercent: (json['discount_percent'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      isPopular: json['is_popular'] ?? false,
      isNew: json['is_new'] ?? false,
      composition: json['rolls'] != null
          ? (json['rolls'] as List)
              .map((e) => SetComposition.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cost_price': costPrice,
      'set_price': setPrice,
      'discount_percent': discountPercent,
      'image_url': imageUrl,
      'is_popular': isPopular,
      'is_new': isNew,
      'rolls': composition?.map((e) => e.toJson()).toList(),
    };
  }

  // Метод для конвертации в AppSet
  AppSet toAppSet() {
    return AppSet.fromSet(this, isPopular: isPopular, isNew: isNew);
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
  final int quantity;

  SetComposition({
    required this.setId,
    required this.rollId,
    required this.rollName,
    this.quantity = 1,
  });

  factory SetComposition.fromJson(Map<String, dynamic> json) {
    return SetComposition(
      setId: json['set_id']?.toInt() ?? 0,
      rollId: json['roll_id']?.toInt() ?? 0,
      rollName: json['roll']?['name'] ?? '',
      quantity: json['quantity']?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_id': setId,
      'roll_id': rollId,
      'roll_name': rollName,
      'quantity': quantity,
    };
  }
}
