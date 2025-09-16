import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_sushi_service.dart'; // Заменяем на API сервис
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/favorites_service.dart';
import '../../models/app_roll.dart';
import '../../models/app_set.dart';
import './widgets/banner_carousel_widget.dart';
import './widgets/category_tile_widget.dart';
import './widgets/loyalty_points_widget.dart';
import './widgets/popular_sushi_card_widget.dart';
import './widgets/quick_reorder_card_widget.dart';
import './widgets/recommended_item_widget.dart';
import '../../widgets/unified_product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  bool _isRefreshing = false;
  int _currentTabIndex = 0;

  // Mock data for banners
  final List<Map<String, dynamic>> banners = [
    {
      "id": 1,
      "title": "Fresh Salmon Rolls",
      "subtitle": "20% Off Today Only",
      "image":
          "https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "backgroundColor": Color(0xFFE85A4F),
    },
    {
      "id": 2,
      "title": "Premium Tuna Selection",
      "subtitle": "Free Delivery on Orders \$30+",
      "image":
          "https://images.pexels.com/photos/248444/pexels-photo-248444.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "backgroundColor": Color(0xFF1B4B5A),
    },
    {
      "id": 3,
      "title": "Dragon Roll Special",
      "subtitle": "Limited Time Offer",
      "image":
          "https://images.pexels.com/photos/2098085/pexels-photo-2098085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "backgroundColor": Color(0xFF2E7D32),
    },
  ];

  // Real data for popular sushi
  List<AppRoll> popularSushi = [];
  List<AppSet> popularSets = [];
  List<Map<String, dynamic>> categories = [];
  List<dynamic> favoriteItems = []; // Избранные товары (роллы и сеты)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
    _loadData();
    
    // Проверяем, авторизован ли пользователь
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = AuthService();
      if (!authService.isLoggedIn) {
        print('🔐 Пользователь не авторизован, перенаправляем на регистрацию');
        Navigator.pushReplacementNamed(context, '/register-screen');
      } else {
        print('✅ Пользователь авторизован: ${authService.currentUser?.name}');
        // Пользователь авторизован, загружаем данные и показываем главную страницу
        print('🏠 Остаемся на главной странице');
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Загружаем реальные данные...');
      
      final rolls = await ApiSushiService.getPopularRolls();
      final sets = await ApiSushiService.getPopularSets();
      
      // Загружаем избранное (не блокируем UI)
      final favoritesService = FavoritesService();
      favoritesService.loadFavorites(); // Убираем await
      final favorites = favoritesService.favoriteItems;
      
      print('🔍 DEBUG: Получено роллов: ${rolls.length}, сетов: ${sets.length}, избранного: ${favorites.length}');
      if (rolls.isNotEmpty) {
        print('🔍 DEBUG: Первый ролл: ${rolls.first.name} - ${rolls.first.formattedPrice}');
      }
      if (sets.isNotEmpty) {
        print('🔍 DEBUG: Первый сет: ${sets.first.name} - ${sets.first.formattedPrice}');
      }
      
      // Создаем категории на основе реальных данных
      final dynamicCategories = <Map<String, dynamic>>[];
      
      // Добавляем категорию "Все роллы"
      dynamicCategories.add({
        "id": 0,
        "name": "Все роллы",
        "icon": "restaurant_menu",
        "color": Color(0xFFE85A4F),
        "route": "/menu-browse-screen",
      });
      
      // Добавляем статические категории роллов
      final staticCategories = [
        "Классические",
        "Запеченные", 
        "Острые",
        "Вегетарианские",
        "Премиум",
        "Мини роллы"
      ];
      
      final categoryColors = [
        Color(0xFF1B4B5A),
        Color(0xFF2E7D32),
        Color(0xFF9C27B0),
        Color(0xFFFF9800),
        Color(0xFF3F51B5),
        Color(0xFFE91E63),
        Color(0xFF4CAF50),
        Color(0xFFFF5722),
      ];
      
      for (int i = 0; i < staticCategories.length; i++) {
        dynamicCategories.add({
          "id": i + 1,
          "name": staticCategories[i],
          "icon": "restaurant_menu",
          "color": categoryColors[i % categoryColors.length],
          "route": "/menu-browse-screen",
          "category": staticCategories[i],
        });
      }
      
      // Добавляем категорию "Сеты"
      dynamicCategories.add({
        "id": 100,
        "name": "Сеты",
        "icon": "set_meal",
        "color": Color(0xFF795548),
        "route": "/sets-browse-screen",
      });
      
      // Добавляем категорию "Другое" для соусов, напитков и других товаров
      dynamicCategories.add({
        "id": 200,
        "name": "Другое",
        "icon": "category",
        "color": Color(0xFF607D8B),
        "route": "/menu-browse-screen",
        "category": "other",
      });
      
      // Всегда устанавливаем данные, даже если они пустые
      setState(() {
        popularSushi = rolls.take(6).toList();
        popularSets = sets.take(3).toList();
        favoriteItems = favorites;
        categories = dynamicCategories;
        _isLoading = false;
      });
      
      print('✅ Данные успешно загружены: ${popularSushi.length} роллов, ${popularSets.length} сетов, ${categories.length} категорий');
      
    } catch (e) {
      print('❌ Ошибка загрузки данных: $e');
      print('💡 Проверьте, что API сервер работает и доступен');
      
      // Даже при ошибке сбрасываем состояние загрузки
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Убираем загрузку моковых данных
  // void _loadMockData() {
  //   print('🔄 Загружаем моковые данные...');
  //   // Здесь можно добавить моковые данные если нужно
  // }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _bannerController.hasClients) {
        final nextIndex = (_currentBannerIndex + 1) % banners.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startBannerAutoScroll();
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _onAddToCart(dynamic item) async {
    HapticFeedback.lightImpact();
    String itemName = '';
    String itemType = '';
    int itemId = 0;
    
    try {
      if (item is AppRoll) {
        itemName = item.name.isNotEmpty ? item.name : 'Ролл';
        itemType = 'roll';
        itemId = item.id;
      } else if (item is AppSet) {
        itemName = item.name.isNotEmpty ? item.name : 'Сет';
        itemType = 'set';
        itemId = item.id;
      } else if (item is Map<String, dynamic>) {
        itemName = (item["name"]?.toString() ?? 'Item').isNotEmpty ? item["name"] : 'Item';
        itemType = 'roll'; // По умолчанию считаем роллом
        itemId = item["id"] ?? 0;
      } else {
        itemName = 'Item';
        itemType = 'roll';
        itemId = 0;
      }
      
      // Добавляем товар в корзину через CartService
      final cartService = CartService();
      final success = await cartService.addToCart(
        itemType: itemType,
        itemId: itemId,
        quantity: 1,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName добавлен в корзину'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка добавления в корзину'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Ошибка в _onAddToCart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка добавления в корзину'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onItemLongPress(dynamic item) {
    HapticFeedback.mediumImpact();
    
    String itemName = '';
    try {
      if (item is AppRoll) {
        itemName = item.name.isNotEmpty ? item.name : 'Ролл';
      } else if (item is AppSet) {
        itemName = item.name.isNotEmpty ? item.name : 'Сет';
      } else if (item is Map<String, dynamic>) {
        itemName = (item["name"]?.toString() ?? 'Item').isNotEmpty ? item["name"] : 'Item';
      } else {
        itemName = 'Item';
      }
    } catch (e) {
      print('❌ Ошибка в _onItemLongPress: $e');
      itemName = 'Item';
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility', 
                color: AppTheme.lightTheme.colorScheme.primary, 
                size: 24
              ),
              title: Text('Просмотр деталей'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/product-detail-screen');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite_border', 
                color: AppTheme.lightTheme.colorScheme.secondary, 
                size: 24
              ),
              title: Text('Добавить в избранное'),
              onTap: () {
                Navigator.pop(context);
                _onAddToFavorites(item);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share', 
                color: AppTheme.lightTheme.colorScheme.primary, 
                size: 24
              ),
              title: Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                _onShareItem(item);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _onAddToFavorites(dynamic item) {
    String itemName = '';
    
    try {
      if (item is AppRoll) {
        itemName = item.name.isNotEmpty ? item.name : 'Ролл';
      } else if (item is AppSet) {
        itemName = item.name.isNotEmpty ? item.name : 'Сет';
      } else if (item is Map<String, dynamic>) {
        itemName = (item["name"]?.toString() ?? 'Item').isNotEmpty ? item["name"] : 'Item';
      } else {
        itemName = 'Item';
      }
    } catch (e) {
      print('❌ Ошибка в _onAddToFavorites: $e');
      itemName = 'Item';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName добавлен в избранное'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onShareItem(dynamic item) {
    String itemName = '';
    
    try {
      if (item is AppRoll) {
        itemName = item.name.isNotEmpty ? item.name : 'Ролл';
      } else if (item is AppSet) {
        itemName = item.name.isNotEmpty ? item.name : 'Сет';
      } else if (item is Map<String, dynamic>) {
        itemName = (item["name"]?.toString() ?? 'Item').isNotEmpty ? item["name"] : 'Item';
      } else {
        itemName = 'Item';
      }
    } catch (e) {
      print('❌ Ошибка в _onShareItem: $e');
      itemName = 'Item';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Поделиться $itemName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.lightTheme.colorScheme.primary,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBannerCarousel(),
                          SizedBox(height: 3.h),
                          _buildLoyaltyPoints(),
                          SizedBox(height: 3.h),
                          _buildPopularSushiSection(),
                          SizedBox(height: 2.h),
                          _buildPopularSetsSection(),
                          SizedBox(height: 2.h),
                          _buildFavoritesSection(),
                          SizedBox(height: 2.h),
                          _buildRecommendedSection(),
                          SizedBox(height: 2.h),
                          _buildCategoriesSection(),
                          SizedBox(height: 20.h), // Увеличиваем отступ снизу
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Location selector functionality
              },
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deliver to',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                        Text(
                          'Downtown Office',
                          style: AppTheme.lightTheme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'keyboard_arrow_down',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/menu-browse-screen');
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'search',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          GestureDetector(
            onTap: () {
              // Notification functionality
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  CustomIconWidget(
                    iconName: 'notifications',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Container(
      height: 20.h,
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (index) {
          setState(() {
            _currentBannerIndex = index;
          });
        },
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return BannerCarouselWidget(
            banner: banner,
            onTap: () {
              Navigator.pushNamed(context, '/menu-browse-screen');
            },
          );
        },
      ),
    );
  }

  Widget _buildLoyaltyPoints() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: LoyaltyPointsWidget(
        currentPoints: 850,
        nextRewardPoints: 1000,
        onTap: () {
          Navigator.pushNamed(context, '/user-profile-screen');
        },
      ),
    );
  }

  Widget _buildPopularSushiSection() {
    print('🔍 DEBUG: _buildPopularSushiSection вызван');
    print('🔍 DEBUG: popularSushi.length = ${popularSushi.length}');
    if (popularSushi.isNotEmpty) {
      print('🔍 DEBUG: Первый ролл: ${popularSushi.first.name}');
    }
    
    if (popularSushi.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Популярные роллы',
              style: AppTheme.lightTheme.textTheme.headlineSmall,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            height: 28.h,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Нет популярных роллов',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Попробуйте обновить страницу',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Популярные роллы',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          height: 28.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: popularSushi.length,
            itemBuilder: (context, index) {
              final sushi = popularSushi[index];
              
              print('🔍 DEBUG: Рендерим ролл $index: ${sushi.name}');
              
              // Защита от null значений
              if (sushi == null) return const SizedBox.shrink();
              
              return PopularSushiCardWidget(
                roll: sushi,
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/product-detail-screen',
                    arguments: {
                      'productId': sushi.id,
                      'productType': 'roll',
                    }
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection() {
    final favoritesService = FavoritesService();
    if (favoriteItems.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Избранное', 
                style: AppTheme.lightTheme.textTheme.headlineSmall
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/favorites-screen');
                }, 
                child: Text('Все избранное')
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 18.h, // Увеличиваем высоту для избранного
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: favoriteItems.length,
            itemBuilder: (context, index) {
              final item = favoriteItems[index];
              
              // Защита от null значений
              if (item == null) return const SizedBox.shrink();
              
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/product-detail-screen',
                    arguments: {
                      'productId': item.item.id,
                      'productType': item.itemType,
                    }
                  );
                },
                child: Container(
                  width: 25.w, // Увеличиваем ширину карточек сетов
                  margin: EdgeInsets.only(right: 3.w),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Добавляем это
                      children: [
                        ClipRRect( // Заменяем Expanded на ClipRRect с фиксированной высотой
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)
                          ),
                          child: item.imageUrl.isNotEmpty 
                              ? Image.network(
                                  item.imageUrl,
                                  width: double.infinity,
                                  height: 12.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 7.h,
                                      color: Colors.grey[300],
                                      child: Icon(
                                        item.itemType == 'roll' 
                                            ? Icons.restaurant 
                                            : Icons.set_meal,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  height: 7.h,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    item.itemType == 'roll' 
                                        ? Icons.restaurant 
                                        : Icons.set_meal,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        Container( // Оборачиваем в Container с фиксированной высотой
                          height: 4.h, // Увеличиваем высоту для текста
                          padding: EdgeInsets.all(1.w), // Увеличиваем padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Простое распределение
                            children: [
                              Text(
                                item.itemName.isNotEmpty ? item.itemName : 'Товар $index',
                                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                  fontSize: 12, // Увеличиваем размер шрифта
                                ),
                                maxLines: 2, // Увеличиваем количество строк
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.price.toStringAsFixed(2)} сом',
                                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11, // Увеличиваем размер шрифта
                                    ),
                                  ),
                                  if (item.itemType == 'set' && (item.item as dynamic).hasDiscount)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w, // Увеличиваем padding
                                        vertical: 1.h
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8) // Увеличиваем радиус
                                      ),
                                      child: Text(
                                        '-${(item.item as dynamic).formattedDiscount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10, // Увеличиваем размер шрифта
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Кнопка "Добавить в избранное"
                                  Expanded(
                                    child: IconButton(
                                      onPressed: () async {
                                        final favoritesService = FavoritesService();
                                        final success = await favoritesService.toggleFavorite(
                                          itemType: item.itemType,
                                          itemId: item.item.id,
                                        );
                                        
                                        if (success) {
                                          // Обновляем UI через перезагрузку данных
                                          _loadData();
                                        }
                                      },
                                      icon: Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  // Кнопка "Добавить в корзину"
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: () => _onAddToCart(item.item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 0.5.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'В корзину',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Рекомендуем',
                style: AppTheme.lightTheme.textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/menu-browse-screen');
                },
                child: Text('Все роллы'),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: popularSushi.isEmpty
              ? const Center(child: Text('Загружаем рекомендации...'))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 2.h,
                  ),
                  itemCount: popularSushi.take(4).length,
                  itemBuilder: (context, index) {
                    final roll = popularSushi[index];
                    return UnifiedProductCard(
                      product: roll,
                      onTap: () {
                        Navigator.pushNamed(
                          context, 
                          '/product-detail-screen',
                          arguments: {
                            'productId': roll.id,
                            'productType': 'roll',
                          }
                        );
                      },
                      showRating: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPopularSetsSection() {
    print('🔍 DEBUG: _buildPopularSetsSection вызван');
    print('🔍 DEBUG: popularSets.length = ${popularSets.length}');
    if (popularSets.isNotEmpty) {
      print('🔍 DEBUG: Первый сет: ${popularSets.first.name}');
    }
    
    if (popularSets.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Популярные сеты',
              style: AppTheme.lightTheme.textTheme.headlineSmall,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            height: 28.h,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.set_meal, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Нет популярных сетов',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Попробуйте обновить страницу',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Популярные сеты',
                style: AppTheme.lightTheme.textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/sets-browse-screen');
                },
                child: Text('Все сеты'),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          height: 28.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: popularSets.length,
            itemBuilder: (context, index) {
              final set = popularSets[index];
              
              print('🔍 DEBUG: Рендерим сет $index: ${set.name}');
              
              return RecommendedItemWidget(
                set: set,
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/set-detail-screen',
                    arguments: {
                      'setId': set.id,
                    }
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Categories',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          height: 15.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryTileWidget(
                category: category,
                onTap: () {
                  if (category['name'] == 'Сеты') {
                    Navigator.pushReplacementNamed(context, '/sets-browse-screen');
                  } else if (category['name'] == 'Все роллы') {
                    Navigator.pushReplacementNamed(context, '/menu-browse-screen');
                  } else if (category.containsKey('category')) {
                    // Переходим к роллам с фильтром по категории
                    Navigator.pushReplacementNamed(
                      context, 
                      '/menu-browse-screen',
                      arguments: {'category': category['category']}
                    );
                  } else {
                    Navigator.pushReplacementNamed(context, '/menu-browse-screen');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Home'),
              _buildNavItem(1, Icons.restaurant_menu, 'Menu'),
              _buildNavItem(2, Icons.receipt_long, 'Заказы'),
              _buildNavItem(3, Icons.shopping_cart, 'Cart'),
              _buildNavItem(4, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });

        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/menu-browse-screen');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/orders-screen');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/shopping-cart-screen');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/user-profile-screen');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.lightTheme.colorScheme.primary : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.lightTheme.colorScheme.primary : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/menu-browse-screen');
      },
      child: CustomIconWidget(
        iconName: 'search',
        color: AppTheme.lightTheme.colorScheme.onSecondary,
        size: 24,
      ),
    );
  }
}