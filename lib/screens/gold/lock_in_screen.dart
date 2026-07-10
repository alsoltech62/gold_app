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
      final data = await ApiClient().get('/api/lockin/plans.php?metal_type=$_currentMetalType');
      if (data['success'] == true) {
        setState(() {
          _plans = (data['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching plans: $e');
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await ApiClient().get('/api/lockin/history.php');
      if (data['success'] == true) {
        setState(() {
          _history = (data['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
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
  }  @override
  Widget build(BuildContext context) {
    final isGold = _currentMetalType == 'gold';
    final themeColor = isGold ? const Color(0xFFFFD700) : const Color(0xFFE5E7EB);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: themeColor),
            onPressed: () {},
          ),
        ],
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
          
          // Auto-set amount to total balance for locking
          if (_amount.isEmpty && totalGrams > 0) {
            _amount = totalGrams.toString();
            _amountController.text = _amount;
          }
          
          double parsedAmount = double.tryParse(_amount) ?? 0.0;
          double currentValue = parsedAmount * currentRate;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.dashboard, color: themeColor, size: 40), // Placeholder for gold bars icon
                  ),
                ).animate().scale(delay: 100.ms),
                
                const SizedBox(height: 20),
                
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.horizontal_rule, color: themeColor.withOpacity(0.5), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'LOCK-IN PERIOD',
                      style: TextStyle(color: themeColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.horizontal_rule, color: themeColor.withOpacity(0.5), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lock your investment and earn extra returns',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                
                const SizedBox(height: 30),
                
                // Investment Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Investment', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${_formatGrams(parsedAmount)} gm', style: TextStyle(color: themeColor, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(isGold ? 'Gold' : 'Silver', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Value', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_formatINR(currentValue), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Purity', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(isGold ? '24K' : '999', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 30),
                
                // Choose Lock-in Period divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.diamond, color: themeColor.withOpacity(0.5), size: 10),
                    const SizedBox(width: 10),
                    const Text('CHOOSE LOCK-IN PERIOD', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Icon(Icons.diamond, color: themeColor.withOpacity(0.5), size: 10),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Plans List
                if (_plans.isEmpty && !_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Loading plans...', style: TextStyle(color: Colors.white54)),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final isSelected = _selectedPlan != null && _selectedPlan!['id'] == plan['id'];
                    final months = plan['months'];
                    
                    // Calculate estimated date
                    final lockTillDate = DateTime.now().add(Duration(days: (months * 30).toInt()));
                    final dateStr = DateFormat('dd MMM yyyy').format(lockTillDate);
                    
                    // Calculate estimated profit
                    final returnRate = double.tryParse(plan['return_percentage'].toString()) ?? 0.0;
                    final estProfit = currentValue * (returnRate / 100);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlan = plan),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? themeColor : Colors.white.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected 
                              ? [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)]
                              : [],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Radio button
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? themeColor : Colors.white54, width: 2),
                              ),
                              child: isSelected 
                                  ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor)))
                                  : null,
                            ),
                            
                            // Months and Date
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    months >= 12 
                                        ? '${months ~/ 12} YEAR${months >= 24 ? 'S' : ''}'
                                        : '$months MONTHS',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white54, size: 12),
                                      const SizedBox(width: 4),
                                      Text('Lock till $dateStr', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Return info
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up, color: themeColor, size: 28),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Get extra', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                        Text('$returnRate%', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold)),
                                        const Text('yearly return on your investment', style: TextStyle(color: Colors.white54, fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action Button / Profit
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('EST. EXTRA PROFIT', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                                  const SizedBox(height: 2),
                                  Text('+ ${_formatINR(estProfit)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? themeColor : Colors.transparent,
                                      border: Border.all(color: themeColor),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isSelected ? 'SELECTED' : 'SELECT',
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : themeColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 20),
                
                // Summary Footer
                if (_selectedPlan != null && currentValue > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.1)),
                        bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bar_chart, color: themeColor, size: 30),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ESTIMATED MATURITY VALUE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(
                                  _formatINR(currentValue + (currentValue * (double.parse(_selectedPlan!['return_percentage'].toString()) / 100))),
                                  style: TextStyle(color: themeColor, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL EXTRA PROFIT', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(
                              '+ ${_formatINR(currentValue * (double.parse(_selectedPlan!['return_percentage'].toString()) / 100))}',
                              style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 10),
                  const Text(
                    '* Values are estimated and may vary with market conditions.',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _selectedPlan == null || parsedAmount <= 0) ? null : _lockMetal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      disabledBackgroundColor: themeColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock, color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Text('CONFIRM LOCK-IN', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.security, color: Colors.white54, size: 14),
                    SizedBox(width: 8),
                    Text('Your investment is 100% secure with bank-grade protection', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
