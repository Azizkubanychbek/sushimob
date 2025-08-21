import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AdminUsersWidget extends StatefulWidget {
  const AdminUsersWidget({super.key});

  @override
  State<AdminUsersWidget> createState() => _AdminUsersWidgetState();
}

class _AdminUsersWidgetState extends State<AdminUsersWidget> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final users = await ApiService.getAdminUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки пользователей: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Детали пользователя'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', user['id'].toString()),
              _buildDetailRow('Имя', user['name']),
              _buildDetailRow('Email', user['email']),
              _buildDetailRow('Телефон', user['phone']),
              _buildDetailRow('Адрес', user['location'] ?? 'Не указан'),
              _buildDetailRow('Бонусные баллы', user['loyalty_points'].toString()),
              _buildDetailRow('Статус', user['is_active'] ? 'Активен' : 'Заблокирован'),
              _buildDetailRow('Роль', user['is_admin'] ? 'Администратор' : 'Пользователь'),
              _buildDetailRow('Дата регистрации', _formatDate(user['created_at'])),
              if (user['last_login_at'] != null)
                _buildDetailRow('Последний вход', _formatDate(user['last_login_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Не указана';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Управление пользователями (${_users.length})',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _loadUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: _users.isEmpty
                      ? const Center(
                          child: Text(
                            'Пользователи не найдены',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: user['is_admin'] == true
                                      ? Colors.red 
                                      : (user['is_active'] == true ? Colors.green : Colors.grey),
                                  child: Text(
                                    user['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (user['is_admin'] == true)
                                      const Icon(Icons.admin_panel_settings, color: Colors.red),
                                    if (user['is_active'] != true)
                                      const Icon(Icons.block, color: Colors.grey),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['email']),
                                    Text(user['phone']),
                                    if (user['location']?.isNotEmpty == true)
                                      Text(user['location']),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text('Баллы: ${user['loyalty_points']}'),
                                          backgroundColor: Colors.blue[100],
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text(user['is_active'] == true ? 'Активен' : 'Заблокирован'),
                                          backgroundColor: user['is_active'] == true
                                              ? Colors.green[100] 
                                              : Colors.grey[100],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showUserDetails(user),
                                      icon: const Icon(Icons.info, color: Colors.blue),
                                      tooltip: 'Детали',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
  }
}
