import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../providers/gold_provider.dart';
import '../../providers/auth_provider.dart';
import '../gold/lock_in_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SilverScreen extends StatefulWidget {
  final bool initialIsBuy;
  const SilverScreen({super.key, this.initialIsBuy = true});

  @override
  State<SilverScreen> createState() => _SilverScreenState();
}

class _SilverScreenState extends State<SilverScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _paymentMethod = 'RRFINCO';
  bool _isProcessingPayment = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoldProvider>(context, listen: false).fetchSilverRate();
    });
  }

  // Cashfree callbacks removed

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleTransaction() async {
    final goldProvider = Provider.of<GoldProvider>(context, listen: false);

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum amount is ₹100')));
      return;
    }

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
      Map<String, dynamic> result = await goldProvider.buySilver(amount, _paymentMethod, paymentId: 'WALLET_TXN');
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silver purchased successfully!')));
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockInScreen(metalType: 'silver')));
        _amountController.clear();
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
          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
                    child: Text('goldbindia@oksbi', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
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
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.black),
            onPressed: () async {
              if (utrController.text.length < 6) return;
              Navigator.pop(dialogContext);
              setState(() => _isProcessingPayment = true);
              
              final result = await goldProvider.buySilver(amount, 'UPI', paymentId: utrController.text);
              if (!mounted) return;
              setState(() => _isProcessingPayment = false);
              
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silver purchased successfully!')));
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockInScreen(metalType: 'silver')));
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
          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        title: const Text('Payment Verification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Did you complete the payment in the browser? Click below to verify and add silver to your vault.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isProcessingPayment = true);
              
              final result = await Provider.of<GoldProvider>(context, listen: false).buySilver(amount, 'RRFINCO', paymentId: orderId);
              if (!mounted) return;
              setState(() => _isProcessingPayment = false);
              
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silver purchased successfully!')));
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockInScreen(metalType: 'silver')));
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
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('SILVER VAULT'),
        centerTitle: true,
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          final rateRaw = provider.silverRate?['rate_per_gram'];
          final silverRate = rateRaw != null ? double.tryParse(rateRaw.toString()) ?? 0.0 : 0.0;
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
                    DropdownMenuItem(value: 'RRFINCO', child: Text('Direct / UPI / Cards')),
                    DropdownMenuItem(value: 'UPI', child: Text('Manual UPI Transfer')),
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
