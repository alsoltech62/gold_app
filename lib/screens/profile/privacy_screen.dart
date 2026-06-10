import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRIVACY POLICY')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Color(0xFFFFD700), size: 30),
                SizedBox(width: 15),
                Text('Privacy Policy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 20),
            Text('1. Information Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'We collect information you provide directly to us, such as when you create or modify your account, request services, contact customer support, or otherwise communicate with us.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            SizedBox(height: 20),
            Text('2. Use of Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'We use the information we collect to provide, maintain, and improve our services, process transactions, and send related information, including confirmations and receipts.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            SizedBox(height: 20),
            Text('3. Data Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'We take reasonable measures to help protect information about you from loss, theft, misuse and unauthorized access, disclosure, alteration and destruction.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
