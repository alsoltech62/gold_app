import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../providers/gold_provider.dart';
import '../../providers/auth_provider.dart';
import 'lock_in_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyGoldScreen extends StatefulWidget {
  const BuyGoldScreen({super.key});

  @override
  State<BuyGoldScreen> createState() => _BuyGoldScreenState();
}

class _BuyGoldScreenState extends State<BuyGoldScreen> {
  final _amountController = TextEditingController();
  double _grams = 0.0;
  String _paymentMethod = 'RRFINCO';
  bool _isProcessingPayment = false;
  
  @override
  void initState() {
    super.initState();
  }

  // Cashfree callbacks removed

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }


  void _calculateGrams(String value) {
    if (value.isEmpty) {
      setState(() => _grams = 0.0);
      return;
    }
    final amount = double.tryParse(value) ?? 0.0;
    final rateRaw = Provider.of<GoldProvider>(context, listen: false).currentRate?['rate_per_gram'];
    final rate = rateRaw != null ? double.tryParse(rateRaw.toString()) ?? 0.0 : 0.0;
    if (rate > 0) {
      setState(() => _grams = amount / rate);
    }
  }

  void _handleBuy() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum investment is ₹100')));
      return;
    }

    final goldProvider = Provider.of<GoldProvider>(context, listen: false);

    if (_paymentMethod == 'RRFINCO') {
      setState(() => _isProcessingPayment = true);
      final response = await goldProvider.createPaymentOrder(amount);
      if (response['success'] == true) {
        final paymentUrl = response['data']['payment_url'];
        final orderId = response['data']['order_id'];
        
        try {
          final Uri url = Uri.parse(paymentUrl);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch payment URL'), backgroundColor: Colors.red));
          } else {
            if (mounted) {
              _showPaymentVerificationDialog(amount, orderId);
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Could not create order'), backgroundColor: Colors.red));
      }
      setState(() => _isProcessingPayment = false);
      return;
    }

    if (_paymentMethod != 'UPI' && _paymentMethod != 'RRFINCO') {
      final result = await goldProvider.buyGold(amount, _paymentMethod, 'WALLET_TXN');
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gold purchased successfully!')));
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockInScreen(metalType: 'gold')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Transaction failed.'), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() => _isProcessingPayment = true);
    
    // Show Manual UPI Dialog
    setState(() => _isProcessingPayment = false);
    
    final utrController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFB08D57).withOpacity(0.3)),
        ),
        title: const Text('Complete UPI Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please transfer exactly to the UPI ID below and enter the UTR/Reference ID to verify.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('goldbindia@oksbi', style: TextStyle(color: Color(0xFFB08D57), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'goldbindia@oksbi'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID Copied!')));
                    },
                    child: const Icon(Icons.copy, color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: utrController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'UTR / Reference ID',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFB08D57))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB08D57), foregroundColor: Colors.black),
            onPressed: () async {
              if (utrController.text.length < 6) return;
              Navigator.pop(dialogContext);
              setState(() => _isProcessingPayment = true);
              
              final result = await goldProvider.buyGold(amount, 'UPI', utrController.text);
              if (!mounted) return;
              setState(() => _isProcessingPayment = false);
              
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gold purchased successfully!')));
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockInScreen(metalType: 'gold')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Transaction failed.'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Verify Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _showPaymentVerificationDialog(double amount, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFB08D57).withOpacity(0.3)),
        ),
        title: const Text('Payment Verification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Did you complete the payment in the browser? Click below to verify and add gold to your vault.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB08D57), foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isProcessingPayment = true);
              
              final result = await Provider.of<GoldProvider>(context, listen: false).buyGold(amount, 'RRFINCO', orderId);
              if (!mounted) return;
              setState(() => _isProcessingPayment = false);
              
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gold purchased successfully!')));
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockInScreen(metalType: 'gold')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Payment verification failed.'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Yes, Check Status', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BUY GOLD')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invest in 24K Pure Gold',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ).animate().fadeIn(),
            const SizedBox(height: 10),
            const Text(
              'Safe, secure and 100% insured',
              style: TextStyle(color: Colors.grey),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 40),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFB08D57)),
              onChanged: _calculateGrams,
              decoration: const InputDecoration(
                labelText: 'Enter Amount',
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFB08D57)),
                suffixIcon: Icon(Icons.currency_rupee, color: Color(0xFFB08D57)),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            if (_grams > 0)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFB08D57).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB08D57).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFB08D57), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'You will receive: ${_grams.toStringAsFixed(4)} grams',
                      style: const TextStyle(color: Color(0xFFB08D57), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),
            const SizedBox(height: 40),
            const Text(
              'Popular Amounts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [500, 1000, 2000, 5000].map((amt) {
                return InkWell(
                  onTap: () {
                    _amountController.text = amt.toString();
                    _calculateGrams(amt.toString());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text('₹$amt', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 40),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'RRFINCO', child: Text('Direct / UPI / Cards')),
                DropdownMenuItem(value: 'UPI', child: Text('Manual UPI Transfer')),
                DropdownMenuItem(value: 'inr_wallet', child: Text('INR Wallet Balance')),
                DropdownMenuItem(value: 'japsan_wallet', child: Text('Japsan Wallet Balance')),
                DropdownMenuItem(value: 'silver_wallet', child: Text('Silver Wallet (Sell Silver to Buy Gold)')),
              ],
              onChanged: (val) => setState(() => _paymentMethod = val!),
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              child: Consumer<GoldProvider>(
                builder: (context, gold, child) {
                  return ElevatedButton(
                    onPressed: (gold.isLoading || _isProcessingPayment) ? null : _handleBuy,
                    child: (gold.isLoading || _isProcessingPayment)
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('PROCEED TO PAYMENT'),
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
