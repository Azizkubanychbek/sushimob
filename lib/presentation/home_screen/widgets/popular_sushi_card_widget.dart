import 'package:flutter/material.dart';
import '../../../models/app_roll.dart';
import '../../../services/cart_service.dart';
import '../../../services/favorites_service.dart';

class PopularSushiCardWidget extends StatelessWidget {
  final AppRoll roll;
  final VoidCallback? onTap;

  const PopularSushiCardWidget({
    Key? key,
    required this.roll,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService();
    final cartService = CartService();
    
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.pushNamed(
          context,
          '/product-detail-screen',
          arguments: {
            'productId': roll.id,
            'productType': 'roll',
          }
        );
      },
      child: Container(
        width: 160, // Фиксированная ширина карточки
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка на всю ширину карточки
            Container(
              height: 120, // Высота картинки
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
            ),
            
            const SizedBox(height: 8),
            
            // Название ролла под карточкой
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
            
            // Цена
            Text(
              roll.formattedPrice,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Кнопки справа снизу
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Кнопка "Добавить в избранное"
                IconButton(
                  onPressed: () async {
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
                          duration: Duration(seconds: 2),
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
      ),
    );
  }
}
