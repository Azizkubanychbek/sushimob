import '../models/app_roll.dart';
import '../models/app_set.dart';
import 'api_service.dart';

/// Сервис для работы с суши через API
/// Заменяет SushiDataService и CsvDataService
class ApiSushiService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 Инициализация ApiSushiService...');
      // API сервис не требует специальной инициализации
      _isInitialized = true;
      print('✅ ApiSushiService инициализирован успешно');
    } catch (e) {
      print('❌ Ошибка инициализации ApiSushiService: $e');
      rethrow;
    }
  }

  /// Получить все роллы
  static Future<List<AppRoll>> getRolls() async {
    await initialize();
    try {
      final rolls = await ApiService.getRolls();
      return rolls.map((roll) => roll.toAppRoll()).toList();
    } catch (e) {
      print('❌ Ошибка получения роллов через API: $e');
      return [];
    }
  }

  /// Получить популярные роллы
  static Future<List<AppRoll>> getPopularRolls() async {
    await initialize();
    try {
      final rolls = await ApiService.getRolls();
      // Фильтруем популярные роллы
      final popularRolls = rolls.where((roll) => roll.isPopular).toList();
      
      // Если популярных роллов нет, возвращаем все роллы
      if (popularRolls.isEmpty) {
        print('⚠️ Популярных роллов нет, возвращаем все роллы');
        return rolls.map((roll) => roll.toAppRoll()).toList();
      }
      
      return popularRolls.map((roll) => roll.toAppRoll()).toList();
    } catch (e) {
      print('❌ Ошибка получения популярных роллов через API: $e');
      return [];
    }
  }

  /// Получить новые роллы
  static Future<List<AppRoll>> getNewRolls() async {
    await initialize();
    try {
      final rolls = await ApiService.getRolls();
      // Фильтруем новые роллы
      final newRolls = rolls.where((roll) => roll.isNew).toList();
      
      // Если новых роллов нет, возвращаем все роллы
      if (newRolls.isEmpty) {
        print('⚠️ Новых роллов нет, возвращаем все роллы');
        return rolls.map((roll) => roll.toAppRoll()).toList();
      }
      
      return newRolls.map((roll) => roll.toAppRoll()).toList();
    } catch (e) {
      print('❌ Ошибка получения новых роллов через API: $e');
      return [];
    }
  }

  /// Получить все сеты
  static Future<List<AppSet>> getSets() async {
    await initialize();
    try {
      final sets = await ApiService.getSets();
      return sets.map((set) => set.toAppSet()).toList();
    } catch (e) {
      print('❌ Ошибка получения сетов через API: $e');
      return [];
    }
  }

  /// Получить популярные сеты
  static Future<List<AppSet>> getPopularSets() async {
    await initialize();
    try {
      final sets = await ApiService.getSets();
      // Фильтруем популярные сеты
      final popularSets = sets.where((set) => set.isPopular).toList();
      
      // Если популярных сетов нет, возвращаем все сеты
      if (popularSets.isEmpty) {
        print('⚠️ Популярных сетов нет, возвращаем все сеты');
        return sets.map((set) => set.toAppSet()).toList();
      }
      
      return popularSets.map((set) => set.toAppSet()).toList();
    } catch (e) {
      print('❌ Ошибка получения популярных сетов через API: $e');
      return [];
    }
  }

  /// Получить ролл по ID
  static Future<AppRoll?> getRollById(int id) async {
    await initialize();
    try {
      final roll = await ApiService.getRollDetails(id);
      return roll.toAppRoll();
    } catch (e) {
      print('❌ Ошибка получения ролла по ID через API: $e');
      return null;
    }
  }

  /// Получить сет по ID
  static Future<AppSet?> getSetById(int id) async {
    await initialize();
    try {
      final sets = await ApiService.getSets();
      final set = sets.firstWhere((set) => set.id == id);
      return set.toAppSet();
    } catch (e) {
      print('❌ Ошибка получения сета по ID через API: $e');
      return null;
    }
  }

  /// Поиск роллов
  static Future<List<AppRoll>> searchRolls(String query) async {
    await initialize();
    try {
      final rolls = await ApiService.getRolls();
      final filteredRolls = rolls.where((roll) => 
        roll.name.toLowerCase().contains(query.toLowerCase()) ||
        roll.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
      return filteredRolls.map((roll) => roll.toAppRoll()).toList();
    } catch (e) {
      print('❌ Ошибка поиска роллов через API: $e');
      return [];
    }
  }

  /// Получить роллы по категории
  static Future<List<AppRoll>> getRollsByCategory(String category) async {
    final allRolls = await getRolls();
    return allRolls.where((roll) => 
      roll.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  /// Получить дополнительные товары (соусы, напитки)
  static Future<List<Map<String, dynamic>>> getOtherItems() async {
    await initialize();
    try {
      return await ApiService.getOtherItems();
    } catch (e) {
      print('❌ Ошибка получения дополнительных товаров через API: $e');
      return [];
    }
  }

  /// Получить товары по категории (соусы, напитки)
  static Future<List<Map<String, dynamic>>> getOtherItemsByCategory(String category) async {
    await initialize();
    try {
      return await ApiService.getOtherItemsByCategory(category);
    } catch (e) {
      print('❌ Ошибка получения товаров категории $category через API: $e');
      return [];
    }
  }

  /// Получить статистику
  static Future<Map<String, dynamic>> getStats() async {
    await initialize();
    try {
      final rolls = await getRolls();
      final sets = await getSets();
      final otherItems = await getOtherItems();
      
      return {
        'total_rolls': rolls.length,
        'total_sets': sets.length,
        'total_other_items': otherItems.length,
        'popular_rolls': rolls.where((r) => r.isPopular).length,
        'new_rolls': rolls.where((r) => r.isNew).length,
      };
    } catch (e) {
      print('❌ Ошибка получения статистики через API: $e');
      return {};
    }
  }

  /// Получить состав сета
  static Future<List<Map<String, dynamic>>> getSetComposition(int setId) async {
    await initialize();
    try {
      final response = await ApiService.getSetComposition(setId);
      return List<Map<String, dynamic>>.from(response['composition'] ?? []);
    } catch (e) {
      print('❌ Ошибка загрузки состава сета: $e');
      // Возвращаем пустой список вместо ошибки
      return [];
    }
  }

  /// Обновить данные (для hot reload)
  static Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }
}
