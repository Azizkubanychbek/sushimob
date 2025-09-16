import 'package:flutter/material.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/menu_browse_screen/menu_browse_screen.dart';
import '../presentation/sets_browse_screen/sets_browse_screen.dart';
import '../presentation/shopping_cart_screen/shopping_cart_screen.dart';
import '../presentation/favorites_screen/favorites_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/product_detail_screen/product_detail_screen.dart';
import '../presentation/set_detail_screen/set_detail_screen.dart';
import '../presentation/auth_screen/auth_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/debug/debug_page.dart';
import '../presentation/admin_screen/admin_screen.dart';
import '../presentation/checkout_screen/checkout_screen.dart';
import '../presentation/loyalty_screen/loyalty_screen.dart';
import '../presentation/referral_screen/referral_screen.dart';
import '../presentation/address_selection_screen/interactive_map_screen.dart';
import '../presentation/address_selection_screen/universal_2gis_map_screen.dart';
import '../presentation/orders_screen/orders_screen.dart';
import '../presentation/chef_screen/chef_dashboard_screen.dart';
import 'package:latlong2/latlong.dart';

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
  static const String setDetailScreen = '/set-detail-screen';
  static const String loginScreen = '/login-screen';
  static const String registerScreen = '/register-screen';
  static const String debugPage = '/debug-page';
  static const String adminScreen = '/admin-screen';
  static const String checkoutScreen = '/checkout-screen';
  static const String loyaltyScreen = '/loyalty-screen';
  static const String referralScreen = '/referral-screen';
  static const String interactiveMapScreen = '/interactive-map-screen';
  static const String twogisMapScreen = '/twogis-map-screen';
  static const String ordersScreen = '/orders-screen';
  static const String chefDashboardScreen = '/chef-dashboard-screen';

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
    setDetailScreen: (context) => const SetDetailScreen(setId: 1), // Заглушка, setId будет передаваться через Navigator
    loginScreen: (context) => const LoginScreen(),
    registerScreen: (context) => const RegisterScreen(),
    debugPage: (context) => const DebugPage(),
    adminScreen: (context) => const AdminScreen(),
    checkoutScreen: (context) => const CheckoutScreen(),
    loyaltyScreen: (context) => const LoyaltyScreen(),
    referralScreen: (context) => const ReferralScreen(),
    interactiveMapScreen: (context) => InteractiveMapScreen(
      onAddressSelected: (addressInfo) {
        Navigator.of(context).pop(addressInfo);
      },
    ),
    twogisMapScreen: (context) => Universal2GisMapScreen(
      initialCenter: const LatLng(42.8746, 74.5698), // Центр Бишкека
      onLocationSelected: (coordinates, address) {
        Navigator.of(context).pop();
      },
    ),
    ordersScreen: (context) => const OrdersScreen(),
    chefDashboardScreen: (context) => const ChefDashboardScreen(),
    // TODO: Add your other routes here
  };
}
