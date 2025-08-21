import 'package:flutter/material.dart';
import '../../models/app_set.dart';
import '../../services/api_sushi_service.dart'; // Заменяем на API сервис
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../set_detail_screen/set_detail_screen.dart';

class SetsBrowseScreen extends StatefulWidget {
  const SetsBrowseScreen({super.key});

  @override
  State<SetsBrowseScreen> createState() => _SetsBrowseScreenState();
}

class _SetsBrowseScreenState extends State<SetsBrowseScreen> {
  List<AppSet> _sets = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Загружаем сеты для меню...');
      final sets = await ApiSushiService.getSets();
      
      setState(() {
        _sets = sets;
        _isLoading = false;
      });
      
      print('✅ Загружено ${sets.length} сетов для меню');
    } catch (e) {
      print('❌ Ошибка загрузки сетов: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<AppSet> get _filteredSets {
    if (_searchQuery.isEmpty) {
      return _sets;
    }
    
    return _sets.where((set) => 
      set.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сеты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Показать поиск
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Избранное
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/menu-browse-screen');
              break;
            case 2:
              // Already on favorites
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
                hintText: 'Поиск сетов...',
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
                  'Найдено: ${_filteredSets.length} сетов',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Всего: ${_sets.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Список сетов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSets.isEmpty
                    ? const Center(
                        child: Text('Сеты не найдены'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSets.length,
                        itemBuilder: (context, index) {
                          final set = _filteredSets[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  set.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.restaurant),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                set.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(set.description),
                                  const SizedBox(height: 4),
                                  Text('${set.totalRolls} роллов'),
                                  if (set.hasDiscount) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          set.formattedOriginalPrice,
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '-${set.formattedDiscount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    set.formattedPrice,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (set.hasDiscount)
                                    Text(
                                      'Экономия: ${set.formattedSavings}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SetDetailScreen(setId: set.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
