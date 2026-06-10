import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TERMS & CONDITIONS')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Color(0xFFFFD700), size: 30),
                SizedBox(width: 15),
                Text('Terms & Conditions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 20),
            Text('1. Agreement to Terms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'By accessing or using our platform, you agree to be bound by these Terms and Conditions. If you disagree with any part of the terms, then you may not access the service.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            SizedBox(height: 20),
            Text('2. Digital Gold and Silver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'The digital gold and silver purchased on our platform represent physical bullion stored securely. The live rates fluctuate based on market conditions.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            SizedBox(height: 20),
            Text('3. Wallet and SIP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'Funds added to the INR Wallet can be used to purchase gold or silver. The SIP feature automates purchases based on your settings. All investments carry market risk.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
