import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/gold_provider.dart';

class SilverScreen extends StatefulWidget {
  const SilverScreen({super.key});

  @override
  State<SilverScreen> createState() => _SilverScreenState();
}

class _SilverScreenState extends State<SilverScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _gramsController = TextEditingController();
  String _paymentMethod = 'UPI';
  bool _isBuy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoldProvider>(context, listen: false).fetchSilverRate();
    });
  }

  void _handleTransaction() async {
    final provider = Provider.of<GoldProvider>(context, listen: false);
    Map<String, dynamic> result = {};

    if (_isBuy) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount < 100) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum amount is ₹100')));
        return;
      }
      result = await provider.buySilver(amount, _paymentMethod);
    } else {
      final grams = double.tryParse(_gramsController.text) ?? 0;
      if (grams <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
        return;
      }
      result = await provider.sellSilver(grams);
    }

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isBuy ? 'Silver purchased successfully!' : 'Silver sold successfully!')));
      _amountController.clear();
      _gramsController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Transaction failed'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isBuy ? const Color(0xFFE0E0E0) : const Color(0xFF1E1E1E),
                          foregroundColor: _isBuy ? Colors.black : Colors.white,
                        ),
                        onPressed: () => setState(() => _isBuy = true),
                        child: const Text('BUY SILVER'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isBuy ? const Color(0xFFE0E0E0) : const Color(0xFF1E1E1E),
                          foregroundColor: !_isBuy ? Colors.black : Colors.white,
                        ),
                        onPressed: () => setState(() => _isBuy = false),
                        child: const Text('SELL SILVER'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                if (_isBuy) ...[
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
                ] else ...[
                  TextField(
                    controller: _gramsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (Grams)',
                      suffixText: ' gms',
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _handleTransaction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: const Color(0xFFE0E0E0),
                    foregroundColor: Colors.black,
                  ),
                  child: provider.isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(_isBuy ? 'PROCEED TO BUY' : 'PROCEED TO SELL'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
