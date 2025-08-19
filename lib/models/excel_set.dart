class ExcelSet {
  final int id;
  final String name;
  final double costPrice;
  final double retailPrice;
  final double setPrice;
  final double discountPercent;
  final double grossProfit;
  final double marginPercent;
  final List<String> rollNames;

  ExcelSet({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.retailPrice,
    required this.setPrice,
    required this.discountPercent,
    required this.grossProfit,
    required this.marginPercent,
    this.rollNames = const [],
  });

  factory ExcelSet.fromExcelRow(List<dynamic> row) {
    if (row.length < 8) {
      throw ArgumentError('Excel row must have at least 8 columns for set data');
    }

    final id = row[0] is int ? row[0] : int.tryParse(row[0]?.toString() ?? '0') ?? 0;
    final name = row[1]?.toString() ?? '';
    final costPrice = row[2] is double ? row[2] : double.tryParse(row[2]?.toString() ?? '0') ?? 0.0;
    final retailPrice = row[3] is double ? row[3] : double.tryParse(row[3]?.toString() ?? '0') ?? 0.0;
    final setPrice = row[4] is double ? row[4] : double.tryParse(row[4]?.toString() ?? '0') ?? 0.0;
    final discountPercent = row[5] is double ? row[5] : double.tryParse(row[5]?.toString() ?? '0') ?? 0.0;
    final grossProfit = row[6] is double ? row[6] : double.tryParse(row[6]?.toString() ?? '0') ?? 0.0;
    final marginPercent = row[7] is double ? row[7] : double.tryParse(row[7]?.toString() ?? '0') ?? 0.0;

    return ExcelSet(
      id: id,
      name: name,
      costPrice: costPrice,
      retailPrice: retailPrice,
      setPrice: setPrice,
      discountPercent: discountPercent,
      grossProfit: grossProfit,
      marginPercent: marginPercent,
    );
  }

  // Добавление роллов к сету
  ExcelSet withRolls(List<String> rollNames) {
    return ExcelSet(
      id: id,
      name: name,
      costPrice: costPrice,
      retailPrice: retailPrice,
      setPrice: setPrice,
      discountPercent: discountPercent,
      grossProfit: grossProfit,
      marginPercent: marginPercent,
      rollNames: rollNames,
    );
  }

  // Конвертация в AppSet для отображения
  Map<String, dynamic> toAppSet() {
    return {
      'id': id,
      'name': name.isNotEmpty ? name : 'Сет $id',
      'description': _generateDescription(name),
      'price': setPrice,
      'originalPrice': retailPrice,
      'discount': discountPercent,
      'imageUrl': _getDefaultImage(name),
      'isPopular': _isPopular(),
      'totalRolls': rollNames.length,
      'rollNames': rollNames,
      'formattedPrice': '${setPrice.toStringAsFixed(0)}₽',
      'formattedOriginalPrice': '${retailPrice.toStringAsFixed(0)}₽',
      'formattedDiscount': '${discountPercent.toStringAsFixed(0)}%',
      'hasDiscount': discountPercent > 0,
      'savings': retailPrice - setPrice,
      'formattedSavings': '${(retailPrice - setPrice).toStringAsFixed(0)}₽',
    };
  }

  String _generateDescription(String name) {
    if (name.isEmpty) return 'Вкусный набор роллов';
    
    final descriptions = {
      'классический': 'Популярные роллы для знакомства с японской кухней',
      'бюджетный': 'Доступный набор для экономных гурманов',
      'темпура': 'Хрустящие роллы в темпуре',
      'запечённый': 'Теплые запеченные роллы',
      'фила премиум': 'Премиальные роллы с лососем',
      'хит комбо': 'Самые популярные роллы в одном наборе',
      'party mix': 'Большой набор для вечеринки',
      'для компании': 'Идеальный выбор для компании друзей',
      'anteyko': 'Эксклюзивный набор от шеф-повара',
      'набор на двоих': 'Романтический набор для двоих',
      'набор на троих': 'Семейный набор на троих',
      'chill на филармонии': 'Особый набор для культурного вечера',
    };
    
    return descriptions[name.toLowerCase()] ?? 'Вкусный набор роллов "$name"';
  }

  String _getDefaultImage(String name) {
    final specialImages = {
      'классический': 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'бюджетный': 'https://images.pexels.com/photos/248444/pexels-photo-248444.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'темпура': 'https://images.pexels.com/photos/2098080/pexels-photo-2098080.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'запечённый': 'https://images.pexels.com/photos/2097090/pexels-photo-2097090.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'фила премиум': 'https://images.pexels.com/photos/248444/pexels-photo-248444.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'party mix': 'https://images.pexels.com/photos/2098085/pexels-photo-2098085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    };
    
    return specialImages[name.toLowerCase()] ?? 'https://images.pexels.com/photos/2098085/pexels-photo-2098085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
  }

  bool _isPopular() {
    // Сеты со скидкой больше 20% или дорогие (выше 2000₽) считаются популярными
    return discountPercent > 20 || setPrice > 2000;
  }

  @override
  String toString() {
    return 'ExcelSet(id: $id, name: $name, setPrice: $setPrice, discountPercent: $discountPercent, rollsCount: ${rollNames.length})';
  }
}
