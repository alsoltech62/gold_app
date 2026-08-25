import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/gold_provider.dart';

class SellSilverScreen extends StatefulWidget {
  const SellSilverScreen({super.key});

  @override
  State<SellSilverScreen> createState() => _SellSilverScreenState();
}

class _SellSilverScreenState extends State<SellSilverScreen> {
  final _gramsController = TextEditingController();
  final _upiIdController = TextEditingController();
  double _amount = 0.0;

  void _calculateAmount(String value) {
    if (value.isEmpty) {
      setState(() => _amount = 0.0);
      return;
    }
    final grams = double.tryParse(value) ?? 0.0;
    final currentRateObj = Provider.of<GoldProvider>(context, listen: false).silverRate;
    final rateRaw = currentRateObj?['sell_rate_per_gram'] ?? currentRateObj?['rate_per_gram'];
    final rate = rateRaw != null ? double.tryParse(rateRaw.toString()) ?? 0.0 : 0.0;
    if (rate > 0) {
      setState(() => _amount = grams * rate);
    }
  }

  void _handleSell() async {
    final grams = double.tryParse(_gramsController.text) ?? 0.0;
    if (grams <= 0) return;

    final upiId = _upiIdController.text.trim();
    if (upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your UPI ID for instant payout.')),
      );
      return;
    }

    final goldProvider = Provider.of<GoldProvider>(context, listen: false);
    final result = await goldProvider.sellSilver(grams, upiId: upiId);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sell request submitted! Funds will be instantly credited to your UPI.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit request.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalGrams = Provider.of<GoldProvider>(context).dashboardData?['total_silver_grams'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('SELL SILVER')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sell back your Silver',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ).animate().fadeIn(),
            const SizedBox(height: 10),
            Text(
              'Available Balance: ${totalGrams.toStringAsFixed(4)} gms',
              style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 40),
            TextField(
              controller: _gramsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              onChanged: _calculateAmount,
              decoration: const InputDecoration(
                labelText: 'Enter Grams',
                suffixText: 'gms',
                suffixStyle: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            TextField(
              controller: _upiIdController,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Payout UPI ID',
                hintText: 'yourname@upi',
              ),
            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            if (_amount > 0)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.currency_rupee, color: Colors.grey, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'You will receive: ₹${_amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),
            const SizedBox(height: 40),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'The amount will be instantly credited to your provided UPI ID.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              child: Consumer<GoldProvider>(
                builder: (context, gold, child) {
                  return ElevatedButton(
                    onPressed: gold.isLoading ? null : _handleSell,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: gold.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('SUBMIT SELL REQUEST'),
                  );
                },
              ),
            ).animate().fadeIn(delay: 800.ms).scale(),
          ],
        ),
      ),
    );
  }
}
