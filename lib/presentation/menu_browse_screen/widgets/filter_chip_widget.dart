import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? count;

  const FilterChipWidget({
    Key? key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.count,
  }) : super(key: key);

  String _getDisplayLabel() {
    switch (label) {
      case 'vegetarian':
        return 'Vegetarian';
      case 'gluten-free':
        return 'Gluten Free';
      case 'rolls':
        return 'Rolls';
      case 'nigiri':
        return 'Nigiri';
      case 'sashimi':
        return 'Sashimi';
      default:
        return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 2.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.dividerColor,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getDisplayLabel(),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: isActive
                      ? AppTheme.lightTheme.colorScheme.onPrimary
                      : AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              if (count != null && count! > 0) ...[
                SizedBox(width: 1.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (isActive) ...[
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
