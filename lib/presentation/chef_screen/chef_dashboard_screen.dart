import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/ingredient_service.dart';

class ChefDashboardScreen extends StatefulWidget {
  const ChefDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ChefDashboardScreen> createState() => _ChefDashboardScreenState();
}

class _ChefDashboardScreenState extends State<ChefDashboardScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final IngredientService _ingredientService = IngredientService();
  List<Order> _orders = [];
  List<Map<String, dynamic>> _ingredients = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    // Получаем токен из AuthService
    final authService = AuthService();
    if (authService.isLoggedIn) {
      final token = authService.getToken()!;
      _orderService.setAuthToken(token);
      _ingredientService.setAuthToken(token);
    }

    try {
      // Загружаем заказы и ингредиенты параллельно
      final futures = await Future.wait([
        _orderService.getAllOrders(),
        _ingredientService.getAllIngredients(),
      ]);
      
      setState(() {
        _orders = futures[0] as List<Order>;
        _ingredients = futures[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getIngredientIcon(String? name) {
    if (name == null) return Icons.help;
    
    final lowerName = name.toLowerCase();
    if (lowerName.contains('рис')) return Icons.rice_bowl;
    if (lowerName.contains('лосось') || lowerName.contains('рыба')) return Icons.waves;
    if (lowerName.contains('авокадо')) return Icons.eco;
    if (lowerName.contains('сыр') || lowerName.contains('филадельфия')) return Icons.emoji_food_beverage;
    if (lowerName.contains('нори')) return Icons.article;
    if (lowerName.contains('васаби')) return Icons.water_drop;
    if (lowerName.contains('имбирь')) return Icons.spa;
    if (lowerName.contains('соус') || lowerName.contains('соевый')) return Icons.local_drink;
    return Icons.emoji_food_beverage;
  }

  Color _getIngredientColor(String? name) {
    if (name == null) return Colors.grey;
    
    final lowerName = name.toLowerCase();
    if (lowerName.contains('рис')) return Colors.brown;
    if (lowerName.contains('лосось') || lowerName.contains('рыба')) return Colors.orange;
    if (lowerName.contains('авокадо')) return Colors.green;
    if (lowerName.contains('сыр') || lowerName.contains('филадельфия')) return Colors.yellow;
    if (lowerName.contains('нори')) return Colors.grey;
    if (lowerName.contains('васаби')) return Colors.lightGreen;
    if (lowerName.contains('имбирь')) return Colors.pink;
    if (lowerName.contains('соус') || lowerName.contains('соевый')) return Colors.brown;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель шеф-повара'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Новые', icon: Icon(Icons.new_releases)),
            Tab(text: 'Готовятся', icon: Icon(Icons.restaurant)),
            Tab(text: 'Готовы', icon: Icon(Icons.check_circle)),
            Tab(text: 'Поставки', icon: Icon(Icons.local_shipping)),
            Tab(text: 'Списания', icon: Icon(Icons.remove_circle)),
            Tab(text: 'Все', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(_getOrdersByStatus([OrderStatus.confirmed])), // Новые заказы (Принят)
                _buildOrdersList(_getOrdersByStatus([OrderStatus.preparing])), // Готовятся
                _buildOrdersList(_getOrdersByStatus([OrderStatus.ready])), // Готовы
                _buildSuppliesList(), // Поставки
                _buildWriteoffsList(), // Списания
                _buildOrdersList(_orders), // Все заказы
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIngredientsManagement(),
        icon: const Icon(Icons.inventory),
        label: const Text('Ингредиенты'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  List<Order> _getOrdersByStatus(List<OrderStatus> statuses) {
    return _orders.where((order) => statuses.contains(order.status)).toList();
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет заказов',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Новые заказы появятся здесь',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок заказа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ #${order.id}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(order.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Информация о клиенте
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${order.userName ?? 'Пользователь'} • ${order.userPhone ?? order.phone ?? 'Не указан'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Время заказа
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDate(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Адрес доставки
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Товары в заказе
            Text(
              'Товары (${order.items.length}):',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 4),
            
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                children: [
                  Text('• ', style: TextStyle(color: Colors.grey[600])),
                  Expanded(
                    child: Text(
                      '${item.itemName} x${item.quantity}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 12),
            
            // Сумма заказа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Сумма: ${order.totalAmount.toStringAsFixed(0)} сом',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (order.notes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note, size: 12, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Есть примечания',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Кнопки управления
            _buildOrderActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(Order order) {
    return Row(
      children: [
        if (order.status == OrderStatus.pending) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(order, OrderStatus.confirmed),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Принять'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(order, OrderStatus.cancelled),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Отклонить'),
            ),
          ),
        ] else if (order.status == OrderStatus.confirmed) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(order, OrderStatus.preparing),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Начать готовить'),
            ),
          ),
        ] else if (order.status == OrderStatus.preparing) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(order, OrderStatus.ready),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Готово'),
            ),
          ),
        ] else if (order.status == OrderStatus.ready) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(order, OrderStatus.delivering),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
              ),
              child: const Text('Передать курьеру'),
            ),
          ),
        ] else ...[
          Expanded(
            child: Text(
              'Заказ ${order.status.displayName.toLowerCase()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    final success = await _orderService.updateOrderStatus(order.id, newStatus);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус заказа #${order.id} изменен на "${newStatus.displayName}"'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка обновления статуса заказа'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showIngredientsManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Управление ингредиентами',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ingredients.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет данных об ингредиентах',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : Column(
                          children: _ingredients.map((ingredient) {
                            return _buildIngredientCard(
                              ingredient['name'] ?? 'Неизвестный ингредиент',
                              '${ingredient['quantity'] ?? 'N/A'} ${ingredient['unit'] ?? ''}',
                              _getIngredientIcon(ingredient['name']),
                              _getIngredientColor(ingredient['name']),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientCard(String name, String amount, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'В наличии: $amount',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Добавить функциональность списания
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Списать $name'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Списать'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuppliesList() {
    return Scaffold(
      body: Column(
        children: [
          // Кнопка добавления поставки
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddSupplyDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить поставку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Список поставок
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5, // Заглушка
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping, color: Colors.green),
                    title: Text('Поставка #${index + 1}'),
                    subtitle: Text('Рис - 50 кг\n${_formatDate(DateTime.now().subtract(Duration(days: index)))}'),
                    trailing: Text('${(100 + index * 50)} сом'),
                    onTap: () => _showSupplyDetails(index + 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteoffsList() {
    return Scaffold(
      body: Column(
        children: [
          // Кнопка добавления списания
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddWriteoffDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить списание'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Список списаний
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3, // Заглушка
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.remove_circle, color: Colors.red),
                    title: Text('Списание #${index + 1}'),
                    subtitle: Text('Просроченный лосось - 2 кг\n${_formatDate(DateTime.now().subtract(Duration(days: index + 1)))}'),
                    trailing: Text('${(50 + index * 25)} сом'),
                    onTap: () => _showWriteoffDetails(index + 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSupplyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить поставку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Название ингредиента'),
              controller: TextEditingController(text: 'Рис'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Количество'),
              controller: TextEditingController(text: '50'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Единица измерения'),
              controller: TextEditingController(text: 'кг'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Стоимость'),
              controller: TextEditingController(text: '150'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Поставка добавлена')),
              );
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddWriteoffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить списание'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Название ингредиента'),
              controller: TextEditingController(text: 'Лосось'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Количество'),
              controller: TextEditingController(text: '2'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Единица измерения'),
              controller: TextEditingController(text: 'кг'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Причина списания'),
              controller: TextEditingController(text: 'Просрочен'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Списание добавлено')),
              );
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showSupplyDetails(int supplyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Поставка #$supplyId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ингредиент: Рис'),
            Text('Количество: 50 кг'),
            Text('Стоимость: 150 сом'),
            Text('Дата: ${_formatDate(DateTime.now())}'),
            Text('Поставщик: ООО "Рис и Ко"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showWriteoffDetails(int writeoffId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Списание #$writeoffId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ингредиент: Лосось'),
            Text('Количество: 2 кг'),
            Text('Причина: Просрочен'),
            Text('Дата: ${_formatDate(DateTime.now())}'),
            Text('Ответственный: Шеф-повар'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.grey;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivering:
        return Colors.cyan;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  void _logout() {
    final authService = AuthService();
    authService.logout();
    Navigator.pushReplacementNamed(context, '/');
  }
}
