import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../providers/gold_provider.dart';

class SipScreen extends StatefulWidget {
  final String metalType;
  const SipScreen({super.key, this.metalType = 'gold'});

  @override
  State<SipScreen> createState() => _SipScreenState();
}

class _SipScreenState extends State<SipScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _amount = '1000';
  String _frequency = 'monthly';
  bool _isLoading = false;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPlans();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoldProvider>(context, listen: false).fetchSipHistory(metalType: widget.metalType);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    try {
      final data = await ApiClient().get('/api/user/sip_plans.php');
      if (data['success'] == true) {
        setState(() {
          _plans = (data['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          if (_plans.isNotEmpty) {
            _selectedPlan = _plans.first;
            _amount = _selectedPlan!['min_amount'].toString();
            final rawFreq = _selectedPlan!['frequency']?.toString() ?? '';
            final planName = _selectedPlan!['plan_name']?.toString().toLowerCase() ?? '';
            _frequency = rawFreq.isNotEmpty
                ? rawFreq
                : (planName.contains('daily')
                    ? 'daily'
                    : planName.contains('weekly')
                        ? 'weekly'
                        : planName.contains('yearly')
                            ? 'yearly'
                            : 'monthly');
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching SIP plans: $e');
    }
  }

  Future<void> _setupSip() async {
    final minAmt = _selectedPlan != null
        ? (double.tryParse(_selectedPlan!['min_amount'].toString()) ?? 500)
        : 500.0;

    if (double.tryParse(_amount) == null || double.parse(_amount) < minAmt) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum SIP amount for this plan is ₹$minAmt'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<GoldProvider>(context, listen: false);
      final result = await provider.updateSipSettings(
        true,
        double.parse(_amount),
        _frequency,
        widget.metalType,
      );

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SIP Setup successfully'), backgroundColor: Colors.green),
        );
        await provider.fetchSipHistory(metalType: widget.metalType);
        await provider.fetchDashboard();
        _tabController.animateTo(0); // go back to My SIPs tab
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to setup SIP'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _freqIcon(String freq) {
    switch (freq.toLowerCase()) {
      case 'daily': return '📅';
      case 'weekly': return '📆';
      case 'yearly': return '🗓️';
      default: return '🔄';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070707),
        elevation: 0,
        title: Text(
          widget.metalType == 'all' 
            ? 'My SIP Plans' 
            : 'My ${widget.metalType == 'silver' ? 'Silver' : 'Gold'} SIPs',
          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: widget.metalType == 'all' ? null : TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'MY SIPS'),
            Tab(text: 'ADD / MODIFY SIP'),
          ],
        ),
      ),
      body: widget.metalType == 'all' 
        ? _buildMySipsTab()
        : TabBarView(
            controller: _tabController,
            children: [
              _buildMySipsTab(),
              _buildSetupTab(),
            ],
          ),
    );
  }

  // ── Tab 1: Active SIPs + Monitoring ──────────────────────────────────────
  Widget _buildMySipsTab() {
    return Consumer<GoldProvider>(
      builder: (context, provider, _) {
        final sipData = provider.sipHistory;

        if (sipData == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        final activeSips = (sipData['active_sips'] as List?) ?? [];
        final double totalInvested = double.tryParse(sipData['total_invested'].toString()) ?? 0.0;
        final double totalGold = double.tryParse(sipData['total_gold'].toString()) ?? 0.0;
        final List history = sipData['history'] ?? [];

        return RefreshIndicator(
          color: const Color(0xFFD4AF37),
          onRefresh: () => provider.fetchSipHistory(metalType: widget.metalType),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active SIPs section
                if (activeSips.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.autorenew, color: Colors.grey, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'No Active SIP',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Set up a SIP to automate your gold investment',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _tabController.animateTo(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Set Up SIP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'ACTIVE SIP PLANS',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  ...activeSips.map((sip) => _buildActiveSipCard(sip)).toList(),
                ],

                const SizedBox(height: 20),

                // Monitoring stats
                const Text(
                  'SIP INSTALLMENT MONITORING',
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Invested', '₹${_fmt(totalInvested)}', Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(
                      widget.metalType == 'all' ? 'Metal Accumulated' : '${widget.metalType == 'silver' ? 'Silver' : 'Gold'} Accumulated', 
                      '${totalGold.toStringAsFixed(4)}g', 
                      widget.metalType == 'silver' ? Colors.grey : const Color(0xFFD4AF37)
                    )),
                  ],
                ),

                const SizedBox(height: 20),

                // Transaction history
                const Text(
                  'INSTALLMENT HISTORY',
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 10),

                if (history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, color: Colors.grey, size: 36),
                          SizedBox(height: 8),
                          Text(
                            'No installments deducted yet',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Installments will appear here after the first auto-deduction',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...history.map((txn) => _buildHistoryCard(txn)).toList(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSipCard(Map sip) {
    final freq = sip['frequency']?.toString() ?? 'monthly';
    final amount = double.tryParse(sip['amount'].toString()) ?? 0.0;
    final metal = sip['metal_type']?.toString() ?? 'gold';
    final createdAt = sip['created_at']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_freqIcon(freq), style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        freq.toUpperCase(),
                        style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: metal == 'silver' ? Colors.grey.withOpacity(0.1) : const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metal.toUpperCase(),
                        style: TextStyle(color: metal == 'silver' ? Colors.grey : const Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '₹ ${_fmt(amount)}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (createdAt != null)
                  Text(
                    'Started: $createdAt',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sip['status']?.toString().toUpperCase() ?? 'ACTIVE',
                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (sip['id'] != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Text('Cancel SIP', style: TextStyle(color: Colors.white)),
                        content: const Text('Are you sure you want to cancel this SIP?', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('NO', style: TextStyle(color: Colors.grey))),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('YES', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final provider = Provider.of<GoldProvider>(context, listen: false);
                      final res = await provider.cancelSip(int.parse(sip['id'].toString()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res['message'] ?? (res['success'] == true ? 'Cancelled successfully' : 'Failed to cancel')),
                          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                        ));
                      }
                      if (res['success'] == true) {
                        provider.fetchSipHistory(metalType: widget.metalType);
                        provider.fetchDashboard();
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Text('CANCEL', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          )
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹${txn['amount_inr']}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(txn['created_at']?.toString() ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${txn['gold_grams']}g',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text(txn['status']?.toString().toUpperCase() ?? '',
                  style: const TextStyle(color: Colors.green, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Setup / Modify SIP ─────────────────────────────────────────────
  Widget _buildSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SIP Installment Amount',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: TextEditingController(text: _amount)
                    ..selection = TextSelection.collapsed(offset: _amount.length),
                  onChanged: (val) => _amount = val,
                ),
                const SizedBox(height: 20),
                const Text('Select SIP Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                if (_plans.isEmpty)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                else
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _plans.length,
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        final isSelected = _selectedPlan != null && _selectedPlan!['id'] == plan['id'];
                        final rawFreq = plan['frequency']?.toString() ?? '';
                        final planName = plan['plan_name']?.toString().toLowerCase() ?? '';
                        final displayFreq = rawFreq.isNotEmpty
                            ? rawFreq
                            : (planName.contains('daily')
                                ? 'daily'
                                : planName.contains('weekly')
                                    ? 'weekly'
                                    : planName.contains('yearly')
                                        ? 'yearly'
                                        : 'monthly');
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedPlan = plan;
                            _amount = plan['min_amount'].toString();
                            _frequency = displayFreq;
                          }),
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isSelected ? Colors.green : Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(plan['plan_name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('Min: ₹${plan['min_amount']}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                Text(displayFreq.toUpperCase(),
                                    style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                const Text('Selected Frequency',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    _frequency.isEmpty ? 'MONTHLY' : _frequency.toUpperCase(),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _setupSip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Setup / Update SIP',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
