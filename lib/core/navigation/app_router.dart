import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/student_register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/password_success_screen.dart';
import '../../features/home/home_dashboard_screen.dart';
import '../../features/home/happy_hour_list_screen.dart';
import '../../features/marketplace/market_list_screen.dart';
import '../../features/marketplace/happy_hour_offer_detail_screen.dart';
import '../../features/marketplace/happy_hour_checkout_screen.dart';
import '../../features/restaurant/restaurant_list_screen.dart';
import '../../features/restaurant/restaurant_detail_screen.dart';
import '../../features/restaurant/menu_item_detail_screen.dart';
import '../../features/events/events_discovery_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/digital_ticket_screen.dart';
import '../../features/events/ticket_success_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/orders/order_tracking_screen.dart';
import '../../features/orders/order_receipt_screen.dart';
import '../../features/profile/pro_points_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../features/profile/payment_methods_screen.dart';
import '../../features/profile/account_settings_screen.dart';
import '../../features/profile/help_center_screen.dart';
import '../../features/profile/app_map_screen.dart';
import '../../features/restaurant/restaurant_data.dart';
import '../../features/events/event_data.dart';

/// Route paths
class AppRoutes {
  static const String onboarding = '/onboarding/:step';
  static const String login = '/login';
  static const String register = '/register';
  static const String studentRegister = '/student-register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/reset-password';
  static const String passwordSuccess = '/password-success';
  static const String home = '/';
  static const String marketList = '/market';
  static const String happyHourList = '/happy-hour';
  static const String happyHourDetail = '/happy-hour/detail';
  static const String happyHourCheckout = '/happy-hour/checkout';
  static const String restaurantList = '/restaurants';
  static const String restaurantDetail = '/restaurants/:id';
  static const String menuItemDetail = '/menu-item';
  static const String eventsDiscovery = '/events';
  static const String eventDetail = '/events/detail';
  static const String digitalTicket = '/digital-ticket';
  static const String ticketSuccess = '/ticket-success';
  static const String orderHistory = '/orders';
  static const String orderTracking = '/orders/tracking';
  static const String orderReceipt = '/orders/receipt';
  static const String proPoints = '/pro-points';
  static const String addresses = '/addresses';
  static const String paymentMethods = '/payment-methods';
  static const String accountSettings = '/account-settings';
  static const String helpCenter = '/help-center';
  static const String appMap = '/app-map';
}

/// GoRouter provider
final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: isAuthenticated ? AppRoutes.home : '/onboarding/0',
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding/:step',
        builder: (context, state) {
          final step = int.tryParse(state.pathParameters['step'] ?? '0') ?? 0;
          return OnboardingScreen(step: step);
        },
      ),

      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/student-register', builder: (_, __) => const StudentEmailRegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/otp-verification', builder: (_, __) => const OtpVerificationScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/password-success', builder: (_, __) => const PasswordSuccessScreen()),

      // Home
      GoRoute(path: '/', builder: (_, __) => const HomeDashboardScreen()),

      // Marketplace
      GoRoute(path: '/market', builder: (_, __) => const MarketListScreen()),
      GoRoute(path: '/happy-hour', builder: (_, __) => const HappyHourListScreen()),
      GoRoute(path: '/happy-hour/detail', builder: (_, __) => const HappyHourOfferDetailScreen()),
      GoRoute(path: '/happy-hour/checkout', builder: (_, __) => const HappyHourCheckoutScreen()),

      // Restaurants
      GoRoute(path: '/restaurants', builder: (_, __) => const RestaurantListScreen()),
      GoRoute(
        path: '/restaurants/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ??
              (restaurantCards.isNotEmpty ? restaurantCards.first.id : defaultRestaurantCatalog().first.id);
          return RestaurantDetailScreen(restaurantId: id);
        },
      ),
      GoRoute(path: '/menu-item', builder: (_, __) => const MenuItemDetailScreen()),

      // Events
      GoRoute(path: '/events', builder: (_, __) => const EventsDiscoveryScreen()),
      GoRoute(path: '/events/detail', builder: (_, __) => const EventDetailScreen()),
      GoRoute(path: '/digital-ticket', builder: (_, __) => const DigitalTicketScreen()),
      GoRoute(path: '/ticket-success', builder: (_, __) => const TicketSuccessScreen()),

      // Orders
      GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(path: '/orders/tracking', builder: (_, __) => const OrderTrackingScreen()),
      GoRoute(path: '/orders/receipt', builder: (_, __) => const OrderReceiptScreen()),

      // Profile
      GoRoute(path: '/pro-points', builder: (_, __) => const ProPointsScreen()),
      GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
      GoRoute(path: '/payment-methods', builder: (_, __) => const PaymentMethodsScreen()),
      GoRoute(path: '/account-settings', builder: (_, __) => const AccountSettingsScreen()),
      GoRoute(path: '/help-center', builder: (_, __) => const HelpCenterScreen()),
      GoRoute(path: '/app-map', builder: (_, __) => const AppMapScreen()),
    ],
  );
});
