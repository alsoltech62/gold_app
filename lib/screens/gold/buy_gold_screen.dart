import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../providers/gold_provider.dart';
import '../../providers/auth_provider.dart';
import 'lock_in_modal.dart';

class BuyGoldScreen extends StatefulWidget {
  const BuyGoldScreen({super.key});

  @override
  State<BuyGoldScreen> createState() => _BuyGoldScreenState();
}

class _BuyGoldScreenState extends State<BuyGoldScreen> {
  final _amountController = TextEditingController();
  double _grams = 0.0;
  String _paymentMethod = 'UPI';
  late Razorpay _razorpay;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final goldProvider = Provider.of<GoldProvider>(context, listen: false);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    final result = await goldProvider.buyGold(
      amount, 
      'UPI', 
      response.paymentId ?? '',
      razorpayOrderId: response.orderId,
      razorpaySignature: response.signature,
    );
    
    setState(() => _isProcessingPayment = false);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gold purchased successfully!')));
      LockInModal.show(
        context: context,
        title: 'Increase Your Returns with Lock-In Investment',
        message: 'If you want, you can get additional returns by locking your gold for a specific period.',
        primaryActionText: 'Lock Now',
        secondaryActionText: 'Skip & Continue',
        onSecondaryAction: () => Navigator.of(context).pop(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Verification failed.'), backgroundColor: Colors.red));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  void _calculateGrams(String value) {
    if (value.isEmpty) {
      setState(() => _grams = 0.0);
      return;
    }
    final amount = double.tryParse(value) ?? 0.0;
    final rate = Provider.of<GoldProvider>(context, listen: false).currentRate?['rate_per_gram'] ?? 0.0;
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

    if (_paymentMethod != 'UPI') {
      final result = await goldProvider.buyGold(amount, _paymentMethod, 'WALLET_TXN');
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gold purchased successfully!')));
        LockInModal.show(
          context: context,
          title: 'Increase Your Returns with Lock-In Investment',
          message: 'If you want, you can get additional returns by locking your gold for a specific period.',
          primaryActionText: 'Lock Now',
          secondaryActionText: 'Skip & Continue',
          onSecondaryAction: () => Navigator.of(context).pop(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Transaction failed.'), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() => _isProcessingPayment = true);
    final orderRes = await goldProvider.createPaymentOrder(amount);
    
    if (orderRes['success'] == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      final orderData = orderRes['data'];
      var options = {
        'key': orderData['key'],
        'amount': orderData['amount'],
        'name': 'GoldVault',
        'description': 'Purchase of ${_grams.toStringAsFixed(4)}g 24K Gold',
        'order_id': orderData['order_id'],
        'prefill': {
          'contact': user?['mobile'] ?? '',
          'name': user?['name'] ?? '',
        },
        'theme': {'color': '#D4AF37'}
      };
      
      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isProcessingPayment = false);
        debugPrint('Error: $e');
      }
    } else {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create payment order.'), backgroundColor: Colors.red));
    }
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
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
              onChanged: _calculateGrams,
              decoration: const InputDecoration(
                labelText: 'Enter Amount',
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                suffixIcon: Icon(Icons.currency_rupee, color: Color(0xFFFFD700)),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            if (_grams > 0)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'You will receive: ${_grams.toStringAsFixed(4)} grams',
                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
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
                DropdownMenuItem(value: 'UPI', child: Text('Direct / Razorpay (UPI)')),
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
