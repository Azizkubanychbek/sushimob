import 'roll.dart';

class AppRoll {
  final int id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final bool isPopular;
  final bool isNew;
  final double rating;
  final int preparationTime;
  final double originalPrice;
  final double discount;

  AppRoll({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.isPopular = false,
    this.isNew = false,
    this.rating = 4.5,
    this.preparationTime = 15,
    this.originalPrice = 0.0,
    this.discount = 0.0,
  });

  // Создание AppRoll из Roll (вашей бизнес-модели)
  factory AppRoll.fromRoll(Roll roll, {bool isPopular = false, bool isNew = false}) {
    // Проверяем все поля на null и пустые значения
    final safeName = roll.name.isNotEmpty ? roll.name : 'Ролл ${roll.id}';
    final safePrice = roll.salePrice > 0 ? roll.salePrice : 100.0;
    final safeDescription = roll.description.isNotEmpty ? roll.description : _generateDescription(safeName);
    final safeImageUrl = roll.imageUrl.isNotEmpty ? roll.imageUrl : _getDefaultImage(safeName);
    
    return AppRoll(
      id: roll.id,
      name: safeName,
      price: safePrice,
      description: safeDescription,
      imageUrl: safeImageUrl,
      category: 'Роллы',
      isPopular: roll.isPopular || isPopular,
      isNew: roll.isNew || isNew,
      rating: 4.5 + (roll.id % 5) * 0.1,
      preparationTime: 15 + (roll.id % 10),
      originalPrice: safePrice,
      discount: 0.0,
    );
  }

  static String _generateDescription(String name) {
    if (name.isEmpty) return 'Свежий ролл - один из наших популярных роллов';
    
    // Генерируем описание на основе названия ролла
    final descriptions = {
      'Калифорния': 'Классический ролл с крабом, авокадо и огурцом',
      'филадельфия': 'Премиум ролл с лососем и сливочным сыром',
      'сладкий ролл': 'Необычный десертный ролл с фруктами',
      'чикен маки': 'Популярный ролл с курицей и овощами',
      'острый лосось': 'Острый ролл с лососем и специями',
      'лосось темпура': 'Хрустящий ролл с лососем в темпуре',
      'курица темпура': 'Хрустящий ролл с курицей в темпуре',
      'угорь темпура': 'Экзотический ролл с угрем в темпуре',
      'копченная фила': 'Ролл с копченым лососем',
      'фила спешл': 'Специальный ролл с лососем',
      'запеч магистр': 'Запеченный ролл "Магистр"',
      'запеч фила': 'Запеченный ролл с лососем',
      'саке маки': 'Классический маки с лососем',
      'унаги запеч': 'Запеченный ролл с угрем',
      'овощьной ролл': 'Легкий овощной ролл',
      'чикаго ролл': 'Американский ролл "Чикаго"',
      'маки курица': 'Маки с курицей',
      'фила с угрем': 'Ролл с лососем и угрем',
      'чедр ролл': 'Ролл с сыром чеддер',
      'мини рол огурец': 'Мини ролл с огурцом',
    };
    
    return descriptions[name] ?? 'Свежий ролл "$name" - один из наших популярных роллов';
  }

  static String _getDefaultImage(String name) {
    // Используем базовое изображение для всех роллов
    // В будущем можно загружать реальные изображения из API или локальных ресурсов
    return 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'isPopular': isPopular,
      'isNew': isNew,
      'rating': rating,
      'preparationTime': preparationTime,
      'originalPrice': originalPrice,
      'discount': discount,
    };
  }

  // Геттер для безопасного получения цены
  String get formattedPrice => '${price.toStringAsFixed(0)}₽';
  
  // Геттер для безопасного получения рейтинга
  String get formattedRating => rating.toStringAsFixed(1);
  
  // Геттер для безопасного получения времени приготовления
  String get formattedPreparationTime => '${preparationTime} мин';
}
