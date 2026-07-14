import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:goldapp/providers/admin_provider.dart';
import 'package:goldapp/screens/admin/admin_update_rate_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/gold_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAdminDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADMIN PANEL')),
      body: Consumer<AdminProvider>(
        builder: (context, admin, child) {
          if (admin.isLoading && admin.adminStats == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFB08D57)));
          }

          final stats = admin.adminStats ?? {};

          return RefreshIndicator(
            onRefresh: () => admin.fetchAdminDashboard(),
            color: const Color(0xFFB08D57),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Overview',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),
                  _buildAdminStats(stats),
                  const SizedBox(height: 30),
                  const Text(
                    'Admin Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildAdminActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminStats(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildStatBox('Total Users', '${stats['total_users'] ?? 0}', Icons.people),
        _buildStatBox('Total Gold (gms)', '${stats['total_customer_gold'] ?? 0}', Icons.fitness_center),
        _buildStatBox('Total Revenue', '₹${stats['total_revenue'] ?? 0}', Icons.monetization_on),
        _buildStatBox('Pending Deliv.', '${stats['pending_deliveries'] ?? 0}', Icons.local_shipping),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFB08D57), size: 30),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Column(
      children: [
        _buildActionTile(Icons.trending_up, 'Update Gold Rate', 'Set daily price per gram', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUpdateRateScreen()));
        }),
        _buildActionTile(Icons.person_add, 'Manage Customers', 'Add, edit or block users', () {}),
        _buildActionTile(Icons.list_alt, 'Manage Transactions', 'Approve sell/delivery requests', () {}),
        _buildActionTile(Icons.warning_amber_rounded, 'Reconciliation', 'Check for system mismatches', () {}),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFB08D57)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
