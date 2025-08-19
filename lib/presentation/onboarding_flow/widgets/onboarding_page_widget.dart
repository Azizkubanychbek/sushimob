import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String iconName;

  const OnboardingPageWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.iconName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 4.h),

            // Feature Icon
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: iconName,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 8.w,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Main Image with Parallax Effect
            Container(
              width: 80.w,
              height: 35.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20.0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  width: 80.w,
                  height: 35.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(height: 6.h),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.lightTheme.colorScheme.onSurface,
                height: 1.2,
              ),
            ),

            SizedBox(height: 2.h),

            // Description
            Container(
              constraints: BoxConstraints(maxWidth: 85.w),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                  height: 1.5,
                  fontSize: 16.sp,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Feature Highlights
            _buildFeatureHighlights(),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    List<Map<String, String>> highlights = [];

    switch (iconName) {
      case 'restaurant_menu':
        highlights = [
          {"icon": "star", "text": "Premium Quality"},
          {"icon": "local_dining", "text": "Fresh Daily"},
          {"icon": "verified", "text": "Expert Chefs"},
        ];
        break;
      case 'shopping_cart':
        highlights = [
          {"icon": "touch_app", "text": "Easy Ordering"},
          {"icon": "payment", "text": "Secure Payment"},
          {"icon": "tune", "text": "Customizable"},
        ];
        break;
      case 'delivery_dining':
        highlights = [
          {"icon": "location_on", "text": "GPS Tracking"},
          {"icon": "schedule", "text": "Real-time Updates"},
          {"icon": "notifications", "text": "Instant Alerts"},
        ];
        break;
      case 'card_giftcard':
        highlights = [
          {"icon": "loyalty", "text": "Earn Points"},
          {"icon": "redeem", "text": "Exclusive Rewards"},
          {"icon": "workspace_premium", "text": "VIP Benefits"},
        ];
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: highlights.map((highlight) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: highlight["icon"]!,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 5.w,
                ),
                SizedBox(height: 1.h),
                Text(
                  highlight["text"]!,
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
