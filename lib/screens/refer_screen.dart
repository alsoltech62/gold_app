import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  bool _isLoading = true;
  int _totalReferrals = 0;
  double _totalSilverBonus = 0;
  List<dynamic> _referredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchReferralStats();
  }

  Future<void> _fetchReferralStats() async {
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.get(
        Uri.parse('https://goldpay.odofast.in/api/user/referral_stats.php'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _totalReferrals = data['data']['total_referrals'] ?? 0;
          _totalSilverBonus = (data['data']['total_silver_bonus'] ?? 0).toDouble();
          _referredUsers = data['data']['referred_users'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching referral stats: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final referralCode = user?['mobile'] ?? '';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Refer & Earn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Referral Code', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(referralCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700), letterSpacing: 2)),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral Code Copied!')));
                        },
                      ),
                    ],
                  ),
                  const Text('Share this code! They get 50 JC on signup, and you get 500 JC when they buy ₹1000 Gold/Silver.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Icon(Icons.people, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        Text(_totalReferrals.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('Total Referrals', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Icon(Icons.diamond, color: Colors.purple, size: 32),
                        const SizedBox(height: 8),
                        Text('${_totalSilverBonus.toStringAsFixed(0)} JC', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('JC Bonus', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text('Recent Referrals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            
            Expanded(
              child: _referredUsers.isEmpty
                  ? const Center(child: Text('No referrals yet.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _referredUsers.length,
                      itemBuilder: (context, index) {
                        final u = _referredUsers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E1E1E),
                            child: Text(u['name'][0].toUpperCase(), style: const TextStyle(color: Color(0xFFFFD700))),
                          ),
                          title: Text(u['name'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text('Joined: ${u['created_at'].split(' ')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
