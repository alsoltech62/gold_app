import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: const Text('ABOUT US'),
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(color: const Color(0xFFB08D57), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB08D57).withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset('assets/icon/newlogo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 18),
            const Text(
              'GoldBarPe',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFB08D57).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFB08D57).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified, color: Color(0xFFB08D57), size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Owned by Jaherkhabar media private limited',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB08D57),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'About the Platform',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Welcome to GoldBarPe, India\'s premier digital precious metals investment platform. We enable you to save, buy, sell, and redeem 24K pure 99.9% hallmarked gold and 99.9% fine silver securely starting from just ₹10.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Every gram of digital gold you buy is backed 100% by physical gold securely held in insured vaults. Seamlessly track live market rates, automate daily/weekly/monthly SIPs, and request doorstep delivery of physical gold anytime.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(Icons.security, '100% Insured & Secured Vaults'),
                  const Divider(color: Colors.white10, height: 24),
                  _buildFeatureRow(Icons.check_circle_outline, '24K 99.9% Hallmarked Pure Gold'),
                  const Divider(color: Colors.white10, height: 24),
                  _buildFeatureRow(Icons.local_shipping_outlined, 'Insured Doorstep Delivery Across India'),
                  const Divider(color: Colors.white10, height: 24),
                  _buildFeatureRow(Icons.autorenew, 'Automated Micro-SIPs & Instant Liquidity'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '© ${DateTime.now().year} Jaherkhabar media private limited. All rights reserved.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB08D57), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
