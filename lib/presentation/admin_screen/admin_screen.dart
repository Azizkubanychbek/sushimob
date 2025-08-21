import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'widgets/admin_dashboard_widget.dart';
import 'widgets/admin_users_widget.dart';
import 'widgets/admin_rolls_widget.dart';
import 'widgets/admin_sets_widget.dart';
import 'widgets/admin_ingredients_widget.dart';
import 'widgets/admin_other_items_widget.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // Проверяем права администратора
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_authService.isLoggedIn || !_authService.currentUser!.isAdmin) {
        Navigator.pushNamedAndRemoveUntil(context, '/login-screen', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Доступ запрещен. Требуются права администратора.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    if (user == null || !user.isAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login-screen',
                (route) => false,
              );
            },
          ),
        ],
                            bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(icon: Icon(Icons.dashboard), text: 'Дашборд'),
                        Tab(icon: Icon(Icons.people), text: 'Пользователи'),
                        Tab(icon: Icon(Icons.restaurant_menu), text: 'Роллы'),
                        Tab(icon: Icon(Icons.set_meal), text: 'Сеты'),
                        Tab(icon: Icon(Icons.inventory), text: 'Ингредиенты'),
                        Tab(icon: Icon(Icons.local_drink), text: 'Соусы/Напитки'),
                      ],
                    ),
      ),
                        body: TabBarView(
                    controller: _tabController,
                    children: const [
                      AdminDashboardWidget(),
                      AdminUsersWidget(),
                      AdminRollsWidget(),
                      AdminSetsWidget(),
                      AdminIngredientsWidget(),
                      AdminOtherItemsWidget(),
                    ],
                  ),
    );
  }
}
