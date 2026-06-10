import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'buy_gold_screen.dart';
import 'sip_screen.dart';

class BuyFlowScreen extends StatelessWidget {
  const BuyFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Gold'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Choose your preferred investment method',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ).animate().fadeIn(),
            const SizedBox(height: 30),
            
            _buildOptionCard(
              context: context,
              title: 'Invest One Time',
              subtitle: 'Make a single purchase at the current market rate and add it directly to your vault.',
              icon: Icons.shopping_cart,
              color: const Color(0xFFFFD700),
              target: const BuyGoldScreen(),
            ).animate().slideX(),
            
            const SizedBox(height: 20),
            
            _buildOptionCard(
              context: context,
              title: 'SIP Investment',
              subtitle: 'Automate your investments with regular installments to average out the market price.',
              icon: Icons.calendar_today,
              color: Colors.green,
              target: const SipScreen(),
            ).animate().slideX(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget target,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
