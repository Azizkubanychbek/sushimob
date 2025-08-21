import 'package:flutter/material.dart';
import '../../../models/app_roll.dart';
import '../../../services/cart_service.dart';
import '../../../services/favorites_service.dart';

class SushiCardWidget extends StatelessWidget {
  final AppRoll roll;

  const SushiCardWidget({
    super.key,
    required this.roll,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService();
    final cartService = CartService();
    return GestureDetector(
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
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Минимальный размер
          children: [
            // Изображение - фиксированная высота
            Container(
              height: 90, // Уменьшенная высота
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(roll.imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Fallback на иконку если изображение не загрузилось
                  },
                ),
              ),
              child: roll.imageUrl.contains('pexels.com') 
                ? null 
                : const Icon(
                    Icons.image,
                    size: 48,
                    color: Colors.white,
                  ),
            ),
            // Контент - компактный без лишних отступов
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Минимальный размер
                children: [
                  // Название ролла
                  Text(
                    roll.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Рейтинг
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        roll.formattedRating,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Фиксированный отступ
                  // Цена и кнопки
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        roll.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          // Кнопка "Добавить в избранное"
                          IconButton(
                            onPressed: () async {
                              final favoritesService = FavoritesService();
                              final success = await favoritesService.toggleFavorite(
                                itemType: 'roll',
                                itemId: roll.id,
                              );
                              
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${roll.name} ${favoritesService.isInFavorites('roll', roll.id) ? 'добавлен в' : 'удален из'} избранного'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              favoritesService.isInFavorites('roll', roll.id) 
                                  ? Icons.favorite 
                                  : Icons.favorite_border,
                              color: favoritesService.isInFavorites('roll', roll.id) 
                                  ? Colors.red 
                                  : Colors.grey,
                            ),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          // Кнопка "Добавить в корзину"
                          IconButton(
                            onPressed: () async {
                              final cartService = CartService();
                              final success = await cartService.addToCart(
                                itemType: 'roll',
                                itemId: roll.id,
                                quantity: 1,
                              );
                              
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${roll.name} добавлен в корзину'),
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
                            },
                            icon: const Icon(Icons.shopping_cart),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}