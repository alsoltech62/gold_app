import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/gold_provider.dart';
import '../gold/buy_flow_screen.dart';
import '../gold/sell_flow_screen.dart';
import '../silver/silver_screen.dart';
import '../silver/buy_silver_flow_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  
  final List<Map<String, String>> _banners = [
    {
      'image': 'assets/images/jewelry_banner.png',
      'title': 'Invest in Precious\nMetals, Secure\nYour Future',
      'subtitle': 'Start Your Investment Today'
    },
    {
      'image': 'assets/images/gold_bars_hero.png',
      'title': '24K Pure Gold\nDelivered to\nYour Doorstep',
      'subtitle': '100% Insured Delivery'
    },
    {
      'image': 'assets/images/gold_bangle_feature.png',
      'title': 'Lock-In your\nAssets for Extra\nReturns',
      'subtitle': 'Up to 12% Extra Profit'
    },
    {
      'image': 'assets/images/gold_coins_footer.png',
      'title': 'Build Wealth\nWith Digital\nSilver & Gold',
      'subtitle': 'Secure & Transparent'
    }
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goldProvider = Provider.of<GoldProvider>(context, listen: false);
      goldProvider.fetchDashboard();
      goldProvider.fetchCurrentRate();
      goldProvider.fetchSilverRate();
    });
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextIndex = (_currentBannerIndex + 1) % _banners.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String formatINR(dynamic value) {
    if (value == null) return '0';
    double numVal = double.tryParse(value.toString()) ?? 0.0;
    return NumberFormat('#,##,###.##').format(numVal);
  }

  String formatGrams(dynamic value) {
    if (value == null) return '0.000';
    double numVal = double.tryParse(value.toString()) ?? 0.0;
    return numVal.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        centerTitle: true,
        title: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            color: Colors.black,
          ),
          child: Image.asset('assets/icon/newlogo.png', fit: BoxFit.contain),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFFD4AF37),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<GoldProvider>(
        builder: (context, gold, child) {
          if (gold.isLoading && gold.dashboardData == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          final data = gold.dashboardData ?? {};
          final totalGold = data['total_gold_grams'] ?? 0;
          final totalSilver = data['total_silver_grams'] ?? 0;
          final goldRate = gold.currentRate?['rate_per_gram'] ?? 0;
          final silverRate = gold.silverRate?['rate_per_gram'] ?? 0;
          final currentGoldValue = data['gold_current_value'] ?? 0;
          final currentSilverValue = data['silver_current_value'] ?? 0;
          final totalValue = data['current_value_inr'] ?? 0;
          final lockedGold = data['locked_gold'] ?? 0;
          final lockedSilver = data['locked_silver'] ?? 0;
          final sipActive = data['sip_active'] ?? false;
          final sipAmount = data['sip_amount'] ?? 0;

          final pl =
              double.tryParse(data['profit_loss_inr']?.toString() ?? '0') ?? 0;
          final totalInv =
              double.tryParse(data['total_invested_inr']?.toString() ?? '0') ??
              0;
          final plPercentage = totalInv > 0
              ? ((pl / totalInv) * 100).toStringAsFixed(2)
              : '0.00';

          return RefreshIndicator(
            color: const Color(0xFFD4AF37),
            onRefresh: () async {
              await gold.fetchDashboard();
              await gold.fetchCurrentRate();
              await gold.fetchSilverRate();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Rates Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text("🥇", style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "GOLD",
                                  style: TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "₹ ${formatINR(goldRate)} ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "/gm",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                        ),
                        Row(
                          children: [
                            const Text("🥈", style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "SILVER",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "₹ ${formatINR(silverRate)} ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "/gm",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            gold.fetchDashboard();
                            gold.fetchCurrentRate();
                            gold.fetchSilverRate();
                          },
                          child: const Icon(
                            Icons.sync,
                            color: Color(0xFFD4AF37),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Promo Banner
                  SizedBox(
                    height: 140,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                            ),
                            image: DecorationImage(
                              image: AssetImage(banner['image']!),
                              fit: BoxFit.cover,
                              opacity: 0.7,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withOpacity(0.9),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      banner['title']!,
                                      style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 16,
                                        fontFamily: 'serif',
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      banner['subtitle']!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(_banners.length, (dotIndex) {
                                      final isActive = _currentBannerIndex == dotIndex;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        width: isActive ? 16 : 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFFD4AF37) : Colors.white30,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "🥇",
                          "TOTAL GOLD\nINVESTED",
                          "${formatGrams(totalGold)} gm",
                          const Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          "🥈",
                          "TOTAL SILVER\nINVESTED",
                          "${formatGrams(totalSilver)} gm",
                          Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTrendCard(
                          Icons.trending_up,
                          const Color(0xFFD4AF37),
                          "CURRENT GOLD\nVALUE",
                          "₹ ${formatINR(currentGoldValue)}",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTrendCard(
                          Icons.trending_up,
                          Colors.grey,
                          "CURRENT SILVER\nVALUE",
                          "₹ ${formatINR(currentSilverValue)}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTrendCard(
                          Icons.lock_outline,
                          const Color(0xFFD4AF37),
                          "LOCKED GOLD",
                          "${formatGrams(lockedGold)} gm",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTrendCard(
                          Icons.lock_outline,
                          Colors.grey,
                          "LOCKED SILVER",
                          "${formatGrams(lockedSilver)} gm",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (sipActive) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.autorenew, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ACTIVE SIP",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Total: ₹ ${formatINR(sipAmount)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (data['sip_breakdown'] is Map)
                                  ...((data['sip_breakdown'] as Map).entries.map((e) => Text(
                                    "₹ ${formatINR(e.value)} ${e.key.toString().toUpperCase()}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Total Portfolio Value
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFFD4AF37),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "TOTAL PORTFOLIO VALUE",
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 42.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹ ${formatINR(totalValue)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${pl >= 0 ? '↑' : '↓'} Today ${pl >= 0 ? 'Profit' : 'Loss'} ₹ ${formatINR(pl.abs())} ($plPercentage%)",
                                style: TextStyle(
                                  color: pl >= 0 ? Colors.green : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionRow(
                          "🥇",
                          "GOLD",
                          "24K Gold",
                          const Color(0xFFD4AF37),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BuyFlowScreen(),
                            ),
                          ),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SellFlowScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionRow(
                          "🥈",
                          "SILVER",
                          "999 Silver",
                          Colors.grey,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BuySilverFlowScreen(),
                            ),
                          ),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SellFlowScreen(initialMetalType: 'silver'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "RECENT TRANSACTIONS",
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionListScreen(),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              "VIEW ALL ",
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Color(0xFFD4AF37),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          (data['recent_transactions'] as List?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final tx = data['recent_transactions'][index];
                        return _buildTransactionCard(tx);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String emoji, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    IconData icon,
    Color color,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    String emoji,
    String title,
    String subtitle,
    Color color,
    VoidCallback onBuy,
    VoidCallback onSell,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(color: color, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "BUY",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onSell,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      border: Border.all(color: color.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "SELL",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    bool isBuy = tx['type'] == 'buy';
    bool isSell = tx['type'] == 'sell';
    String metal = tx['metal_type']?.toString().toUpperCase() ?? 'GOLD';
    String metalName = metal == 'GOLD' ? 'Gold' : 'Silver';
    String amount = formatINR(tx['amount_inr']);
    String dateStr = tx['created_at'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(tx['created_at']))
        : '';

    IconData iconData = isBuy
        ? Icons.shopping_cart
        : isSell
        ? Icons.arrow_downward
        : Icons.local_shipping;
    String actionName = isBuy
        ? 'Buy'
        : isSell
        ? 'Sell'
        : 'Delivery';
    String grams = tx['gold_grams'] != null
        ? formatGrams(tx['gold_grams'])
        : (tx['silver_grams'] != null ? formatGrams(tx['silver_grams']) : '0');

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                  ),
                ),
                child: Icon(iconData, color: const Color(0xFFD4AF37), size: 14),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$metalName $actionName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$grams gm",
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "₹ $amount",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Text(
              "Completed",
              style: TextStyle(color: Colors.green, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }
}
