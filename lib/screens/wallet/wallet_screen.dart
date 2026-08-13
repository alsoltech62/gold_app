import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/gold_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _sipAmountController = TextEditingController();
  String _walletType = 'inr';
  String _sipFreq = 'monthly';
  String _sipMetalType = 'gold';
  bool _sipActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GoldProvider>(context, listen: false);
      provider.fetchDashboard().then((_) {
        final data = provider.dashboardData;
        if (data != null && mounted) {
          setState(() {
            _sipActive = data['sip_active'] ?? false;
            _sipAmountController.text = (data['sip_amount'] ?? '').toString();
            _sipFreq = data['sip_frequency'] ?? 'monthly';
            _sipMetalType = data['sip_metal_type'] ?? 'gold';
          });
        }
      });
      provider.fetchSipHistory();
    });
  }

  void _handleDeposit() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    if (_walletType == 'japsan') {
      final Uri url = Uri.parse('https://japsanpay.com/');
      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch Japsan Pay')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch Japsan Pay')));
        }
      }
      _amountController.clear();
      return;
    }

    final provider = Provider.of<GoldProvider>(context, listen: false);
    final res = await provider.depositFunds(amount, _walletType);
    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deposit successful!')));
        _amountController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Deposit failed')),
        );
      }
    }
  }

  void _handleSipSave() async {
    final amount = double.tryParse(_sipAmountController.text) ?? 0;
    final provider = Provider.of<GoldProvider>(context, listen: false);
    final res = await provider.updateSipSettings(
      _sipActive,
      amount,
      _sipFreq,
      _sipMetalType,
    );
    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('SIP Settings Saved')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to save SIP')),
        );
      }
    }
  }

  void _handleWithdraw() {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Withdraw Funds',
            style: TextStyle(color: Colors.white),
          ),
          content: Consumer<AuthProvider>(
            builder: (ctx2, authProv, _) {
              final user = authProv.user;
              final hasBankDetails =
                  user != null &&
                  user['account_number'] != null &&
                  user['account_number'].toString().isNotEmpty;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Withdraw to Bank',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (hasBankDetails)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank: ${user['bank_name']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'A/C: ${user['account_number']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'IFSC: ${user['ifsc_code']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Name: ${user['account_holder_name']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'Please update your bank details in the Profile section.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                if (amt <= 0) return;

                final auth = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).user;
                if (auth == null ||
                    auth['account_number'] == null ||
                    auth['account_number'].toString().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please update your bank details in the Profile section before withdrawing.',
                      ),
                    ),
                  );
                  Navigator.pop(ctx);
                  return;
                }

                Navigator.pop(ctx);

                final provider = Provider.of<GoldProvider>(
                  context,
                  listen: false,
                );
                final res = await provider.withdrawFunds(amt);
                if (mounted) {
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Withdrawal request submitted successfully',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Withdrawal failed'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('WALLET & SIP'), centerTitle: true),
      body: Consumer<GoldProvider>(
        builder: (context, provider, _) {
          final data = provider.dashboardData ?? {};
          final inrBalance =
              double.tryParse(data['inr_wallet']?.toString() ?? '') ?? 0.0;
          final japsanBalance =
              double.tryParse(data['japsan_wallet']?.toString() ?? '') ?? 0.0;
          final sipHistory = provider.sipHistory;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balances
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'INR WALLET',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              currencyFormat.format(inrBalance),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'JAPSAN WALLET',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              currencyFormat.format(japsanBalance),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purpleAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Deposit Section
                const Text(
                  'Deposit Funds',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _walletType,
                  decoration: const InputDecoration(labelText: 'Wallet Type'),
                  items: const [
                    DropdownMenuItem(value: 'inr', child: Text('INR Wallet')),
                    DropdownMenuItem(
                      value: 'japsan',
                      child: Text('Japsan Wallet'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _walletType = val!),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _handleDeposit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'DEPOSIT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: provider.isLoading ? null : _handleWithdraw,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.white30),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'WITHDRAW',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Deposit: ',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Add funds to your wallet. When your INR balance reaches ₹1,000, it automatically converts into Digital Gold to secure your savings.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Withdraw: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Transfer your available INR balance directly to your registered bank account.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // SIP Settings
                const Text(
                  'Auto SIP Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                SwitchListTile(
                  title: const Text('Enable SIP'),
                  value: _sipActive,
                  onChanged: (val) => setState(() => _sipActive = val),
                  activeColor: Colors.blue,
                ),
                if (_sipActive) ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: _sipAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'SIP Amount',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _sipMetalType,
                    decoration: const InputDecoration(
                      labelText: 'SIP Metal Type',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'gold', child: Text('Gold')),
                      DropdownMenuItem(value: 'silver', child: Text('Silver')),
                    ],
                    onChanged: (val) => setState(() => _sipMetalType = val!),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _sipFreq,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Monthly'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _sipFreq = val!),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _handleSipSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text('SAVE SIP SETTINGS'),
                ),

                const SizedBox(height: 40),

                // SIP History
                if (sipHistory != null) ...[
                  const Text(
                    'SIP Investment Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL INVESTED',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                currencyFormat.format(
                                  double.tryParse(
                                        sipHistory['total_invested']
                                                ?.toString() ??
                                            '',
                                      ) ??
                                      0.0,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GOLD ACQUIRED',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${sipHistory['total_gold'] ?? 0}g',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB08D57),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Recent Deductions',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (sipHistory['history'] as List?)?.length ?? 0,
                    itemBuilder: (context, index) {
                      final txn = sipHistory['history'][index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          currencyFormat.format(
                            double.tryParse(
                                  txn['amount_inr']?.toString() ?? '',
                                ) ??
                                0.0,
                          ),
                        ),
                        subtitle: Text(
                          txn['created_at'].toString().split(' ')[0],
                        ),
                        trailing: Text(
                          '+${txn['gold_grams']}g',
                          style: const TextStyle(
                            color: Color(0xFFB08D57),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
