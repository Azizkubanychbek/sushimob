class ExcelRoll {
  final int id;
  final String name;
  final double salePrice;
  final double? cost;
  final String description;
  final String category;
  final String ingredients;
  final String imageUrl;
  final bool isPopular;
  final bool isNew;

  ExcelRoll({
    required this.id,
    required this.name,
    required this.salePrice,
    this.cost,
    this.description = '',
    this.category = 'Роллы',
    this.ingredients = '',
    this.imageUrl = '',
    this.isPopular = false,
    this.isNew = false,
  });

  factory ExcelRoll.fromExcelRow(List<dynamic> row) {
    if (row.length < 3) {
      throw ArgumentError('Excel row must have at least 3 columns: id, name, sale_price');
    }

    final id = row[0] is int ? row[0] : int.tryParse(row[0]?.toString() ?? '0') ?? 0;
    final name = row[1]?.toString() ?? '';
    final salePrice = row[2] is double 
        ? row[2] 
        : double.tryParse(row[2]?.toString() ?? '0') ?? 0.0;
    final cost = row.length > 3 
        ? (row[3] is double ? row[3] : double.tryParse(row[3]?.toString() ?? '0'))
        : null;
    
    // Новые поля из расширенного CSV
    final description = row.length > 4 ? (row[4]?.toString() ?? '') : '';
    final category = row.length > 5 ? (row[5]?.toString() ?? 'Роллы') : 'Роллы';
    final ingredients = row.length > 6 ? (row[6]?.toString() ?? '') : '';
    final imageUrl = row.length > 7 ? (row[7]?.toString() ?? '') : '';
    final isPopular = row.length > 8 ? (row[8]?.toString() == '1') : false;
    final isNew = row.length > 9 ? (row[9]?.toString() == '1') : false;

    return ExcelRoll(
      id: id,
      name: name,
      salePrice: salePrice,
      cost: cost,
      description: description,
      category: category,
      ingredients: ingredients,
      imageUrl: imageUrl,
      isPopular: isPopular,
      isNew: isNew,
    );
  }

  // Конвертация в AppRoll для отображения
  toAppRoll({bool? overridePopular, bool? overrideNew}) {
    return {
      'id': id,
      'name': name.isNotEmpty ? name : 'Ролл $id',
      'price': salePrice,
      'description': description.isNotEmpty ? description : _generateDescription(name),
      'imageUrl': imageUrl.isNotEmpty ? imageUrl : _getDefaultImage(name),
      'category': category,
      'ingredients': ingredients,
      'isPopular': overridePopular ?? isPopular,
      'isNew': overrideNew ?? isNew,
      'rating': 4.0 + (id % 10) * 0.1, // Рейтинг 4.0-4.9
      'preparationTime': 10 + (id % 15), // Время 10-25 минут
      'originalPrice': salePrice,
      'discount': 0.0,
    };
  }

  static String _generateDescription(String name) {
    if (name.isEmpty) return 'Свежий ролл - один из наших популярных роллов';
    
    final descriptions = {
      'Калифорния': 'Классический ролл с крабом, авокадо и огурцом',
      'Филадельфия': 'Премиум ролл с лососем и сливочным сыром',
      'Каппа маки': 'Легкий ролл с огурцом',
      'Унаги маки': 'Ролл с угрем и кунжутом',
      'Крабовый ролл': 'Ролл с крабовыми палочками и сыром',
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
      'мини ролл огурец': 'Мини ролл с огурцом',
    };
    
    return descriptions[name.toLowerCase()] ?? 'Свежий ролл "$name" - один из наших популярных роллов';
  }

  static String _getDefaultImage(String name) {
    final specialImages = {
      'калифорния': 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'филадельфия': 'https://images.pexels.com/photos/248444/pexels-photo-248444.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'сладкий ролл': 'https://images.pexels.com/photos/2098085/pexels-photo-2098085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'острый лосось': 'https://images.pexels.com/photos/2097090/pexels-photo-2097090.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'лосось темпура': 'https://images.pexels.com/photos/2098080/pexels-photo-2098080.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    };
    
    return specialImages[name.toLowerCase()] ?? 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
  }

  @override
  String toString() {
    return 'ExcelRoll(id: $id, name: $name, salePrice: $salePrice, cost: $cost, category: $category, isPopular: $isPopular, isNew: $isNew)';
  }
}
