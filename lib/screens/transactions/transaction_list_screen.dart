import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gold_provider.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoldProvider>(context, listen: false).fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TRANSACTIONS')),
      body: Consumer<GoldProvider>(
        builder: (context, gold, child) {
          if (gold.isLoading && gold.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }

          if (gold.transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: gold.transactions.length,
            itemBuilder: (context, index) {
              final txn = gold.transactions[index];
              final type = txn['type']?.toString().toLowerCase() ?? '';
              final metalType = txn['metal_type']?.toString().toUpperCase() ?? 'GOLD';
              final status = txn['status']?.toString().toLowerCase() ?? 'pending';

              String title = 'Transaction';
              IconData icon = Icons.receipt_long;
              Color iconColor = Colors.grey;
              String gramsText = '';
              Color gramsColor = Colors.white;

              if (type == 'buy') {
                title = 'Bought $metalType';
                icon = Icons.add;
                iconColor = Colors.green;
                gramsText = '+${txn['gold_grams'] ?? '0'} gms';
                gramsColor = Colors.green;
              } else if (type == 'sell') {
                title = 'Sold $metalType';
                icon = Icons.remove;
                iconColor = Colors.red;
                gramsText = '-${txn['gold_grams'] ?? '0'} gms';
                gramsColor = Colors.red;
              } else if (type == 'deposit') {
                title = 'Wallet Deposit';
                icon = Icons.account_balance_wallet;
                iconColor = Colors.blue;
                gramsText = '---';
                gramsColor = Colors.grey;
              } else if (type == 'delivery') {
                title = 'Physical Claim';
                icon = Icons.local_shipping;
                iconColor = Colors.orange;
                gramsText = '-${txn['gold_grams'] ?? '0'} gms';
                gramsColor = Colors.orange;
              }

              String dateStr = '';
              if (txn['created_at'] != null) {
                try {
                  final parsedDate = DateTime.parse(txn['created_at'].toString());
                  dateStr = "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
                } catch (_) {
                  dateStr = txn['created_at'].toString().split(' ')[0];
                }
              }

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              dateStr,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'ID: ${txn['id']}',
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            gramsText,
                            style: TextStyle(
                              color: gramsColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹${txn['amount_inr']}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
