import '../models/app_roll.dart';
import '../models/app_set.dart';
import 'csv_data_service.dart';

/// Обертка над CsvDataService для совместимости с существующим кодом
/// Теперь загружает данные из реальных CSV файлов
class SushiDataService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 Инициализация SushiDataService через CsvDataService...');
      await CsvDataService.initialize();
      _isInitialized = true;
      print('✅ SushiDataService инициализирован успешно');
    } catch (e) {
      print('❌ Ошибка инициализации SushiDataService: $e');
      rethrow;
    }
  }

  /// Получить все роллы
  static Future<List<AppRoll>> getRolls() async {
    await initialize();
    return await CsvDataService.getRolls();
  }

  /// Получить популярные роллы
  static Future<List<AppRoll>> getPopularRolls() async {
    await initialize();
    return await CsvDataService.getPopularRolls();
  }

  /// Получить новые роллы
  static Future<List<AppRoll>> getNewRolls() async {
    await initialize();
    return await CsvDataService.getNewRolls();
  }

  /// Получить все сеты
  static Future<List<AppSet>> getSets() async {
    await initialize();
    return await CsvDataService.getSets();
  }

  /// Получить популярные сеты
  static Future<List<AppSet>> getPopularSets() async {
    await initialize();
    return await CsvDataService.getPopularSets();
  }

  /// Получить ролл по ID
  static Future<AppRoll?> getRollById(int id) async {
    await initialize();
    return await CsvDataService.getRollById(id);
  }

  /// Получить сет по ID
  static Future<AppSet?> getSetById(int id) async {
    await initialize();
    return await CsvDataService.getSetById(id);
  }

  /// Поиск роллов
  static Future<List<AppRoll>> searchRolls(String query) async {
    await initialize();
    return await CsvDataService.searchRolls(query);
  }

  /// Получить роллы по категории
  static Future<List<AppRoll>> getRollsByCategory(String category) async {
    final allRolls = await getRolls();
    return allRolls.where((roll) => 
      roll.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  /// Получить статистику
  static Future<Map<String, dynamic>> getStats() async {
    await initialize();
    return await CsvDataService.getStats();
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

  /// Обновить данные (для hot reload)
  static Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }
}