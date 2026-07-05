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
      goldProvider.fetchSilverRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          ),
          child: Image.asset(
            'assets/images/logo1.png',
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFFFD700),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<GoldProvider>(
        builder: (context, gold, child) {
          if (gold.isLoading && gold.dashboardData == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            );
          }

          final data = gold.dashboardData ?? {};
          final totalGold =
              double.tryParse(data['total_gold_grams']?.toString() ?? '0') ??
              0.0;
          final totalSilver =
              double.tryParse(data['total_silver_grams']?.toString() ?? '0') ??
              0.0;

          final goldRate =
              double.tryParse(
                gold.currentRate?['rate_per_gram']?.toString() ?? '0',
              ) ??
              0.0;
          final silverRate =
              double.tryParse(
                gold.silverRate?['rate_per_gram']?.toString() ?? '0',
              ) ??
              0.0;

          var currentGoldValue =
              double.tryParse(data['current_value_inr']?.toString() ?? '0') ??
              0.0;
          if (currentGoldValue <= 0.0) currentGoldValue = totalGold * goldRate;

          var currentSilverValue =
              double.tryParse(
                data['current_silver_value_inr']?.toString() ?? '0',
              ) ??
              0.0;
          if (currentSilverValue <= 0.0)
            currentSilverValue = totalSilver * silverRate;

          return RefreshIndicator(
            onRefresh: () async {
              await gold.fetchDashboard();
              await gold.fetchCurrentRate();
              await gold.fetchSilverRate();
            },
            color: const Color(0xFFFFD700),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildBanner(data),
                  const SizedBox(height: 16),
                  _buildStatsGrid(
                    currentGoldValue.toStringAsFixed(2),
                    currentSilverValue.toStringAsFixed(2),
                    totalGold.toStringAsFixed(4),
                    totalSilver.toStringAsFixed(4),
                  ),
                  const SizedBox(height: 16),
                  _buildActionSection(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    const baseUrl = 'https://goldpay.odofast.in/backend';
    return '$baseUrl/$path';
  }

  Widget _buildBanner(Map<String, dynamic> data) {
    final banners = data['banners'] as List<dynamic>? ?? [];
    if (banners.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: PageView.builder(
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            final imageUrl = _getImageUrl(banner['image_url']);
            return Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (ctx, err, stack) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white54),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsGrid(
    String goldVal,
    String silverVal,
    String totalGold,
    String totalSilver,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildStatCard(
            'CURRENT VALUE\n(GOLD)',
            goldVal,
            Icons.trending_up,
            'Rs',
          ),
          _buildStatCard(
            'CURRENT VALUE\n(SILVER)',
            silverVal,
            Icons.trending_up,
            'Rs',
          ),
          _buildStatCard(
            'TOTAL GOLD\nINVESTED',
            totalGold,
            Icons.monetization_on,
            'gms',
          ),
          _buildStatCard(
            'TOTAL SILVER\nINVESTED',
            totalSilver,
            Icons.view_agenda,
            'gms',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD700), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                // Gold Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700)),
                      ),
                      child: const Icon(
                        Icons.widgets,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOLD',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            '(24K)',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      'BUY',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BuyFlowScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildIconActionButton(
                      Icons.sync,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LockInScreen(metalType: 'gold'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      'SELL',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SellFlowScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Silver Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(
                        Icons.widgets,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SILVER',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            '(999)',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      'BUY',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SilverScreen()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildIconActionButton(
                      Icons.sync,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LockInScreen(metalType: 'silver'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      'SELL',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SellFlowScreen(metalType: 'silver'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 100,
            color: const Color(0xFFFFD700).withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionListScreen(),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'HISTORY',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Icon(
                      Icons.calendar_month,
                      color: Color(0xFFFFD700),
                      size: 28,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showMetalSelectionDialog(context),
                child: const Column(
                  children: [
                    Text(
                      'DELIVERY',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Icon(
                      Icons.local_shipping,
                      color: Color(0xFFFFD700),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFD700)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildIconActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFD700)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: const Color(0xFFFFD700), size: 14),
      ),
    );
  }

  void _showMetalSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Metal for Delivery',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const DeliveryScreen(metalType: 'gold'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.1),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Text('🥇', style: TextStyle(fontSize: 32)),
                            SizedBox(height: 8),
                            Text(
                              'Gold',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Asset',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const DeliveryScreen(metalType: 'silver'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Text('🥈', style: TextStyle(fontSize: 32)),
                            SizedBox(height: 8),
                            Text(
                              'Silver',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Asset',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
