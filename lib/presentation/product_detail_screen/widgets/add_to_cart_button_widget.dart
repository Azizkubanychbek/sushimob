import 'package:flutter/material.dart';
import '../../../services/cart_service.dart';
import '../../../services/favorites_service.dart';

class AddToCartButtonWidget extends StatelessWidget {
  final String itemType;
  final int itemId;
  final String itemName;
  final VoidCallback? onSuccess;

  const AddToCartButtonWidget({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService();
    final cartService = CartService();

    return Row(
      children: [
        // Кнопка "Добавить в избранное"
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await favoritesService.toggleFavorite(
                itemType: itemType,
                itemId: itemId,
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$itemName ${favoritesService.isInFavorites(itemType, itemId) ? 'добавлен в' : 'удален из'} избранного'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                if (onSuccess != null) onSuccess!();
              }
            },
            icon: Icon(
              favoritesService.isInFavorites(itemType, itemId) 
                  ? Icons.favorite 
                  : Icons.favorite_border,
              color: favoritesService.isInFavorites(itemType, itemId) 
                  ? Colors.red 
                  : Colors.grey,
            ),
            label: Text(
              favoritesService.isInFavorites(itemType, itemId) 
                  ? 'В избранном' 
                  : 'В избранное'
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Кнопка "Добавить в корзину"
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () async {
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
                if (onSuccess != null) onSuccess!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ошибка добавления в корзину'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Добавить в корзину'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}