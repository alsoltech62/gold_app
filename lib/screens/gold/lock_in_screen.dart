import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/gold_provider.dart';
import 'package:intl/intl.dart';

class LockInScreen extends StatefulWidget {
  final String metalType;
  const LockInScreen({super.key, this.metalType = 'gold'});

  @override
  State<LockInScreen> createState() => _LockInScreenState();
}

class _LockInScreenState extends State<LockInScreen> with SingleTickerProviderStateMixin {
  late String _currentMetalType;
  String _amount = '';
  Map<String, dynamic>? _selectedPlan;
  bool _isLoading = false;

  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _history = [];
  
  final _amountController = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentMetalType = widget.metalType;
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gold = Provider.of<GoldProvider>(context, listen: false);
      gold.fetchDashboard();
      gold.fetchCurrentRate();
      gold.fetchSilverRate();
      _fetchPlans();
      _fetchHistory();
    });
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onMetalTypeChanged(String newType) {
    if (_currentMetalType != newType) {
      setState(() {
        _currentMetalType = newType;
        _selectedPlan = null;
        _amount = '';
        _amountController.text = '';
      });
      _fetchPlans();
    }
  }

  Future<void> _fetchPlans() async {
    try {
      final response = await http.get(Uri.parse('${ApiClient.baseUrl}/lockin/plans.php?metal_type=$_currentMetalType'));
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching plans: $e');
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/lockin/history.php'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  Future<void> _lockMetal() async {
    final gold = Provider.of<GoldProvider>(context, listen: false);

    if (_amount.isEmpty || double.tryParse(_amount) == null || double.parse(_amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount to lock'), backgroundColor: Colors.red),
      );
      return;
    }

    final totalGrams = _currentMetalType == 'silver' 
        ? (double.tryParse(gold.dashboardData?['total_silver_grams']?.toString() ?? '0') ?? 0.0) 
        : (double.tryParse(gold.dashboardData?['total_gold_grams']?.toString() ?? '0') ?? 0.0);
        
    if (double.parse(_amount) > totalGrams) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lock-in plan'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await gold.createLockIn(_selectedPlan!['months'], double.parse(_amount), _currentMetalType);

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_currentMetalType == 'silver' ? 'Silver' : 'Gold'} Locked Successfully!'), backgroundColor: Colors.green),
        );
        _fetchHistory();
        setState(() {
          _amount = '';
          _amountController.text = '';
          _selectedPlan = null;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to lock $_currentMetalType'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  String _formatINR(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }
  
  String _formatGrams(double grams) {
    return grams.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final isGold = _currentMetalType == 'gold';
    final themeColor = isGold ? const Color(0xFFD4AF37) : const Color(0xFF9CA3AF);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure dark matching React web #0A0A0A base
      appBar: AppBar(
        title: const Text('Lock & Earn', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<GoldProvider>(
        builder: (context, gold, child) {
          final totalGrams = isGold 
              ? (double.tryParse(gold.dashboardData?['total_gold_grams']?.toString() ?? '0') ?? 0.0) 
              : (double.tryParse(gold.dashboardData?['total_silver_grams']?.toString() ?? '0') ?? 0.0);
              
          final rateData = isGold ? gold.currentRate : gold.silverRate;
          double currentRate = 0.0;
          if (rateData != null) {
            currentRate = double.tryParse((isGold ? rateData['rate_per_gram'] : rateData['current_rate'])?.toString() ?? '0') ?? 0.0;
          }
          
          final filteredHistory = _history.where((h) => h['metal_type'] == _currentMetalType).toList();
          
          double parsedAmount = double.tryParse(_amount) ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header text
                const Text('Get up to 12% extra returns by locking your assets', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 25),
                
                // Toggle Buttons
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton('Lock Gold', 'gold', isGold),
                      _buildToggleButton('Lock Silver', 'silver', !isGold),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Available Balance Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor.withOpacity(0.15), Colors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: themeColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.trending_up, color: themeColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AVAILABLE ${isGold ? 'GOLD' : 'SILVER'} BALANCE', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(_formatGrams(totalGrams), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          if (currentRate > 0)
                            Text('≈ ${_formatINR(totalGrams * currentRate)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
                
                const SizedBox(height: 35),
                const Text('Select Lock-in Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 15),
                
                // Plans Grid (Dynamic list identical to React)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95, // Made taller to match react design proportions
                  ),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final isSelected = _selectedPlan != null && _selectedPlan!['id'] == plan['id'];
                    final colorHex = plan['color_hex'] as String? ?? '#3B82F6';
                    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlan = plan),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.1) : const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.05)),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${plan['months']} Months', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('+${plan['returnRate']}%', style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w900)),
                                  const Text('EXTRA RETURN', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  if (plan['plan_name'] != null && plan['plan_name'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(plan['plan_name'], style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ]
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Icon(Icons.check_circle, color: color, size: 22),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 25),
                
                // Info Cards
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.security, color: themeColor, size: 16),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Your ${isGold ? 'gold' : 'silver'} remains completely safe in our insured vaults during the lock-in period.', style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: themeColor, size: 16),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Early withdrawal is possible but subject to penalty charges depending on the duration served.', style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5))),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 30),
                
                // Investment Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Investment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 24),
                      Text('${isGold ? 'GOLD' : 'SILVER'} TO LOCK (GRAMS)', style: const TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                          hintText: '0.0000',
                          hintStyle: const TextStyle(color: Colors.white24),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _amount = val;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _amount = totalGrams.toString();
                              _amountController.text = _amount;
                            });
                          },
                          child: Text('MAX: ${_formatGrams(totalGrams)}', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                      
                      if (_selectedPlan != null && parsedAmount > 0 && currentRate > 0) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Current Value:', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                  Text(_formatINR(parsedAmount * currentRate), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Guaranteed Return:', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                  Text('+${_selectedPlan!['returnRate']}%', style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Colors.white10, height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Estimated Extra Profit:', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text(_formatINR((parsedAmount * currentRate) * (double.parse(_selectedPlan!['returnRate'].toString()) / 100)), 
                                    style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _selectedPlan == null || parsedAmount <= 0) ? null : _lockMetal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGold ? const Color(0xFFD4AF37) : const Color(0xFFE5E7EB),
                            disabledBackgroundColor: (isGold ? const Color(0xFFD4AF37) : const Color(0xFFE5E7EB)).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.lock, color: Colors.black, size: 20),
                                    SizedBox(width: 10),
                                    Text('Confirm Lock-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                // Lock-In History
                if (filteredHistory.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Lock-In Portfolio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: themeColor.withOpacity(0.2)),
                        ),
                        child: Text('${filteredHistory.length} ACTIVE PLANS', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final h = filteredHistory[index];
                      final progress = (h['progress_percentage'] as num).toDouble();
                      final estExtra = (h['estimated_extra'] as num?)?.toDouble() ?? (h['estimated_extra_gold'] as num?)?.toDouble() ?? 0.0;
                      
                      String startDateStr = h['start_date'].toString().split(' ')[0];
                      String endDateStr = h['end_date'].toString().split(' ')[0];
                      try {
                         DateTime sd = DateTime.parse(startDateStr);
                         DateTime ed = DateTime.parse(endDateStr);
                         startDateStr = DateFormat('dd MMM yy').format(sd);
                         endDateStr = DateFormat('dd MMM yyyy').format(ed);
                      } catch(_) {}

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Background progress glow effect matching React!
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Container(
                                    width: constraints.maxWidth * (progress / 100),
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: constraints.maxWidth * (progress / 100),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [themeColor.withOpacity(0.05), Colors.transparent],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_formatGrams((h['grams'] as num?)?.toDouble() ?? (h['gold_grams'] as num?)?.toDouble() ?? 0.0), 
                                            style: TextStyle(color: themeColor, fontSize: 24, fontWeight: FontWeight.w900)),
                                          const SizedBox(height: 4),
                                          Text('${_currentMetalType.toUpperCase()} LOCKED', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), border: Border.all(color: Colors.greenAccent.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.trending_up, color: Colors.greenAccent, size: 14),
                                                const SizedBox(width: 6),
                                                Text('+${h['return_percentage']}%', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w900)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text((h['plan_name'] ?? '${h['months']} Months').toString().toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  
                                  // Progress Bar mimicking Web
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('MATURITY PROGRESS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                                      Text('${progress.toInt()}%', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111111),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: constraints.maxWidth * (progress / 100),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isGold ? const [Color(0xFFBF953F), Color(0xFFAA771C)] : const [Color(0xFF6B7280), Color(0xFFD1D5DB)],
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [BoxShadow(color: themeColor.withOpacity(0.5), blurRadius: 10)],
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  width: 16,
                                                  child: FadeTransition(
                                                    opacity: _pulseController,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(startDateStr, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                      Text('${h['days_remaining']} DAYS LEFT', style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Maturity Box
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('EST. EXTRA ${_currentMetalType.toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                            const SizedBox(height: 4),
                                            Text('+${_formatGrams(estExtra)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('MATURITY DATE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                            const SizedBox(height: 4),
                                            Text(endDateStr, style: TextStyle(color: themeColor, fontSize: 16, fontWeight: FontWeight.w900)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
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

  Widget _buildToggleButton(String text, String value, bool isSelected) {
    return GestureDetector(
      onTap: () => _onMetalTypeChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (value == 'gold' ? const Color(0xFFD4AF37) : const Color(0xFFD1D5DB)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && value == 'gold' 
              ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 15)] 
              : isSelected && value == 'silver'
                  ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]
                  : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white54,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
