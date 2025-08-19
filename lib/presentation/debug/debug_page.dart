import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String _debugInfo = 'Загрузка...';
  final TextEditingController _testDataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final usersJson = prefs.getString('users_json');
      final sessionToken = prefs.getString('session_token');
      final currentUser = prefs.getString('current_user');
      
      final debugText = '''
🔍 DEBUG ИНФОРМАЦИЯ:

📁 users_json: ${usersJson ?? 'NULL'}
🔑 session_token: ${sessionToken ?? 'NULL'}
👤 current_user: ${currentUser ?? 'NULL'}

📊 Все ключи SharedPreferences:
${prefs.getKeys().join('\n')}

💾 Тестовые данные:
${await _testSharedPreferences()}
      ''';

      setState(() {
        _debugInfo = debugText;
      });
    } catch (e) {
      setState(() {
        _debugInfo = '❌ Ошибка: $e';
      });
    }
  }

  Future<String> _testSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Тест записи
      await prefs.setString('test_key', 'test_value_${DateTime.now().millisecondsSinceEpoch}');
      
      // Тест чтения
      final testValue = prefs.getString('test_key');
      
      return 'test_key = $testValue';
    } catch (e) {
      return '❌ Ошибка теста: $e';
    }
  }

  Future<void> _addTestUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final testUser = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@test.com',
        'phone': '1234567890',
        'password_hash': 'test_hash',
        'created_at': DateTime.now().toIso8601String(),
        'loyalty_points': 100,
        'is_active': true,
      };
      
      final usersData = {
        'users': [testUser]
      };
      
      await prefs.setString('users_json', jsonEncode(usersData));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Тестовый пользователь добавлен!')),
      );
      
      _loadDebugInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }

  Future<void> _clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Все данные очищены!')),
      );
      
      _loadDebugInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Debug Page'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addTestUser,
                  child: const Text('➕ Добавить тест пользователя'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearAll,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('🗑️ Очистить все'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _loadDebugInfo,
                  child: const Text('🔄 Обновить'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
