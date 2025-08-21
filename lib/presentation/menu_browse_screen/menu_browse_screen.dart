import 'package:flutter/material.dart';
import '../../models/app_roll.dart';
import '../../services/api_sushi_service.dart'; // Заменяем на API сервис
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/sort_bottom_sheet.dart';
import 'widgets/sushi_card_widget.dart';

class MenuBrowseScreen extends StatefulWidget {
  final String? initialCategory;
  
  const MenuBrowseScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<MenuBrowseScreen> createState() => _MenuBrowseScreenState();
}

class _MenuBrowseScreenState extends State<MenuBrowseScreen> {
  List<AppRoll> _rolls = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Все';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadRolls();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Получаем аргументы из навигации
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['category'] != null) {
      setState(() {
        _selectedCategory = args['category'] as String;
      });
    }
  }

  Future<void> _loadRolls() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Загружаем роллы для меню...');
      final rolls = await ApiSushiService.getRolls();
      
      setState(() {
        _rolls = rolls;
        _isLoading = false;
      });
      
      print('✅ Загружено ${rolls.length} роллов для меню');
    } catch (e) {
      print('❌ Ошибка загрузки роллов: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<AppRoll> get _filteredRolls {
    if (_searchQuery.isEmpty && _selectedCategory == 'Все') {
      return _rolls;
    }
    
    return _rolls.where((roll) {
      final matchesSearch = _searchQuery.isEmpty || 
        roll.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Все' || 
        roll.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Меню'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const SortBottomSheet(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Меню
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              // Already on menu
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/favorites-screen');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/shopping-cart-screen');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/user-profile-screen');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск роллов...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Счетчик результатов
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Найдено: ${_filteredRolls.length} роллов',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Всего: ${_rolls.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Список роллов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRolls.isEmpty
                    ? const Center(
                        child: Text('Роллы не найдены'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9, // Более квадратные пропорции
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredRolls.length,
                        itemBuilder: (context, index) {
                          final roll = _filteredRolls[index];
                          return SushiCardWidget(roll: roll);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
