import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/excel_roll.dart';
import '../models/excel_set.dart';
import '../models/app_roll.dart';
import '../models/app_set.dart';

/// Упрощенный сервис для загрузки данных из CSV файлов
/// Работает стабильно и быстро
class CsvDataService {
  static List<ExcelRoll> _excelRolls = [];
  static List<ExcelSet> _excelSets = [];
  static Map<int, List<String>> _setComposition = {};
  static bool _isInitialized = false;

  /// Инициализация - загрузка всех данных из CSV файлов
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 Загрузка данных из CSV файлов...');
      
      // Загружаем роллы
      await _loadRollsFromCsv();
      
      // Загружаем сеты
      await _loadSetsFromCsv();
      
      // Загружаем состав сетов
      await _loadSetCompositionFromCsv();
      
      _isInitialized = true;
      print('✅ Данные успешно загружены из CSV!');
      print('📊 Роллов: ${_excelRolls.length}, Сетов: ${_excelSets.length}');
      
    } catch (e) {
      print('❌ Ошибка инициализации CsvDataService: $e');
      print('💡 Убедитесь, что CSV файлы находятся в папке assets/data/');
      rethrow; // Пробрасываем ошибку дальше вместо загрузки мок данных
    }
  }

  /// Загрузка роллов из CSV файла
  static Future<void> _loadRollsFromCsv() async {
    try {
      final csvData = await rootBundle.loadString('assets/data/rolls.csv');
      final List<List<dynamic>> csvList = const CsvToListConverter(fieldDelimiter: ';').convert(csvData);
      
      _excelRolls.clear();
      
      // Пропускаем заголовок (первая строка)
      for (int i = 1; i < csvList.length; i++) {
        final row = csvList[i];
        if (row.length < 3) continue;
        
        try {
          final idStr = row[0]?.toString() ?? '';
          final nameStr = row[1]?.toString() ?? '';
          final priceStr = row[2]?.toString() ?? '';
          
          if (idStr.isEmpty || nameStr.isEmpty) continue;
          
          final id = int.tryParse(idStr) ?? i;
          final name = nameStr.trim();
          final price = double.tryParse(priceStr) ?? 0.0;
          
          // Загружаем дополнительные поля
          final cost = row.length > 3 ? double.tryParse(row[3]?.toString() ?? '') : null;
          final description = row.length > 4 ? (row[4]?.toString() ?? '').trim() : '';
          final category = row.length > 5 ? (row[5]?.toString() ?? 'Роллы').trim() : 'Роллы';
          final ingredients = row.length > 6 ? (row[6]?.toString() ?? '').trim() : '';
          final imageUrl = row.length > 7 ? (row[7]?.toString() ?? '').trim() : '';
          final isPopular = row.length > 8 ? (row[8]?.toString().trim() == '1') : false;
          final isNew = row.length > 9 ? (row[9]?.toString().trim() == '1') : false;
          
          final roll = ExcelRoll(
            id: id,
            name: name,
            salePrice: price,
            cost: cost,
            description: description,
            category: category,
            ingredients: ingredients,
            imageUrl: imageUrl,
            isPopular: isPopular,
            isNew: isNew,
          );
          _excelRolls.add(roll);
        } catch (e) {
          print('⚠️ Ошибка парсинга строки роллов: $e');
          continue;
        }
      }
      
      print('📊 Загружено ${_excelRolls.length} роллов из CSV');
      if (_excelRolls.isNotEmpty) {
        print('🔍 DEBUG: Первый ролл: ${_excelRolls.first.name} - ${_excelRolls.first.salePrice}');
      }
    } catch (e) {
      print('❌ Ошибка загрузки роллов из CSV: $e');
      throw e;
    }
  }

  /// Загрузка сетов из CSV файла
  static Future<void> _loadSetsFromCsv() async {
    try {
      final csvData = await rootBundle.loadString('assets/data/sets.csv');
      final List<List<dynamic>> csvList = const CsvToListConverter(fieldDelimiter: ',').convert(csvData);
      
      _excelSets.clear();
      
      // Пропускаем заголовок
      for (int i = 1; i < csvList.length; i++) {
        final row = csvList[i];
        if (row.length < 8) continue;
        
        try {
          final idStr = row[0]?.toString() ?? '';
          final nameStr = row[1]?.toString() ?? '';
          final costPriceStr = row[2]?.toString() ?? '';
          final retailPriceStr = row[3]?.toString() ?? '';
          final setPriceStr = row[4]?.toString() ?? '';
          final discountStr = row[5]?.toString() ?? '';
          
          if (idStr.isEmpty || nameStr.isEmpty || setPriceStr.isEmpty) continue;
          
          final id = int.tryParse(idStr) ?? i;
          final name = nameStr.trim();
          final costPrice = double.tryParse(costPriceStr) ?? 0.0;
          final retailPrice = double.tryParse(retailPriceStr) ?? 0.0;
          final setPrice = double.tryParse(setPriceStr) ?? 0.0;
          final discount = double.tryParse(discountStr) ?? 0.0;
          
          if (setPrice > 0) {
            final set = ExcelSet(
              id: id,
              name: name,
              costPrice: costPrice,
              retailPrice: retailPrice,
              setPrice: setPrice,
              discountPercent: discount,
              grossProfit: retailPrice - costPrice,
              marginPercent: 200.0, // Примерное значение
            );
            _excelSets.add(set);
          }
        } catch (e) {
          print('⚠️ Ошибка парсинга строки сетов: $e');
          continue;
        }
      }
      
      print('📊 Загружено ${_excelSets.length} сетов из CSV');
      if (_excelSets.isNotEmpty) {
        print('🔍 DEBUG: Первый сет: ${_excelSets.first.name} - ${_excelSets.first.setPrice}');
      }
    } catch (e) {
      print('❌ Ошибка загрузки сетов из CSV: $e');
      throw e;
    }
  }

  /// Загрузка состава сетов из CSV файла
  static Future<void> _loadSetCompositionFromCsv() async {
    try {
      final csvData = await rootBundle.loadString('assets/data/set_composition.csv');
      final List<List<dynamic>> csvList = const CsvToListConverter(fieldDelimiter: ',').convert(csvData);
      
      _setComposition.clear();
      
      // Пропускаем заголовок
      for (int i = 1; i < csvList.length; i++) {
        final row = csvList[i];
        if (row.length < 3) continue;
        
        try {
          final setIdStr = row[0]?.toString() ?? '';
          final rollIdStr = row[1]?.toString() ?? '';
          final rollNameStr = row[2]?.toString() ?? '';
          
          if (setIdStr.isEmpty || rollIdStr.isEmpty) continue;
          
          final setId = int.tryParse(setIdStr) ?? 0;
          final rollId = int.tryParse(rollIdStr) ?? 0;
          
          if (setId > 0 && rollId > 0) {
            if (!_setComposition.containsKey(setId)) {
              _setComposition[setId] = [];
            }
            _setComposition[setId]!.add(rollNameStr.trim());
          }
        } catch (e) {
          print('⚠️ Ошибка парсинга строки состава сета: $e');
          continue;
        }
      }
      
      print('📊 Загружен состав для ${_setComposition.length} сетов');
    } catch (e) {
      print('❌ Ошибка загрузки состава сетов из CSV: $e');
      throw e;
    }
  }

  /// Получить все роллы
  static Future<List<AppRoll>> getRolls() async {
    await initialize();
    
    final rolls = <AppRoll>[];
    
    for (final excelRoll in _excelRolls) {
      try {
        // Создаем AppRoll из ExcelRoll с реальными данными из CSV
        final appRoll = AppRoll(
          id: excelRoll.id,
          name: excelRoll.name,
          price: excelRoll.salePrice,
          description: excelRoll.description.isNotEmpty ? excelRoll.description : 'Свежий ролл "${excelRoll.name}"',
          imageUrl: excelRoll.imageUrl.isNotEmpty ? excelRoll.imageUrl : 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
          category: excelRoll.category,
          isPopular: excelRoll.isPopular,
          isNew: excelRoll.isNew,
          rating: 4.0 + (excelRoll.id % 10) * 0.1, // Рейтинг на основе ID
          preparationTime: 10 + (excelRoll.id % 15), // Время приготовления 10-25 минут
          originalPrice: excelRoll.salePrice,
          discount: 0.0,
        );
        rolls.add(appRoll);
      } catch (e) {
        print('⚠️ Ошибка создания ролла ${excelRoll.name}: $e');
        continue;
      }
    }
    
    return rolls;
  }

  /// Получить популярные роллы
  static Future<List<AppRoll>> getPopularRolls() async {
    await initialize();
    
    // Возвращаем роллы с флагом isPopular = true
    final allRolls = await getRolls();
    final popularRolls = allRolls.where((roll) => roll.isPopular).toList();
    
    // Если популярных роллов мало, добавляем первые несколько
    if (popularRolls.length < 6) {
      final additionalRolls = allRolls.where((roll) => !roll.isPopular).take(6 - popularRolls.length);
      popularRolls.addAll(additionalRolls);
    }
    
    return popularRolls.take(8).toList();
  }

  /// Получить новые роллы
  static Future<List<AppRoll>> getNewRolls() async {
    await initialize();
    
    // Возвращаем роллы с флагом isNew = true
    final allRolls = await getRolls();
    return allRolls.where((roll) => roll.isNew).take(5).toList();
  }

  /// Получить все сеты
  static Future<List<AppSet>> getSets() async {
    await initialize();
    
    final sets = <AppSet>[];
    
    for (final excelSet in _excelSets) {
      try {
        // Получаем роллы для этого сета
        final rollNames = _setComposition[excelSet.id] ?? [];
        final rolls = <AppRoll>[];
        
        // Находим роллы по названию
        for (final rollName in rollNames) {
          final roll = _excelRolls.firstWhere(
            (r) => r.name.toLowerCase() == rollName.toLowerCase(),
            orElse: () => ExcelRoll(id: 0, name: rollName, salePrice: 0.0),
          );
          
          if (roll.id > 0) {
            // Создаем AppRoll из ExcelRoll
            final appRoll = AppRoll(
              id: roll.id,
              name: roll.name,
              price: roll.salePrice,
              description: 'Ролл ${roll.name}',
              imageUrl: 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
              category: 'Роллы',
              isPopular: false,
              isNew: false,
              rating: 4.5,
              preparationTime: 15,
              originalPrice: roll.salePrice,
              discount: 0.0,
            );
            rolls.add(appRoll);
          }
        }
        
        if (rolls.isNotEmpty) {
          // Создаем AppSet из реальных данных
          final appSet = AppSet.fromExcelData(
            id: excelSet.id,
            name: excelSet.name,
            setPrice: excelSet.setPrice,
            discountPercent: excelSet.discountPercent,
            rolls: rolls,
            isPopular: excelSet.id <= 5, // Первые 5 сетов считаем популярными
          );
          sets.add(appSet);
        }
      } catch (e) {
        print('⚠️ Ошибка создания сета ${excelSet.name}: $e');
        continue;
      }
    }
    
    return sets;
  }

  /// Получить популярные сеты
  static Future<List<AppSet>> getPopularSets() async {
    await initialize();
    
    // Возвращаем первые 6 сетов как популярные
    final allSets = await getSets();
    return allSets.take(6).toList();
  }

  /// Поиск роллов по названию
  static Future<List<AppRoll>> searchRolls(String query) async {
    await initialize();
    
    if (query.isEmpty) return [];
    
    final allRolls = await getRolls();
    final lowercaseQuery = query.toLowerCase();
    
    return allRolls.where((roll) => 
      roll.name.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Получить ролл по ID
  static Future<AppRoll?> getRollById(int id) async {
    await initialize();
    
    try {
      final excelRoll = _excelRolls.firstWhere((roll) => roll.id == id);
      
      return AppRoll(
        id: excelRoll.id,
        name: excelRoll.name,
        price: excelRoll.salePrice,
        description: excelRoll.description.isNotEmpty ? excelRoll.description : 'Свежий ролл "${excelRoll.name}"',
        imageUrl: excelRoll.imageUrl.isNotEmpty ? excelRoll.imageUrl : 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
        category: excelRoll.category,
        isPopular: excelRoll.isPopular,
        isNew: excelRoll.isNew,
        rating: 4.0 + (excelRoll.id % 10) * 0.1,
        preparationTime: 10 + (excelRoll.id % 15),
        originalPrice: excelRoll.salePrice,
        discount: 0.0,
      );
    } catch (e) {
      print('⚠️ Ролл с ID $id не найден: $e');
      return null;
    }
  }

  /// Получить сет по ID
  static Future<AppSet?> getSetById(int id) async {
    await initialize();
    
    try {
      final excelSet = _excelSets.firstWhere((set) => set.id == id);
      
      // Получаем роллы для этого сета
      final rollNames = _setComposition[excelSet.id] ?? [];
      final rolls = <AppRoll>[];
      
      // Находим роллы по названию
      for (final rollName in rollNames) {
        final roll = _excelRolls.firstWhere(
          (r) => r.name.toLowerCase() == rollName.toLowerCase(),
          orElse: () => ExcelRoll(id: 0, name: rollName, salePrice: 0.0),
        );
        
        if (roll.id > 0) {
          final appRoll = AppRoll(
            id: roll.id,
            name: roll.name,
            price: roll.salePrice,
            description: 'Ролл ${roll.name}',
            imageUrl: 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            category: 'Роллы',
            isPopular: false,
            isNew: false,
            rating: 4.5,
            preparationTime: 15,
            originalPrice: roll.salePrice,
            discount: 0.0,
          );
          rolls.add(appRoll);
        }
      }
      
      if (rolls.isNotEmpty) {
        return AppSet.fromExcelData(
          id: excelSet.id,
          name: excelSet.name,
          setPrice: excelSet.setPrice,
          discountPercent: excelSet.discountPercent,
          rolls: rolls,
          isPopular: excelSet.id <= 5,
        );
      }
      
      return null;
    } catch (e) {
      print('⚠️ Сет с ID $id не найден: $e');
      return null;
    }
  }

  /// Получить статистику
  static Future<Map<String, dynamic>> getStats() async {
    await initialize();
    
    try {
      final totalRolls = _excelRolls.length;
      final totalSets = _excelSets.length;
      
      // Вычисляем среднюю цену роллов
      final totalRollPrice = _excelRolls.fold(0.0, (sum, roll) => sum + roll.salePrice);
      final averageRollPrice = totalRolls > 0 ? totalRollPrice / totalRolls : 0.0;
      
      // Вычисляем среднюю цену сетов
      final totalSetPrice = _excelSets.fold(0.0, (sum, set) => sum + set.setPrice);
      final averageSetPrice = totalSets > 0 ? totalSetPrice / totalSets : 0.0;
      
      // Находим самый дорогой ролл
      final mostExpensiveRoll = _excelRolls.isNotEmpty 
        ? _excelRolls.reduce((a, b) => a.salePrice > b.salePrice ? a : b)
        : null;
      
      // Находим самый дорогой сет
      final mostExpensiveSet = _excelSets.isNotEmpty 
        ? _excelSets.reduce((a, b) => a.setPrice > b.setPrice ? a : b)
        : null;
      
      return {
        'totalRolls': totalRolls,
        'totalSets': totalSets,
        'averageRollPrice': averageRollPrice,
        'averageSetPrice': averageSetPrice,
        'mostExpensiveRoll': mostExpensiveRoll != null ? {
          'name': mostExpensiveRoll.name,
          'price': mostExpensiveRoll.salePrice,
        } : null,
        'mostExpensiveSet': mostExpensiveSet != null ? {
          'name': mostExpensiveSet.name,
          'price': mostExpensiveSet.setPrice,
        } : null,
        'totalItems': totalRolls + totalSets,
      };
    } catch (e) {
      print('⚠️ Ошибка получения статистики: $e');
      return {
        'totalRolls': 0,
        'totalSets': 0,
        'averageRollPrice': 0.0,
        'averageSetPrice': 0.0,
        'totalItems': 0,
      };
    }
  }

  /// Получить все категории из CSV
  static Future<List<String>> getCategories() async {
    await initialize();
    
    final categories = <String>{};
    for (final roll in _excelRolls) {
      if (roll.category.isNotEmpty && roll.category != 'Соусы') {
        categories.add(roll.category);
      }
    }
    
    return categories.toList()..sort();
  }

  /// Получить роллы по категории
  static Future<List<AppRoll>> getRollsByCategory(String category) async {
    await initialize();
    
    final allRolls = await getRolls();
    return allRolls.where((roll) => 
      roll.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  /// Добавить новый сет (для будущего расширения)
  static Future<bool> addCustomSet({
    required String name,
    required String description,
    required List<AppRoll> rolls,
    double discount = 0.0,
    bool isPopular = false,
  }) async {
    try {
      // В будущем здесь можно добавить логику записи в Excel файл
      print('🎁 Добавлен новый сет: $name с ${rolls.length} роллами');
      return true;
    } catch (e) {
      print('❌ Ошибка добавления сета: $e');
      return false;
    }
  }
}
