import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gold_provider.dart';
import '../gold/buy_flow_screen.dart';
import '../gold/sell_flow_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../delivery/delivery_screen.dart';
import '../notifications_screen.dart';
import '../silver/silver_screen.dart';
import '../silver/silver_screen.dart';
import '../gold/lock_in_screen.dart';

enum ActionType { buy, sell, lockIn, delivery }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goldProvider = Provider.of<GoldProvider>(context, listen: false);
      goldProvider.fetchDashboard();
      goldProvider.fetchCurrentRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('GOLD SAVINGS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            color: const Color(0xFFFFD700),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen())
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<GoldProvider>(
        builder: (context, gold, child) {
          if (gold.isLoading && gold.dashboardData == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }

          final data = gold.dashboardData ?? {};
          final rate = gold.currentRate ?? {};

          return RefreshIndicator(
            onRefresh: () async {
              await gold.fetchDashboard();
              await gold.fetchCurrentRate();
            },
            color: const Color(0xFFFFD700),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoldRateCard(rate),
                  const SizedBox(height: 25),
                  _buildBalanceSection(data, currencyFormat),
                  const SizedBox(height: 30),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildQuickActions(context),
                  const SizedBox(height: 30),
                  _buildRecentActivityHeader(context),
                  const SizedBox(height: 15),
                  _buildRecentActivityList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoldRateCard(Map<String, dynamic> rate) {
    final rateValue = rate['rate_per_gram'] ?? 0.0;
    final change = rate['change'] ?? 0.0;
    final isUp = change >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TODAY\'S RATE (24K)', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 5),
              Text(
                '₹${rateValue.toStringAsFixed(2)}/gm',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isUp ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  '${isUp ? '+' : ''}${change.toStringAsFixed(2)}',
                  style: TextStyle(color: isUp ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildBalanceSection(Map<String, dynamic> data, NumberFormat format) {
    final totalGold = data['total_gold_grams'] ?? 0.0;
    final currentValue = data['current_value_inr'] ?? 0.0;
    final totalInvested = data['total_invested_inr'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'TOTAL GOLD',
                '${totalGold.toStringAsFixed(4)} gms',
                Icons.stars,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'CURRENT VALUE',
                format.format(currentValue),
                Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildStatCard(
          'TOTAL INVESTED',
          format.format(totalInvested),
          Icons.payments,
          fullWidth: true,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatCard(String title, String value, IconData icon, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildActionItem(context, 'BUY', Icons.add_shopping_cart, action: ActionType.buy),
          const SizedBox(width: 25),
          _buildActionItem(context, 'SELL', Icons.sell, action: ActionType.sell),
          const SizedBox(width: 25),
          _buildActionItem(context, 'LOCK IN', Icons.lock_clock, action: ActionType.lockIn),
          const SizedBox(width: 25),
          _buildActionItem(context, 'DELIVERY', Icons.local_shipping, action: ActionType.delivery),
          const SizedBox(width: 25),
          _buildActionItem(context, 'HISTORY', Icons.history, target: const TransactionListScreen()),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, {Widget? target, ActionType? action}) {
    return GestureDetector(
      onTap: () {
        if (target != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
        } else if (action != null) {
          _showMetalSelectionDialog(context, action: action);
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showMetalSelectionDialog(BuildContext context, {required ActionType action}) {
    String title = '';
    switch (action) {
      case ActionType.buy: title = 'Select Metal to Buy'; break;
      case ActionType.sell: title = 'Select Metal to Sell'; break;
      case ActionType.lockIn: title = 'Select Metal to Lock'; break;
      case ActionType.delivery: title = 'Select Metal for Delivery'; break;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Widget target;
                        switch (action) {
                          case ActionType.buy: target = const BuyFlowScreen(); break;
                          case ActionType.sell: target = const SellFlowScreen(); break;
                          case ActionType.lockIn: target = const LockInScreen(metalType: 'gold'); break;
                          case ActionType.delivery: target = const DeliveryScreen(metalType: 'gold'); break;
                        }
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text('🥇', style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            const Text('Gold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(action == ActionType.buy ? '24K / 999' : 'Asset', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Widget target;
                        switch (action) {
                          case ActionType.buy: target = const SilverScreen(); break;
                          case ActionType.sell: target = const SellFlowScreen(metalType: 'silver'); break; 
                          case ActionType.lockIn: target = const LockInScreen(metalType: 'silver'); break;
                          case ActionType.delivery: target = const DeliveryScreen(metalType: 'silver'); break;
                        }
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text('🥈', style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            const Text('Silver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const Text('Asset', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
                ),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionListScreen()));
          },
          child: const Text('See All', style: TextStyle(color: Color(0xFFFFD700))),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildRecentActivityList() {
    return Consumer<GoldProvider>(
      builder: (context, gold, child) {
        final txns = gold.transactions.take(5).toList();
        if (txns.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No recent transactions', style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txns.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final txn = txns[index];
            return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: txn['type'] == 'buy' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      txn['type'] == 'buy' ? Icons.call_made : Icons.call_received,
                      color: txn['type'] == 'buy' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn['type'] == 'buy' ? 'Purchased Gold' : 'Sold Gold',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          txn['date'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${txn['type'] == 'buy' ? '+' : '-'}${txn['gold_grams']} gms',
                        style: TextStyle(
                          color: txn['type'] == 'buy' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${txn['amount_inr']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).animate().fadeIn(delay: 800.ms);
  }
}
