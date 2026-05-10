import 'package:flutter/material.dart';

import '../../widgets/custom_bottom_nav.dart';
import 'overview_screen.dart';
import 'products_screen.dart';
import 'orders_screen.dart';
import 'campaigns_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = <Widget>[
      OverviewScreen(
        onOpenOrders: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        onOpenProducts: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        onOpenCampaigns: () {
          setState(() {
            _currentIndex = 3;
          });
        },
      ),
      const OrdersScreen(),
      ProductsScreen(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      CampaignsScreen(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
        onOpenProducts: () {
          setState(() {
            _currentIndex = 2;
          });
        },
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
