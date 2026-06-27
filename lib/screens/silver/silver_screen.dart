import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../providers/gold_provider.dart';
import '../../providers/auth_provider.dart';
import '../gold/lock_in_modal.dart';

class SilverScreen extends StatefulWidget {
  final bool initialIsBuy;
  const SilverScreen({super.key, this.initialIsBuy = true});

  @override
  State<SilverScreen> createState() => _SilverScreenState();
}

class _SilverScreenState extends State<SilverScreen> {
  final TextEditingController _amountController = TextEditingController();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoldProvider>(context, listen: false).fetchSilverRate();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final provider = Provider.of<GoldProvider>(context, listen: false);
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    final result = await provider.buySilver(
      amount, 
      'UPI', 
      paymentId: response.paymentId ?? '',
      razorpayOrderId: response.orderId,
      razorpaySignature: response.signature,
    );
    
    setState(() => _isProcessingPayment = false);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silver purchased successfully!')));
      LockInModal.show(
        context: context,
        title: 'Increase Your Returns with Lock-In Investment',
        message: 'If you want, you can get additional returns by locking your silver for a specific period.',
        primaryActionText: 'Lock Now',
        secondaryActionText: 'Skip & Continue',
        metalType: 'silver',
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

  void _handleTransaction() async {
    final provider = Provider.of<GoldProvider>(context, listen: false);

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum amount is ₹100')));
      return;
    }
    
    if (_paymentMethod != 'UPI') {
      Map<String, dynamic> result = await provider.buySilver(amount, _paymentMethod, paymentId: 'WALLET_TXN');
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silver purchased successfully!')));
        LockInModal.show(
          context: context,
          title: 'Increase Your Returns with Lock-In Investment',
          message: 'If you want, you can get additional returns by locking your silver for a specific period.',
          primaryActionText: 'Lock Now',
          secondaryActionText: 'Skip & Continue',
          metalType: 'silver',
          onSecondaryAction: () => Navigator.of(context).pop(),
        );
        _amountController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Transaction failed.'), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() => _isProcessingPayment = true);
    final orderRes = await provider.createPaymentOrder(amount);
    
    if (orderRes['success'] == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final rate = provider.silverRate?['current_rate']?['rate_per_gram'] ?? 1.0;
      final grams = amount / rate;
      
      final orderData = orderRes['data'];
      var options = {
        'key': orderData['key'],
        'amount': orderData['amount'],
        'name': 'SilverVault',
        'description': 'Purchase of ${grams.toStringAsFixed(4)}g Silver',
        'order_id': orderData['order_id'],
        'prefill': {
          'contact': user?['mobile'] ?? '',
          'name': user?['name'] ?? '',
        },
        'theme': {'color': '#9CA3AF'}
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
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('SILVER VAULT'),
        centerTitle: true,
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          final silverRate = provider.silverRate?['rate_per_gram'] ?? 0.0;
          final silverBalance = provider.dashboardData?['total_silver_grams'] ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR SILVER BALANCE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 5),
                          Text('${silverBalance.toStringAsFixed(4)} gms', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('SPOT PRICE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 5),
                          Text(currencyFormat.format(silverRate), style: const TextStyle(color: Colors.grey, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (INR)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: 'UPI', child: Text('Direct (UPI / Bank)')),
                    DropdownMenuItem(value: 'inr_wallet', child: Text('INR Wallet Balance')),
                    DropdownMenuItem(value: 'japsan_wallet', child: Text('Japsan Wallet Balance')),
                    DropdownMenuItem(value: 'gold_wallet', child: Text('Gold Wallet (Sell Gold to Buy Silver)')),
                  ],
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: (provider.isLoading || _isProcessingPayment) ? null : _handleTransaction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: const Color(0xFFE0E0E0),
                    foregroundColor: Colors.black,
                  ),
                  child: (provider.isLoading || _isProcessingPayment)
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('PROCEED TO BUY'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
