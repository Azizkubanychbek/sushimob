import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';
import '../models/excel_roll.dart';
import '../models/excel_set.dart';
import '../models/app_roll.dart';
import '../models/app_set.dart';

/// Единый сервис для загрузки данных из Excel файлов
/// Автоматически подхватывает изменения в Excel файлах
class ExcelDataService {
  static List<ExcelRoll> _excelRolls = [];
  static List<ExcelSet> _excelSets = [];
  static Map<int, List<String>> _setComposition = {};
  static bool _isInitialized = false;

  /// Инициализация - загрузка всех данных из Excel файлов
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 Загрузка данных из Excel файлов...');
      
      // Загружаем роллы
      await _loadRollsFromExcel();
      
      // Загружаем сеты
      await _loadSetsFromExcel();
      
      // Загружаем состав сетов
      await _loadSetCompositionFromExcel();
      
      _isInitialized = true;
      print('✅ Данные успешно загружены из Excel!');
      print('📊 Роллов: ${_excelRolls.length}, Сетов: ${_excelSets.length}');
      
    } catch (e) {
      print('❌ Ошибка инициализации ExcelDataService: $e');
      _loadMockData(); // Fallback на моковые данные
    }
  }

  /// Загрузка роллов из Excel файла
  static Future<void> _loadRollsFromExcel() async {
    try {
      final ByteData data = await rootBundle.load('assets/data/rolls.xlsx');
      final Uint8List bytes = data.buffer.asUint8List();
      final Excel excel = Excel.decodeBytes(bytes);
      
      _excelRolls.clear();
      
      // Ищем нужную таблицу
      for (String tableName in excel.tables.keys) {
        final table = excel.tables[tableName]!;
        
        // Пропускаем заголовок (первая строка)
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row == null || row.isEmpty) continue;
          
          try {
            // Конвертируем Data? в dynamic
            final List<dynamic> rowData = row.map((cell) => cell?.value).toList();
            
            // Проверяем что есть минимум нужные данные
            if (rowData.length >= 3 && 
                rowData[0] != null && 
                rowData[1] != null && 
                rowData[2] != null) {
              
              final roll = ExcelRoll.fromExcelRow(rowData);
              
              // Фильтруем роллы с нулевой ценой
              if (roll.salePrice > 0) {
                _excelRolls.add(roll);
              }
            }
          } catch (e) {
            print('⚠️ Ошибка парсинга строки роллов: $e');
            continue;
          }
        }
        break; // Берем первую (и обычно единственную) таблицу
      }
      
      print('📊 Загружено ${_excelRolls.length} роллов из Excel');
    } catch (e) {
      print('❌ Ошибка загрузки роллов из Excel: $e');
      throw e;
    }
  }

  /// Загрузка сетов из Excel файла
  static Future<void> _loadSetsFromExcel() async {
    try {
      final ByteData data = await rootBundle.load('assets/data/sets.xlsx');
      final Uint8List bytes = data.buffer.asUint8List();
      final Excel excel = Excel.decodeBytes(bytes);
      
      _excelSets.clear();
      
      for (String tableName in excel.tables.keys) {
        final table = excel.tables[tableName]!;
        
        // Пропускаем заголовок
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row == null || row.isEmpty) continue;
          
          try {
            final List<dynamic> rowData = row.map((cell) => cell?.value).toList();
            
            if (rowData.length >= 8 && rowData[0] != null) {
              final set = ExcelSet.fromExcelRow(rowData);
              _excelSets.add(set);
            }
          } catch (e) {
            print('⚠️ Ошибка парсинга строки сетов: $e');
            continue;
          }
        }
        break;
      }
      
      print('🎁 Загружено ${_excelSets.length} сетов из Excel');
    } catch (e) {
      print('❌ Ошибка загрузки сетов из Excel: $e');
      throw e;
    }
  }

  /// Загрузка состава сетов из Excel файла
  static Future<void> _loadSetCompositionFromExcel() async {
    try {
      final ByteData data = await rootBundle.load('assets/data/set_composition.xlsx');
      final Uint8List bytes = data.buffer.asUint8List();
      final Excel excel = Excel.decodeBytes(bytes);
      
      _setComposition.clear();
      
      for (String tableName in excel.tables.keys) {
        final table = excel.tables[tableName]!;
        
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row == null || row.isEmpty) continue;
          
          try {
            final List<dynamic> rowData = row.map((cell) => cell?.value).toList();
            
            if (rowData.length >= 3 && 
                rowData[0] != null && 
                rowData[2] != null) {
              
              final setId = rowData[0] is int ? rowData[0] : int.tryParse(rowData[0].toString());
              final rollName = rowData[2]?.toString();
              
              if (setId != null && rollName != null && rollName.isNotEmpty) {
                if (!_setComposition.containsKey(setId)) {
                  _setComposition[setId] = [];
                }
                _setComposition[setId]!.add(rollName);
              }
            }
          } catch (e) {
            print('⚠️ Ошибка парсинга состава сетов: $e');
            continue;
          }
        }
        break;
      }
      
      print('🔗 Загружен состав сетов: ${_setComposition.length} сетов');
    } catch (e) {
      print('❌ Ошибка загрузки состава сетов: $e');
      throw e;
    }
  }

  /// Получить все роллы в формате AppRoll
  static Future<List<AppRoll>> getRolls() async {
    await initialize();
    
    final appRolls = <AppRoll>[];
    for (int i = 0; i < _excelRolls.length; i++) {
      final excelRoll = _excelRolls[i];
      final rollData = excelRoll.toAppRoll(); // Removed unsupported parameters
      
      appRolls.add(AppRoll(
        id: rollData['id'] ?? 0,
        name: rollData['name'] ?? '',
        price: (rollData['price'] ?? 0.0).toDouble(),
        description: rollData['description'] ?? '',
        imageUrl: rollData['imageUrl'] ?? '',
        category: rollData['category'] ?? 'Роллы',
        isPopular: rollData['isPopular'] ?? false,
        isNew: rollData['isNew'] ?? false,
        rating: (rollData['rating'] ?? 4.5).toDouble(),
        preparationTime: rollData['preparationTime'] ?? 15,
        originalPrice: (rollData['originalPrice'] ?? 0.0).toDouble(),
        discount: (rollData['discount'] ?? 0.0).toDouble(),
      ));
    }
    
    return appRolls;
  }

  /// Получить популярные роллы
  static Future<List<AppRoll>> getPopularRolls() async {
    final allRolls = await getRolls();
    return allRolls.where((roll) => roll.isPopular).toList();
  }

  /// Получить новые роллы
  static Future<List<AppRoll>> getNewRolls() async {
    final allRolls = await getRolls();
    return allRolls.where((roll) => roll.isNew).toList();
  }

  /// Получить все сеты в формате AppSet
  static Future<List<AppSet>> getSets() async {
    await initialize();
    
    final appSets = <AppSet>[];
    for (final excelSet in _excelSets) {
      final rollNames = _setComposition[excelSet.id] ?? [];
      final setWithRolls = excelSet.withRolls(rollNames);
      final setData = setWithRolls.toAppSet();
      
      // Находим роллы для этого сета
      final setRolls = <AppRoll>[];
      final allRolls = await getRolls();
      
      for (final rollName in rollNames) {
        final matchingRoll = allRolls.firstWhere(
          (roll) => roll.name.toLowerCase() == rollName.toLowerCase(),
          orElse: () => AppRoll(
            id: 0,
            name: rollName,
            price: 100,
            description: 'Ролл "$rollName"',
            imageUrl: 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            category: 'Роллы',
            isPopular: false, // Added missing parameter
            isNew: false, // Added missing parameter
          ),
        );
        setRolls.add(matchingRoll);
      }
      
      final appSet = AppSet(
        id: setData['id'],
        name: setData['name'],
        description: setData['description'],
        price: setData['price'],
        imageUrl: setData['imageUrl'],
        rolls: setRolls,
        isPopular: setData['isPopular'],
        discount: setData['discount'],
        originalPrice: setData['originalPrice'],
      );
      
      appSets.add(appSet);
    }
    
    return appSets;
  }

  /// Получить популярные сеты
  static Future<List<AppSet>> getPopularSets() async {
    final allSets = await getSets();
    return allSets.where((set) => set.isPopular).toList();
  }

  /// Поиск роллов по названию
  static Future<List<AppRoll>> searchRolls(String query) async {
    final allRolls = await getRolls();
    return allRolls.where((roll) => 
      roll.name.toLowerCase().contains(query.toLowerCase()) ||
      roll.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Получить ролл по ID
  static Future<AppRoll?> getRollById(int id) async {
    final allRolls = await getRolls();
    try {
      return allRolls.firstWhere((roll) => roll.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить сет по ID
  static Future<AppSet?> getSetById(int id) async {
    final allSets = await getSets();
    try {
      return allSets.firstWhere((set) => set.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить статистику
  static Future<Map<String, dynamic>> getStats() async {
    await initialize();
    
    final allRolls = await getRolls();
    final allSets = await getSets();
    
    return {
      'totalRolls': allRolls.length,
      'totalSets': allSets.length,
      'popularRolls': allRolls.where((r) => r.isPopular).length,
      'popularSets': allSets.where((s) => s.isPopular).length,
      'averageRollPrice': allRolls.isNotEmpty 
        ? allRolls.map((r) => r.price).reduce((a, b) => a + b) / allRolls.length 
        : 0.0,
      'averageSetPrice': allSets.isNotEmpty 
        ? allSets.map((s) => s.price).reduce((a, b) => a + b) / allSets.length 
        : 0.0,
    };
  }

  /// Определение популярности ролла
  static bool _isPopularRoll(String name, int position) {
    final popularNames = [
      'филадельфия', 'калифорния', 'лосось темпура', 'острый лосось',
      'курица темпура', 'сладкий ролл', 'запеч магистр', 'запеч фила'
    ];
    
    return popularNames.any((popular) => 
      name.toLowerCase().contains(popular.toLowerCase())
    ) || position < 8; // Первые 8 роллов тоже популярные
  }

  /// Определение новизны ролла
  static bool _isNewRoll(String name, int position) {
    final newNames = [
      'темпура', 'запеч', 'спешл', 'премиум', 'магистр'
    ];
    
    return newNames.any((newWord) => 
      name.toLowerCase().contains(newWord.toLowerCase())
    ) || position >= _excelRolls.length - 5; // Последние 5 роллов новые
  }

  /// Загрузка резервных данных в случае ошибки
  static void _loadMockData() {
    print('⚠️ Загружаются резервные данные...');
    
    _excelRolls = [
      ExcelRoll(id: 1, name: 'Филадельфия', salePrice: 250),
      ExcelRoll(id: 2, name: 'Калифорния', salePrice: 200),
      ExcelRoll(id: 3, name: 'Лосось темпура', salePrice: 280),
    ];
    
    _excelSets = [
      ExcelSet(
        id: 1, name: 'Классический', costPrice: 400, retailPrice: 800,
        setPrice: 650, discountPercent: 19, grossProfit: 250, marginPercent: 200,
      ),
    ];
    
    _setComposition = {
      1: ['Филадельфия', 'Калифорния', 'Лосось темпура'],
    };
    
    _isInitialized = true;
  }

  /// Обновить данные (для hot reload)
  static Future<void> refresh() async {
    _isInitialized = false;
    _excelRolls.clear();
    _excelSets.clear();
    _setComposition.clear();
    await initialize();
  }
}
