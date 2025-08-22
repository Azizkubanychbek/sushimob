import 'package:flutter/material.dart';
import '../models/app_roll.dart';
import '../models/app_set.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';

class UnifiedProductCard extends StatelessWidget {
  final dynamic product; // AppRoll или AppSet
  final VoidCallback? onTap;
  final bool showRating;
  final double? width;
  final double? height;

  const UnifiedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showRating = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService();
    final cartService = CartService();
    
    final isRoll = product is AppRoll;
    final productName = isRoll ? product.name : product.name;
    final productPrice = isRoll ? product.formattedPrice : product.formattedPrice;
    final productImage = isRoll ? product.imageUrl : product.imageUrl;
    final productId = isRoll ? product.id : product.id;
    final productType = isRoll ? 'roll' : 'set';
    
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.pushNamed(
          context,
          isRoll ? '/product-detail-screen' : '/set-detail-screen',
          arguments: {
            'productId': productId,
            'productType': productType,
          }
        );
      },
      child: Container(
        width: width ?? 160,
        height: height ?? 220,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Изображение - фиксированная высота
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(productImage),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Fallback на иконку если изображение не загрузилось
                    },
                  ),
                ),
                child: productImage.contains('pexels.com') 
                  ? null 
                  : const Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.white,
                    ),
              ),
              // Контент - компактный без лишних отступов
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Название продукта
                      Flexible(
                        child: Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Рейтинг (если включен)
                      if (showRating) ...[
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[600]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isRoll ? product.formattedRating : '4.5',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Цена и кнопки - размещаем внизу
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              productPrice,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Кнопка "Добавить в избранное"
                              IconButton(
                                onPressed: () async {
                                  final success = await favoritesService.toggleFavorite(
                                    itemType: productType,
                                    itemId: productId,
                                  );
                                  
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$productName ${favoritesService.isInFavorites(productType, productId) ? 'добавлен в' : 'удален из'} избранного'),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  favoritesService.isInFavorites(productType, productId) 
                                      ? Icons.favorite 
                                      : Icons.favorite_border,
                                  color: favoritesService.isInFavorites(productType, productId) 
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
                                    itemType: productType,
                                    itemId: productId,
                                    quantity: 1,
                                  );
                                  
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$productName добавлен в корзину'),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
