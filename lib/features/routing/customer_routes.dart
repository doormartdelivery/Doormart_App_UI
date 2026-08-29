import 'package:flutter/material.dart';

import '../../views/user/address_screen.dart';
import '../../views/user/cart_screen.dart';
import '../../views/user/checkout_screen.dart';
import '../../views/user/forgot_password_screen.dart';
import '../../views/user/help_support_screen.dart';
import '../../views/user/login_screen.dart';
import '../../views/user/my_orders_screen.dart';
import '../../views/user/notification_screen.dart';
import '../../views/user/order_success_screen.dart';
import '../../views/user/product_category_screen.dart';
import '../../views/user/product_list_screen.dart';
import '../../views/user/search_screen.dart';
import '../../views/user/payment_screen.dart';
import '../../views/user/privacy_policy_screen.dart';
import '../../views/user/profile_screen.dart';
import '../../views/user/product_details_screen.dart';
import '../../views/user/scheduled_order_screen.dart';
import '../../views/user/signup_screen.dart';
import '../../views/user/splash_screen.dart';
import '../../views/user/user_home_screen.dart';
import '../../views/user/wishlist_screen.dart';

class CustomerRoutes {
  static Map<String, WidgetBuilder> get routes => {
    SplashScreen.routeName: (_) => const SplashScreen(),
    UserHomeScreen.routeName: (_) => const UserHomeScreen(),
    LoginScreen.routeName: (_) => const LoginScreen(),
    ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
    SignupScreen.routeName: (_) => const SignupScreen(),
    SearchScreen.routeName: (_) => const SearchScreen(),
    ProductListScreen.routeName: (_) => const ProductListScreen(),
    ProductDetailsScreen.routeName: (_) => const ProductDetailsScreen(),
    ProductCategoryScreen.routeName: (_) => const ProductCategoryScreen(),
    CartScreen.routeName: (_) => const CartScreen(),
    CheckoutScreen.routeName: (_) => const CheckoutScreen(),
    PaymentScreen.routeName: (_) => const PaymentScreen(),
    OrderSuccessScreen.routeName: (_) => const OrderSuccessScreen(),
    ScheduledOrderScreen.routeName: (_) => const ScheduledOrderScreen(),
    MyOrdersScreen.routeName: (_) => const MyOrdersScreen(),
    AddressScreen.routeName: (_) => const AddressScreen(),
    HelpSupportScreen.routeName: (_) => const HelpSupportScreen(),
    NotificationScreen.routeName: (_) => const NotificationScreen(),
    ProfileScreen.routeName: (_) => const ProfileScreen(),
    WishlistScreen.routeName: (_) => const WishlistScreen(),
    PrivacyPolicyScreen.routeName: (_) => const PrivacyPolicyScreen(),
  };
}
