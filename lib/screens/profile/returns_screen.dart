import 'package:flutter/material.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RETURNS POLICY')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_return, color: Color(0xFFFFD700), size: 30),
                SizedBox(width: 15),
                Text('Returns Policy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 20),
            Text('1. Physical Delivery Returns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'Due to the nature of precious metals, physical delivery of gold and silver coins/bars cannot be returned once dispatched, unless the product is damaged or tampered with during transit.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            SizedBox(height: 20),
            Text('2. Digital Assets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'Digital gold and silver can be sold back to the platform at any time at the prevailing sell rate. We do not charge any hidden cancellation fees.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            SizedBox(height: 20),
            Text('3. Claim Process', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
            SizedBox(height: 5),
            Text(
              'For any disputes regarding physical delivery, please raise a support ticket within 24 hours of delivery along with an unboxing video.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
