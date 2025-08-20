import 'package:flutter/material.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/menu_browse_screen/menu_browse_screen.dart';
import '../presentation/sets_browse_screen/sets_browse_screen.dart';
import '../presentation/shopping_cart_screen/shopping_cart_screen.dart';
import '../presentation/favorites_screen/favorites_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/product_detail_screen/product_detail_screen.dart';
import '../presentation/auth_screen/auth_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/debug/debug_page.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String auth = '/auth';
  static const String onboardingFlow = '/onboarding-flow';
  static const String userProfileScreen = '/user-profile-screen';
  static const String menuBrowseScreen = '/menu-browse-screen';
  static const String setsBrowseScreen = '/sets-browse-screen';
  static const String shoppingCartScreen = '/shopping-cart-screen';
  static const String favoritesScreen = '/favorites-screen';
  static const String homeScreen = '/home-screen';
  static const String productDetailScreen = '/product-detail-screen';
  static const String loginScreen = '/login-screen';
  static const String registerScreen = '/register-screen';
  static const String debugPage = '/debug-page';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeScreen(),
    auth: (context) => const AuthScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    userProfileScreen: (context) => const UserProfileScreen(),
    menuBrowseScreen: (context) => const MenuBrowseScreen(),
    setsBrowseScreen: (context) => const SetsBrowseScreen(),
    shoppingCartScreen: (context) => const ShoppingCartScreen(),
    favoritesScreen: (context) => const FavoritesScreen(),
    homeScreen: (context) => const HomeScreen(),
    productDetailScreen: (context) => const ProductDetailScreen(),
    loginScreen: (context) => const LoginScreen(),
    registerScreen: (context) => const RegisterScreen(),
    debugPage: (context) => const DebugPage(),
    // TODO: Add your other routes here
  };
}
