import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiUserService {
  static final ApiUserService _instance = ApiUserService._internal();
  factory ApiUserService() => _instance;
  ApiUserService._internal();

  static const String _baseUrl = 'http://localhost:5002/api'; // Localhost для разработки
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // Получение всех пользователей (отладка)
  Future<List<User>> getAllUsers() async {
    try {
      print('🌐 API: Запрашиваем всех пользователей...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/debug/users'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final usersList = jsonData['users'] as List<dynamic>;
        final users = usersList.map((userData) => User.fromJson(userData)).toList();
        
        print('✅ API: Получено ${users.length} пользователей');
        return users;
      } else {
        print('❌ API: Ошибка ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ API: Ошибка сети: $e');
      return [];
    }
  }

  // Регистрация пользователя
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    try {
      print('🌐 API: Регистрация пользователя $email...');
      
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      };
      
      if (referralCode != null && referralCode.isNotEmpty) {
        requestBody['referral_code'] = referralCode;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      final jsonData = jsonDecode(response.body);
      print('📡 API ответ: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        print('✅ API: Пользователь $email успешно зарегистрирован');
        print('👤 Данные пользователя: ${jsonData['user']}');
        print('🔑 Токен: ${jsonData['access_token']?.substring(0, 20)}...');
        
        final user = User.fromJson(jsonData['user']);
        print('👤 Создан объект User: ${user.name} (${user.email})');
        
        return {
          'success': true,
          'user': user,
          'access_token': jsonData['access_token'],
          'message': jsonData['message'],
        };
      } else {
        print('❌ API: Ошибка регистрации: ${jsonData['error']}');
        return {
          'success': false,
          'error': jsonData['error'],
        };
      }
    } catch (e) {
      print('❌ API: Ошибка сети при регистрации: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Вход пользователя
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      print('🌐 API: Вход пользователя $email...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final jsonData = jsonDecode(response.body);
      print('📡 API ответ на вход: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ API: Пользователь $email успешно вошел');
        print('👤 Данные пользователя: ${jsonData['user']}');
        print('🔑 Токен: ${jsonData['access_token']?.substring(0, 20)}...');
        
        final user = User.fromJson(jsonData['user']);
        print('👤 Создан объект User для входа: ${user.name} (${user.email})');
        
        return {
          'success': true,
          'user': user,
          'access_token': jsonData['access_token'],
          'message': jsonData['message'],
        };
      } else {
        print('❌ API: Ошибка входа: ${jsonData['error']}');
        return {
          'success': false,
          'error': jsonData['error'],
        };
      }
    } catch (e) {
      print('❌ API: Ошибка сети при входе: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Получение профиля (требует JWT токен)
  Future<User?> getUserProfile(String accessToken) async {
    try {
      print('🌐 API: Получение профиля пользователя...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final user = User.fromJson(jsonData['user']);
        print('✅ API: Профиль получен для ${user.name}');
        return user;
      } else {
        print('❌ API: Ошибка получения профиля: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ API: Ошибка сети при получении профиля: $e');
      return null;
    }
  }

  // Проверка состояния API
  Future<bool> checkApiHealth() async {
    try {
      print('🌐 API: Проверка состояния...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        print('✅ API: Сервер работает');
        return true;
      } else {
        print('❌ API: Сервер не отвечает');
        return false;
      }
    } catch (e) {
      print('❌ API: Не удается подключиться к серверу: $e');
      return false;
    }
  }

  // Поиск пользователя по email
  Future<User?> findUserByEmail(String email) async {
    try {
      final users = await getAllUsers();
      return users.cast<User?>().firstWhere(
        (user) => user?.email == email.toLowerCase(),
        orElse: () => null,
      );
    } catch (e) {
      print('❌ API: Ошибка поиска пользователя: $e');
      return null;
    }
  }

  // Проверка существования email
  Future<bool> isEmailTaken(String email) async {
    try {
      final user = await findUserByEmail(email);
      return user != null;
    } catch (e) {
      print('❌ API: Ошибка проверки email: $e');
      return false;
    }
  }

  // Обновление профиля пользователя
  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    String? name,
    String? phone,
    String? location, // Добавляю локацию
  }) async {
    try {
      print('🌐 API: Обновление профиля...');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/profile/update'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (location != null) 'location': location, // Добавляю локацию
        }),
      );

      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ API: Профиль успешно обновлен');
        return {
          'success': true,
          'user': User.fromJson(jsonData['user']),
          'message': jsonData['message'],
        };
      } else {
        print('❌ API: Ошибка обновления профиля: ${jsonData['error']}');
        return {
          'success': false,
          'error': jsonData['error'],
        };
      }
    } catch (e) {
      print('❌ API: Ошибка сети при обновлении профиля: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Изменение пароля
  Future<Map<String, dynamic>> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🌐 API: Изменение пароля...');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/profile/change-password'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ API: Пароль успешно изменен');
        return {
          'success': true,
          'message': jsonData['message'],
        };
      } else {
        print('❌ API: Ошибка изменения пароля: ${jsonData['error']}');
        return {
          'success': false,
          'error': jsonData['error'],
        };
      }
    } catch (e) {
      print('❌ API: Ошибка сети при изменении пароля: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // ===== РЕФЕРАЛЬНАЯ СИСТЕМА =====

  // Получить свой реферальный код
  Future<Map<String, dynamic>> getMyReferralCode(String accessToken) async {
    try {
      print('🌐 API: Получение реферального кода...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/referral/my-code'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $accessToken',
        },
      );

      final jsonData = jsonDecode(response.body);
      print('📡 API ответ: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ API: Реферальный код получен');
        return {
          'success': true,
          'referral_code': jsonData['referral_code'],
          'bonus_points': jsonData['bonus_points'],
          'referrals_count': jsonData['referrals_count'],
        };
      } else {
        print('❌ API: Ошибка получения реферального кода: ${jsonData['error']}');
        return {
          'success': false,
          'error': jsonData['error'],
        };
      }
    } catch (e) {
      print('❌ API: Ошибка сети при получении реферального кода: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Проверить реферальный код
  Future<Map<String, dynamic>> checkReferralCode(String referralCode) async {
    try {
      print('🌐 API: Проверка реферального кода: $referralCode');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/referral/check-code'),
        headers: _headers,
        body: jsonEncode({
          'referral_code': referralCode,
        }),
      );

      final jsonData = jsonDecode(response.body);
      print('📡 API ответ: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ API: Реферальный код валиден');
        return {
          'success': true,
          'valid': jsonData['valid'],
          'referrer_name': jsonData['referrer_name'],
          'message': jsonData['message'],
        };
      } else {
        print('❌ API: Реферальный код невалиден: ${jsonData['error']}');
        return {
          'success': false,
          'error': jsonData['error'],
        };
      }
    } catch (e) {
      print('❌ API: Ошибка сети при проверке реферального кода: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Получить историю рефералов
  Future<Map<String, dynamic>> getReferralHistory(String accessToken) async {
    try {
      print('🌐 API: Получение истории рефералов...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/referral/history'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $accessToken',
        },
      );

      final jsonData = jsonDecode(response.body);
      print('📡 API ответ: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ API: История рефералов получена');
        return {
          'success': true,
          'referred_by': jsonData['referred_by'],
          'referrals_made': jsonData['referrals_made'],
          'total_referrals_made': jsonData['total_referrals_made'],
          'total_bonus_points_earned': jsonData['total_bonus_points_earned'],
        };
      } else {
        print('❌ API: Ошибка получения истории рефералов: ${jsonData['error']}');
        return {
          'success': false,
          'error': jsonData['error'],
        };
      }
    } catch (e) {
      print('❌ API: Ошибка сети при получении истории рефералов: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }
}
