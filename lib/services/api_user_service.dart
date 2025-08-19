import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiUserService {
  static final ApiUserService _instance = ApiUserService._internal();
  factory ApiUserService() => _instance;
  ApiUserService._internal();

  static const String _baseUrl = 'http://localhost:5000/api';
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
  }) async {
    try {
      print('🌐 API: Регистрация пользователя $email...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        print('✅ API: Пользователь $email успешно зарегистрирован');
        return {
          'success': true,
          'user': User.fromJson(jsonData['user']),
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
      
      if (response.statusCode == 200) {
        print('✅ API: Пользователь $email успешно вошел');
        return {
          'success': true,
          'user': User.fromJson(jsonData['user']),
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
}
