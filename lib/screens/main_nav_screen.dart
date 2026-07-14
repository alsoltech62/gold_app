import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'wallet/wallet_screen.dart';
import 'delivery/delivery_screen.dart';
import 'profile/profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const WalletScreen(),
    const DeliveryScreen(initialMetalType: 'gold'), // Defaulting to gold for now
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070707),
          border: Border(top: BorderSide(color: const Color(0xFFB08D57).withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF070707),
          selectedItemColor: const Color(0xFFB08D57),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'DASHBOARD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'WALLET',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              label: 'DELIVERY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
