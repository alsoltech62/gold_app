import 'package:flutter/material.dart';

import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        title: Image.asset('assets/images/GoldBarPay.png', height: 40),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text(
                'Start Gold Saving \u2192',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HERO SECTION
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 14),
                        SizedBox(width: 8),
                        Text(
                          "INDIA'S TRUSTED GOLD SAVING PLATFORM",
                          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "START GOLD",
                    style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "FROM ₹1000",
                    style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Convert your savings into real gold and secure your future.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildFeatureIcon(Icons.check_circle, "100% Real Gold"),
                      _buildFeatureIcon(Icons.lock, "Secure & Safe Storage"),
                      _buildFeatureIcon(Icons.local_shipping, "Easy Delivery"),
                      _buildFeatureIcon(Icons.security, "100% Transparent"),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("START GOLD SAVING NOW", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.black, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone, color: Colors.green, size: 16),
                      label: const Text("Or connect on WhatsApp", style: TextStyle(color: Colors.green)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Image.asset('assets/images/gold_bars_hero.png', fit: BoxFit.contain),
                ],
              ),
            ),
            
            // HOW IT WORKS
            Container(
              color: const Color(0xFF0c0c0c),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  const Text("SIMPLE PROCESS", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text("HOW IT WORKS", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  _buildHowItWorksCard("01", Icons.account_balance_wallet, "PAY", "Choose your plan and make payment easily via UPI, Net Banking or Card."),
                  const SizedBox(height: 16),
                  _buildHowItWorksCard("02", Icons.diamond, "CONVERT", "Your money is converted into real gold as per live market rate."),
                  const SizedBox(height: 16),
                  _buildHowItWorksCard("03", Icons.security, "STORE & GROW", "We store your gold securely and you can track your gold anytime."),
                ],
              ),
            ),
            
            // WHY CHOOSE US
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("Why Choose Us", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Why Thousands Trust Goldbar India?", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("We make gold saving easy, secure and transparent for everyone.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Image.asset('assets/images/gold_bangle_feature.png', height: 200, fit: BoxFit.contain),
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(child: _buildGridFeature(Icons.security, "100% Real Gold", "We deal in only 100% hallmarked real gold.")),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGridFeature(Icons.lock, "Secure Storage", "Your gold is stored in highly secure vaults.")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildGridFeature(Icons.local_shipping, "Easy Delivery", "Get physical gold delivered at your doorstep.")),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGridFeature(Icons.thumb_up, "Best Value", "Buy gold at the most competitive rates.")),
                    ],
                  ),
                ],
              ),
            ),
            
            // LIVE GOLD RATE
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bar_chart, color: Color(0xFFD4AF37)),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("LIVE GOLD RATE", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text("Rates updated in real-time", style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("24K Gold (999)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text("₹7,215", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              Text(" /gm", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          border: Border.all(color: Colors.green.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("+1.25%", style: TextStyle(color: Colors.green, fontSize: 12)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            
            // FOOTER CTA
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF15120a), Color(0xFF0a0a0a)]),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text("SECURE TODAY, SHINE TOMORROW", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("Start Your Gold Saving Journey Today!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("Join thousands of smart savers and build your gold wealth with Goldbar India.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 24),
                  Image.asset('assets/images/gold_coins_footer.png', height: 150),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("START NOW \u2192", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String text) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
          ),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(String number, IconData icon, String title, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -36,
            left: -36,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: Text(number, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFFD4AF37).withOpacity(0.2), Colors.transparent]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFD4AF37), size: 32),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridFeature(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
