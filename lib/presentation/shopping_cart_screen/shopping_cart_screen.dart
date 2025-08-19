import 'package:flutter/material.dart';
import 'widgets/empty_cart_widget.dart';
import 'widgets/order_summary_widget.dart';
import 'widgets/promo_code_widget.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  bool get isEmpty => true; // TODO: implement cart logic

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        centerTitle: true,
      ),
      body: isEmpty
          ? const EmptyCartWidget()
          : const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // TODO: Add cart items list
                  PromoCodeWidget(),
                  SizedBox(height: 24),
                  OrderSummaryWidget(),
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
                  // TODO: implement checkout
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
                  Navigator.pushReplacementNamed(context, '/sets-browse-screen');
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
            icon: Icon(Icons.set_meal),
            label: 'Sets',
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
