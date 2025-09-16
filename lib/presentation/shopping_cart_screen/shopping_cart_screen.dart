import 'package:flutter/material.dart';
import '../../services/cart_service.dart';
import '../../models/cart_item.dart';
import 'widgets/empty_cart_widget.dart';
import 'widgets/order_summary_widget.dart';
import 'widgets/promo_code_widget.dart';
import 'widgets/bonus_points_widget.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  final CartService _cartService = CartService();
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
    });
    
    await _cartService.loadCart();
    
    if (mounted) {
      setState(() {
        _cartItems = _cartService.cartItems;
        _isLoading = false;
      });
    }
  }

  bool get isEmpty => _cartItems.isEmpty;

  Widget _buildItemImage(CartItem item) {
    String? imageUrl;
    
    // Получаем URL изображения из item
    if (item.item is Map<String, dynamic>) {
      imageUrl = item.item['image_url'];
    } else if (item.itemType == 'roll' && item.item != null) {
      imageUrl = (item.item as dynamic).imageUrl;
    } else if (item.itemType == 'set' && item.item != null) {
      imageUrl = (item.item as dynamic).imageUrl;
    }
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon(item);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
      );
    }
    
    return _buildFallbackIcon(item);
  }

  Widget _buildFallbackIcon(CartItem item) {
    return Icon(
      item.itemType == 'roll' ? Icons.restaurant : Icons.set_meal,
      size: 40,
      color: Colors.grey,
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Изображение товара
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: _buildItemImage(item),
            ),
            const SizedBox(width: 16),
            
            // Информация о товаре
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(2)} сом',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Управление количеством
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    if (item.quantity > 1) {
                      await _cartService.updateQuantity(item.id, item.quantity - 1);
                      _loadCart();
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${item.quantity}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () async {
                    await _cartService.updateQuantity(item.id, item.quantity + 1);
                    _loadCart();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            
            // Кнопка удаления
            IconButton(
              onPressed: () async {
                await _cartService.removeFromCart(item.id);
                _loadCart();
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
              ? const EmptyCartWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Список товаров в корзине
                      ..._cartItems.map((item) => _buildCartItem(item)),
                      const SizedBox(height: 24),
                      const PromoCodeWidget(),
                      const SizedBox(height: 16),
                      BonusPointsWidget(
                        totalPrice: _cartService.totalPrice,
                        onBonusUsed: _loadCart,
                      ),
                      const SizedBox(height: 24),
                      OrderSummaryWidget(
                        totalPrice: _cartService.totalPrice,
                        totalItems: _cartService.totalItems,
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/checkout-screen');
                },
                child: const Text('Оформить заказ'),
              ),
            ),
          BottomNavigationBar(
            currentIndex: 3, // Корзина
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/menu-browse-screen');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/favorites-screen');
                  break;
                case 3:
                  // Already on cart
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
        ],
      ),
    );
  }
}
