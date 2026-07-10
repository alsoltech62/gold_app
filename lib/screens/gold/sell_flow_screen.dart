import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'sell_gold_screen.dart';
import '../silver/sell_silver_screen.dart';
import 'lock_in_screen.dart';

class SellFlowScreen extends StatefulWidget {
  final String initialMetalType;
  const SellFlowScreen({super.key, this.initialMetalType = 'gold'});

  @override
  State<SellFlowScreen> createState() => _SellFlowScreenState();
}

class _SellFlowScreenState extends State<SellFlowScreen> {
  late String metalType;

  @override
  void initState() {
    super.initState();
    metalType = widget.initialMetalType;
  }

  @override
  Widget build(BuildContext context) {
    bool isGold = metalType == 'gold';
    Color themeColor = isGold ? const Color(0xFFFFD700) : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sell ${isGold ? 'Gold' : 'Silver'}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Choose how you want to liquidate your assets',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => metalType = 'gold'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: isGold ? const Color(0xFFFFD700) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isGold ? [
                          BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 15)
                        ] : [],
                      ),
                      child: Text(
                        'Sell Gold',
                        style: TextStyle(
                          color: isGold ? Colors.black : Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => metalType = 'silver'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: !isGold ? Colors.grey[300] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !isGold ? [
                          BoxShadow(color: Colors.grey.withOpacity(0.4), blurRadius: 15)
                        ] : [],
                      ),
                      child: Text(
                        'Sell Silver',
                        style: TextStyle(
                          color: !isGold ? Colors.black : Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            
            const SizedBox(height: 30),
            
            _buildOptionCard(
              context: context,
              title: 'Get up to 12% Extra',
              subtitle: 'Instead of selling now, lock your $metalType in our vault for 6-36 months and earn up to 12% guaranteed extra returns.',
              icon: Icons.lock,
              color: themeColor,
              target: LockInScreen(metalType: metalType),
              isRecommended: true,
            ).animate().slideX(),
            
            const SizedBox(height: 20),
            
            _buildOptionCard(
              context: context,
              title: 'Sell Anyway',
              subtitle: 'Liquidate your $metalType immediately at the current market rate. Funds will be transferred to your wallet instantly.',
              icon: Icons.account_balance_wallet,
              color: Colors.red,
              target: isGold ? const SellGoldScreen() : const SellSilverScreen(),
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
    bool isRecommended = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
          if (isRecommended)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFBF953F), Color(0xFFFCF6BA)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
