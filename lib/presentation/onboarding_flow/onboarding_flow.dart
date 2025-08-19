import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/progress_indicator_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Discover Premium Sushi",
      "description":
          "Browse our curated selection of fresh sushi and rolls crafted by expert chefs with the finest ingredients.",
      "image":
          "https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?fm=jpg&q=80&w=1000",
      "backgroundColor": Color(0xFFF8F9FA),
      "iconName": "restaurant_menu",
    },
    {
      "title": "Order with Ease",
      "description":
          "Simple ordering process with customization options, secure payments, and real-time order tracking.",
      "image":
          "https://images.pexels.com/photos/4393021/pexels-photo-4393021.jpeg?auto=compress&cs=tinysrgb&w=1000",
      "backgroundColor": Color(0xFFF1F8FF),
      "iconName": "shopping_cart",
    },
    {
      "title": "Track Your Delivery",
      "description":
          "Real-time delivery tracking with GPS integration and instant notifications for order updates.",
      "image":
          "https://images.pixabay.com/photo/2017/12/09/08/18/pizza-3007395_1280.jpg",
      "backgroundColor": Color(0xFFF0FFF4),
      "iconName": "delivery_dining",
    },
    {
      "title": "Earn Loyalty Rewards",
      "description":
          "Collect points with every order and unlock exclusive rewards, discounts, and premium benefits.",
      "image":
          "https://images.unsplash.com/photo-1553621042-f6e147245754?fm=jpg&q=80&w=1000",
      "backgroundColor": Color(0xFFFFF8F0),
      "iconName": "card_giftcard",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToHome();
    }
  }

  void _skipOnboarding() {
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home-screen');
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _onboardingData[_currentPage]["backgroundColor"] as Color,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: ProgressIndicatorWidget(
                currentPage: _currentPage,
                totalPages: _onboardingData.length,
              ),
            ),

            // Skip Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.lightTheme.colorScheme.primary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    ),
                    child: Text(
                      'Skip',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: OnboardingPageWidget(
                      title: _onboardingData[index]["title"] as String,
                      description:
                          _onboardingData[index]["description"] as String,
                      imageUrl: _onboardingData[index]["image"] as String,
                      iconName: _onboardingData[index]["iconName"] as String,
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => Container(
                        margin: EdgeInsets.only(right: 2.w),
                        width: _currentPage == index ? 8.w : 2.w,
                        height: 1.h,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1.h),
                        ),
                      ),
                    ),
                  ),

                  // Next/Get Started Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor:
                          AppTheme.lightTheme.colorScheme.onPrimary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 2.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _onboardingData.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: AppTheme.lightTheme.textTheme.labelLarge
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        CustomIconWidget(
                          iconName: _currentPage == _onboardingData.length - 1
                              ? 'arrow_forward'
                              : 'arrow_forward_ios',
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          size: 18,
                        ),
                      ],
                    ),
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
