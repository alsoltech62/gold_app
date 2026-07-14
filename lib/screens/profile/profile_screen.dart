import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../transactions/transaction_list_screen.dart';
import 'support_screen.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';
import 'returns_screen.dart';
import 'terms_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE'), centerTitle: true),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user ?? {};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF1E1E1E),
                child: Icon(Icons.person, size: 50, color: Color(0xFFB08D57)),
              ),
              const SizedBox(height: 20),
              Text(
                user['name'] ?? 'User',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user['mobile'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _buildListTile(Icons.edit, 'Edit Profile', () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              }),
              _buildListTile(Icons.history, 'Transaction History', () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TransactionListScreen(),
                  ),
                );
              }),
              _buildListTile(
                Icons.card_giftcard,
                'Refer & Earn (Copy Code)',
                () {
                  Clipboard.setData(ClipboardData(text: user['mobile'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Referral code copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              _buildListTile(Icons.share, 'Share Referral Link', () {
                final mobile = user['mobile'] ?? '';
                Share.share(
                  'Join Gold Savings and start investing in digital gold & silver!\nUse my referral code: $mobile\nhttps://goldpay.odofast.in/signup?ref=$mobile',
                  subject: 'Join Gold Savings',
                );
              }),
              _buildListTile(Icons.help_outline, 'Support', () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                );
              }),
              _buildListTile(Icons.info_outline, 'About Us', () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
              }),
              _buildListTile(Icons.gavel, 'Terms & Conditions', () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TermsScreen()));
              }),
              _buildListTile(Icons.privacy_tip, 'Privacy Policy', () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                );
              }),
              _buildListTile(Icons.keyboard_return, 'Returns Policy', () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReturnsScreen()),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  auth.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFB08D57)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
