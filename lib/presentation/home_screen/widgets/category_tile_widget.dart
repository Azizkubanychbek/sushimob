import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CategoryTileWidget extends StatelessWidget {
  final Map<String, dynamic>? category;
  final VoidCallback onTap;

  const CategoryTileWidget({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Защита от null значений
    if (category == null) {
      return Container(
        width: 25.w,
        height: 15.h,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.error, color: Colors.grey),
        ),
      );
    }

    // Безопасное извлечение значений
    final name = category!["name"]?.toString() ?? 'Категория';
    final iconName = category!["icon"]?.toString() ?? 'restaurant';
    final color = category!["color"] as Color? ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 25.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              name,
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
