import 'package:flutter/material.dart';

import 'screen_enum.dart';
import '../../core/theme/palette.dart';

// Feature screen imports
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

Widget buildSpetoScreen(SpetoScreen screen) {
  switch (screen) {
    case SpetoScreen.onboardingMarket:
      return const OnboardingScreen(step: 0);
    case SpetoScreen.onboardingRestaurant:
      return const OnboardingScreen(step: 1);
    case SpetoScreen.onboardingDeals:
      return const OnboardingScreen(step: 2);
    case SpetoScreen.onboardingStudent:
      return const OnboardingScreen(step: 3);
    case SpetoScreen.onboardingPro:
      return const OnboardingScreen(step: 4);
    case SpetoScreen.login:
      return const LoginScreen();
    case SpetoScreen.register:
      return const RegisterScreen();
    case SpetoScreen.studentRegister:
      return const StudentEmailRegisterScreen();
    case SpetoScreen.forgotPassword:
      return const ForgotPasswordScreen();
    case SpetoScreen.otpVerification:
      return const OtpVerificationScreen();
    case SpetoScreen.resetPassword:
      return const ResetPasswordScreen();
    case SpetoScreen.passwordSuccess:
      return const PasswordSuccessScreen();
    case SpetoScreen.home:
      return const HomeDashboardScreen();
    case SpetoScreen.marketList:
      return const MarketListScreen();
    case SpetoScreen.happyHourList:
      return const HappyHourListScreen();
    case SpetoScreen.happyHourDetail:
      return const HappyHourOfferDetailScreen();
    case SpetoScreen.happyHourCheckout:
      return const HappyHourCheckoutScreen();
    case SpetoScreen.restaurantList:
      return const RestaurantListScreen();
    case SpetoScreen.restaurantDetail:
      return const RestaurantDetailScreen();
    case SpetoScreen.menuItemDetail:
      return const MenuItemDetailScreen();
    case SpetoScreen.eventsDiscovery:
      return const EventsDiscoveryScreen();
    case SpetoScreen.eventDetail:
      return const EventDetailScreen();
    case SpetoScreen.digitalTicket:
      return const DigitalTicketScreen();
    case SpetoScreen.ticketSuccess:
      return const TicketSuccessScreen();
    case SpetoScreen.orderHistory:
      return const OrderHistoryScreen();
    case SpetoScreen.orderTracking:
      return const OrderTrackingScreen();
    case SpetoScreen.orderReceipt:
      return const OrderReceiptScreen();
    case SpetoScreen.proPoints:
      return const ProPointsScreen();
    case SpetoScreen.addresses:
      return const AddressesScreen();
    case SpetoScreen.paymentMethods:
      return const PaymentMethodsScreen();
    case SpetoScreen.accountSettings:
      return const AccountSettingsScreen();
    case SpetoScreen.helpCenter:
      return const HelpCenterScreen();
    case SpetoScreen.appMap:
      return const AppMapScreen();
  }
}

void openScreen(BuildContext context, SpetoScreen screen) {
  Navigator.of(context).push(spetoRoute(buildSpetoScreen(screen)));
}

void openRootScreen(BuildContext context, SpetoScreen screen) {
  Navigator.of(
    context,
  ).pushAndRemoveUntil(spetoRoute(buildSpetoScreen(screen)), (_) => false);
}

Route<void> spetoRoute(Widget child) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 440),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return ColoredBox(color: Palette.base, child: child);
        },
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget routeChild,
        ) {
          final Animation<double> curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0.72, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.014, 0.008),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.998, end: 1).animate(curved),
                child: routeChild,
              ),
            ),
          );
        },
  );
}
