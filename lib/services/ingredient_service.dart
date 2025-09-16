import 'dart:convert';
import 'package:http/http.dart' as http;

class IngredientService {
  static const String baseUrl = 'http://localhost:5002/api';
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Получить все ингредиенты
  Future<List<Map<String, dynamic>>> getAllIngredients() async {
    try {
      print('🥬 Получение ингредиентов...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/ingredients'),
        headers: _headers,
      );

      print('🥬 Ответ API ингредиентов: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ingredients = List<Map<String, dynamic>>.from(data['ingredients']);
        
        print('✅ Получено ингредиентов: ${ingredients.length}');
        return ingredients;
      } else {
        print('❌ Ошибка получения ингредиентов');
        throw Exception('Ошибка получения ингредиентов');
      }
    } catch (e) {
      print('❌ Ошибка сети: $e');
      throw Exception('Ошибка сети: $e');
    }
  }
}
