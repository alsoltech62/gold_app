import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/gold_provider.dart';

class LockInScreen extends StatefulWidget {
  const LockInScreen({super.key});

  @override
  State<LockInScreen> createState() => _LockInScreenState();
}

class _LockInScreenState extends State<LockInScreen> {
  String _amount = '';
  Map<String, dynamic>? _selectedPlan;
  bool _isLoading = false;

  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchPlans();
    _fetchHistory();
  }

  Future<void> _fetchPlans() async {
    try {
      final response = await http.get(Uri.parse('${ApiClient.baseUrl}/lockin/plans.php'));
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

  Future<void> _lockGold() async {
    final gold = Provider.of<GoldProvider>(context, listen: false);

    if (_amount.isEmpty || double.tryParse(_amount) == null || double.parse(_amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    final totalGrams = gold.dashboardData?['total_gold_grams'] ?? 0.0;
    if (double.parse(_amount) > totalGrams) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient gold balance'), backgroundColor: Colors.red),
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
      final result = await gold.createLockIn(_selectedPlan!['months'], double.parse(_amount));

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gold Locked Successfully!'), backgroundColor: Colors.green),
        );
        _fetchHistory();
        setState(() {
          _amount = '';
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
        const SnackBar(content: Text('Failed to lock gold'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lock & Earn')),
      body: Consumer<GoldProvider>(
        builder: (context, gold, child) {
          final totalGrams = gold.dashboardData?['total_gold_grams'] ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Color(0xFFFFD700), size: 40),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available Gold Balance', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text('${totalGrams.toStringAsFixed(4)} gms', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
                
                const SizedBox(height: 30),
                const Text('Select Lock-in Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final isSelected = _selectedPlan != null && _selectedPlan!['id'] == plan['id'];
                    final colorHex = plan['color_hex'] as String? ?? '#3B82F6';
                    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlan = plan),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? color : Colors.transparent),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${plan['months']} Months', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text('+${plan['returnRate']}%', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Extra Return', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            if (plan['plan_name'] != null) ...[
                              const SizedBox(height: 4),
                              Text(plan['plan_name'], style: const TextStyle(color: Colors.white30, fontSize: 8)),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 30),
                const Text('Gold to Lock (Gms)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    suffixIcon: TextButton(
                      onPressed: () => setState(() => _amount = totalGrams.toString()),
                      child: const Text('MAX', style: TextStyle(color: Color(0xFFFFD700))),
                    ),
                  ),
                  controller: TextEditingController(text: _amount)..selection = TextSelection.collapsed(offset: _amount.length),
                  onChanged: (val) => _amount = val,
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _lockGold,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('Confirm Lock-In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  const Text('Your Lock-In Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 15),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final h = _history[index];
                      final progress = (h['progress_percentage'] as num).toDouble();
                      final estExtra = (h['estimated_extra_gold'] as num).toDouble();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${h['gold_grams']}g', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
                                    const Text('Locked Amount', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text('+${h['return_percentage']}%', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(h['plan_name'] ?? '${h['months']} Months', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Maturity Progress', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                Text('${progress.toInt()}%', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                backgroundColor: Colors.black,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(h['start_date'].toString().split(' ')[0], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                Text('${h['days_remaining']} Days Left', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Est. Extra Gold', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text('+${estExtra.toStringAsFixed(4)}g', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Maturity Date', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text(h['end_date'].toString().split(' ')[0], style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
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
