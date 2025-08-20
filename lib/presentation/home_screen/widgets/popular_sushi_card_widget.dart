import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/favorites_service.dart';

class PopularSushiCardWidget extends StatefulWidget {
  final Map<String, dynamic>? sushi;
  final VoidCallback onAddToCart;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const PopularSushiCardWidget({
    Key? key,
    required this.sushi,
    required this.onAddToCart,
    required this.onLongPress,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PopularSushiCardWidget> createState() => _PopularSushiCardWidgetState();
}

class _PopularSushiCardWidgetState extends State<PopularSushiCardWidget> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем состояние избранного из данных
    isFavorite = widget.sushi?["isFavorite"] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Защита от null значений
    if (widget.sushi == null) {
      return Container(
        width: 45.w,
        height: 20.h,
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.error, color: Colors.grey),
        ),
      );
    }

    // Безопасное извлечение значений с проверкой на null
    final imageUrl = widget.sushi!["image"]?.toString() ?? '';
    final name = widget.sushi!["name"]?.toString() ?? 'Название';
    final price = widget.sushi!["price"]?.toString() ?? '0₽';
    final rating = widget.sushi!["rating"]?.toString() ?? '0.0';

    final isNew = widget.sushi!["isNew"] as bool? ?? false;
    final isPopular = widget.sushi!["isPopular"] as bool? ?? false;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: 45.w,
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Добавляем это
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CustomImageWidget(
                    imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                    width: 45.w,
                    height: 12.h, // Уменьшаем высоту изображения
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: GestureDetector(
                    onTap: () async {
                      final favoritesService = FavoritesService();
                      final success = await favoritesService.toggleFavorite(
                        itemType: 'roll',
                        itemId: widget.sushi!['id'] ?? 0,
                      );
                      
                      if (success) {
                        // Обновляем состояние избранного
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? Colors.red
                            : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2.w,
                  left: 2.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          rating,
                          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NEW',
                        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Container( // Заменяем Expanded на Container с фиксированной высотой
              height: 6.h, // Уменьшаем высоту
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8), // Небольшой отступ вместо Spacer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onAddToCart,
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: CustomIconWidget(
                            iconName: 'add_shopping_cart',
                            color: Colors.white,
                            size: 20,
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
    );
  }
}
