import 'app_roll.dart';
import 'set.dart';

class AppSet {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<AppRoll> rolls;
  final bool isPopular;
  final bool isNew;
  final double discount;
  final double originalPrice;
  final int totalRolls;

  AppSet({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rolls,
    this.isPopular = false,
    this.isNew = false,
    this.discount = 0.0,
    this.originalPrice = 0.0,
  }) : totalRolls = rolls.length;

  // Создание AppSet на основе роллов
  factory AppSet.createFromRolls({
    required int id,
    required String name,
    required String description,
    required List<AppRoll> rolls,
    double discount = 0.0,
    bool isPopular = false,
  }) {
    // Проверяем входные параметры
    if (rolls.isEmpty) {
      throw ArgumentError('Сет должен содержать хотя бы один ролл');
    }
    
    // Проверяем, что имя и описание не пустые
    final safeName = name.isNotEmpty ? name : 'Сет $id';
    final safeDescription = description.isNotEmpty ? description : 'Вкусный набор роллов';
    
    final originalPrice = rolls.fold(0.0, (sum, roll) => sum + roll.price);
    final finalPrice = discount > 0 ? originalPrice * (1 - discount / 100) : originalPrice;

    return AppSet(
      id: id,
      name: safeName,
      description: safeDescription,
      price: finalPrice > 0 ? finalPrice : originalPrice,
      imageUrl: _getDefaultImage(name),
      rolls: rolls,
      isPopular: isPopular,
      discount: discount >= 0 ? discount : 0.0,
      originalPrice: originalPrice > 0 ? originalPrice : 100.0,
    );
  }

  // Создание AppSet из Excel данных
  factory AppSet.fromExcelData({
    required int id,
    required String name,
    required double setPrice,
    required double discountPercent,
    required List<AppRoll> rolls,
    bool isPopular = false,
  }) {
    final safeName = name.isNotEmpty ? name : 'Сет $id';
    final description = _generateDescription(safeName, rolls);
    
    return AppSet(
      id: id,
      name: safeName,
      description: description,
      price: setPrice,
      imageUrl: _getDefaultImage(safeName),
      rolls: rolls,
      isPopular: isPopular,
      discount: discountPercent,
      originalPrice: setPrice / (1 - discountPercent / 100),
    );
  }

  // Создание AppSet из модели Set (API)
  factory AppSet.fromSet(Set set, {bool isPopular = false, bool isNew = false}) {
    final safeName = set.name.isNotEmpty ? set.name : 'Сет ${set.id}';
    final safeDescription = set.description.isNotEmpty ? set.description : 'Вкусный набор роллов';
    
    // Создаем список-заглушку для подсчета общего количества роллов в сете
    final totalRollsCount = (set.composition ?? [])
        .fold<int>(0, (sum, c) => sum + c.quantity);
    final placeholderRolls = List<AppRoll>.generate(totalRollsCount, (index) => AppRoll(
      id: index,
      name: 'Ролл',
      price: 0,
      description: '',
      imageUrl: _getDefaultImage(safeName),
      category: 'Роллы',
    ));
    
    return AppSet(
      id: set.id,
      name: safeName,
      description: safeDescription,
      price: set.setPrice,
      imageUrl: set.imageUrl.isNotEmpty ? set.imageUrl : _getDefaultImage(safeName),
      rolls: placeholderRolls,
      isPopular: isPopular,
      isNew: isNew,
      discount: set.discountPercent,
      originalPrice: set.setPrice / (1 - set.discountPercent / 100),
    );
  }

  static String _generateDescription(String name, List<AppRoll> rolls) {
    if (rolls.isEmpty) return 'Вкусный набор роллов';
    
    final rollNames = rolls.take(3).map((r) => r.name).join(', ');
    if (rolls.length <= 3) {
      return 'Набор из ${rolls.length} роллов: $rollNames';
    } else {
      return 'Набор из ${rolls.length} роллов: $rollNames и другие';
    }
  }

  static String _getDefaultImage(String name) {
    // Используем базовое изображение для всех сетов
    // В будущем можно загружать реальные изображения из API или локальных ресурсов
    return 'https://images.pexels.com/photos/2098085/pexels-photo-2098085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'rolls': rolls.map((roll) => roll.toJson()).toList(),
      'isPopular': isPopular,
      'discount': discount,
      'originalPrice': originalPrice,
      'totalRolls': totalRolls,
    };
  }

  // Геттер для безопасного получения цены
  String get formattedPrice => '${price.toStringAsFixed(0)}₽';
  
  // Геттер для безопасного получения оригинальной цены
  String get formattedOriginalPrice => '${originalPrice.toStringAsFixed(0)}₽';
  
  // Геттер для безопасного получения скидки
  String get formattedDiscount => '${discount.toStringAsFixed(0)}%';
  
  // Геттер для проверки наличия скидки
  bool get hasDiscount => discount > 0;
  
  // Геттер для получения экономии
  double get savings => originalPrice - price;
  
  // Геттер для форматированной экономии
  String get formattedSavings => '${savings.toStringAsFixed(0)}₽';
}
