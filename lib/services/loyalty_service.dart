import '../models/loyalty_card.dart';
import '../models/loyalty_roll.dart';
import '../models/loyalty_card_usage.dart';
import 'api_service.dart';

class LoyaltyService {
  static List<LoyaltyCard> _cards = [];
  static List<LoyaltyRoll> _availableRolls = [];
  static List<LoyaltyCardUsage> _history = [];
  static bool _isLoading = false;

  // Геттеры
  static List<LoyaltyCard> get cards => _cards;
  static List<LoyaltyRoll> get availableRolls => _availableRolls;
  static List<LoyaltyCardUsage> get history => _history;
  static bool get isLoading => _isLoading;

  // Получение накопительных карт
  static Future<void> loadCards() async {
    try {
      _isLoading = true;
      final response = await ApiService.getLoyaltyCards();
      
      if (response['success']) {
        _cards = (response['cards'] as List)
            .map((json) => LoyaltyCard.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Ошибка загрузки накопительных карт: $e');
      _cards = [];
    } finally {
      _isLoading = false;
    }
  }

  // Получение доступных роллов
  static Future<void> loadAvailableRolls() async {
    try {
      _isLoading = true;
      final response = await ApiService.getAvailableLoyaltyRolls();
      
      if (response['success']) {
        _availableRolls = (response['rolls'] as List)
            .map((json) => LoyaltyRoll.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Ошибка загрузки доступных роллов: $e');
      _availableRolls = [];
    } finally {
      _isLoading = false;
    }
  }

  // Получение истории использования
  static Future<void> loadHistory() async {
    try {
      _isLoading = true;
      final response = await ApiService.getLoyaltyHistory();
      
      if (response['success']) {
        _history = (response['history'] as List)
            .map((json) => LoyaltyCardUsage.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Ошибка загрузки истории: $e');
      _history = [];
    } finally {
      _isLoading = false;
    }
  }

  // Использование накопительной карты
  static Future<bool> useCard(int cardId, int rollId) async {
    try {
      _isLoading = true;
      final response = await ApiService.useLoyaltyCard(
        cardId: cardId,
        rollId: rollId,
      );
      
      if (response['success']) {
        // Обновляем локальные данные
        await loadCards();
        await loadHistory();
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка использования карты: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Получение заполненных карт
  static List<LoyaltyCard> get completedCards {
    return _cards.where((card) => card.isCompleted).toList();
  }

  // Получение карт в процессе
  static List<LoyaltyCard> get inProgressCards {
    return _cards.where((card) => !card.isCompleted).toList();
  }

  // Общий прогресс пользователя
  static double get totalProgress {
    if (_cards.isEmpty) return 0.0;
    
    double totalProgress = 0.0;
    for (var card in _cards) {
      totalProgress += card.progressPercent;
    }
    
    return totalProgress / _cards.length;
  }

  // Количество использованных карт
  static int get usedCardsCount {
    return _history.length;
  }

  // Обновление всех данных
  static Future<void> refreshAll() async {
    await Future.wait([
      loadCards(),
      loadAvailableRolls(),
      loadHistory(),
    ]);
  }

  // Очистка кэша
  static void clearCache() {
    _cards.clear();
    _availableRolls.clear();
    _history.clear();
  }
}
