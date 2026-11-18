import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../auth/login_screen.dart';
import '../transactions/transaction_list_screen.dart';
import 'support_screen.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';
import 'returns_screen.dart';
import 'terms_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchUser();
    });
  }

  int _calculateScore(Map<String, dynamic> user) {
    if (user['profile_completion_percentage'] != null) {
      return (user['profile_completion_percentage'] as num).toInt();
    }
    if (user['profile_completion'] != null && user['profile_completion']['percentage'] != null) {
      return (user['profile_completion']['percentage'] as num).toInt();
    }
    int score = 0;
    if ((user['mobile'] ?? '').toString().trim().isNotEmpty) score += 10;
    final name = (user['name'] ?? '').toString().trim();
    if (name.isNotEmpty && name.toLowerCase() != 'user' && name.length >= 2) score += 15;
    if ((user['email'] ?? '').toString().contains('@')) score += 10;
    if ((user['dob'] ?? '').toString().trim().isNotEmpty) score += 10;
    if ((user['address'] ?? '').toString().trim().isNotEmpty) score += 5;
    if ((user['city'] ?? '').toString().trim().isNotEmpty && (user['pincode'] ?? '').toString().trim().isNotEmpty) score += 10;
    if ((user['bank_name'] ?? '').toString().trim().isNotEmpty && (user['account_number'] ?? '').toString().trim().isNotEmpty) score += 20;
    if ((user['pan_number'] ?? '').toString().trim().isNotEmpty || (user['pan_image'] ?? '').toString().trim().isNotEmpty) score += 10;
    if ((user['aadhar_number'] ?? '').toString().trim().isNotEmpty || (user['aadhar_front'] ?? '').toString().trim().isNotEmpty) score += 10;
    return score > 100 ? 100 : score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE'), centerTitle: true),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user ?? {};
          final percentage = _calculateScore(user);
          final isComplete = percentage >= 100;

          return RefreshIndicator(
            color: const Color(0xFFB08D57),
            onRefresh: () => auth.fetchUser(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Avatar
                const Center(
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Color(0xFF1E1E1E),
                    child: Icon(Icons.person, size: 48, color: Color(0xFFB08D57)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user['name'] != null && user['name'].toString().toLowerCase() != 'user' && user['name'].toString().isNotEmpty
                      ? user['name']
                      : 'Gold Investor',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['mobile'] != null ? '+91 ${user['mobile']}' : '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // ── DYNAMIC PROFILE COMPLETION CARD & PROGRESS BAR ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isComplete
                          ? [const Color(0xFF142416), const Color(0xFF0E1A10)]
                          : [const Color(0xFF241C0E), const Color(0xFF171208)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isComplete
                          ? Colors.green.withOpacity(0.4)
                          : const Color(0xFFB08D57).withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isComplete ? Icons.verified : Icons.stars_rounded,
                                color: isComplete ? Colors.green : const Color(0xFFB08D57),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Profile Status',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isComplete
                                  ? Colors.green.withOpacity(0.2)
                                  : const Color(0xFFB08D57).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isComplete ? '100% COMPLETE' : '$percentage% COMPLETED',
                              style: TextStyle(
                                color: isComplete ? Colors.green : const Color(0xFFB08D57),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage / 100.0,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete ? Colors.green : const Color(0xFFB08D57),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Prompt banner or verified note
                      if (!isComplete) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFE5A93C), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please complete your full profile to unlock bank withdrawals & full account limits.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB08D57),
                              side: const BorderSide(color: Color(0xFFB08D57)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text(
                              'Complete Full Profile Now',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              ).then((_) => auth.fetchUser());
                            },
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Your profile is fully verified and up to date!',
                              style: TextStyle(color: Colors.green.shade300, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── MENU TILES ──
                Consumer<LanguageProvider>(
                  builder: (context, langProv, _) => _buildListTile(
                    Icons.translate,
                    langProv.isHindi ? 'भाषा बदलें (हिंदी)' : 'Language (English)',
                    () => _showLanguageModal(context, langProv),
                  ),
                ),
                _buildListTile(Icons.edit_note, 'Edit Profile Details', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ).then((_) => auth.fetchUser());
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
                    'Join Gold Savings and start investing in 24K digital gold!\nUse my referral code: $mobile\nhttps://goldbarpe.com/signup?ref=$mobile',
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.12),
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    auth.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLanguageModal(BuildContext context, LanguageProvider langProv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language / भाषा चुनें',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFFB08D57)),
              title: const Text('English', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              trailing: !langProv.isHindi ? const Icon(Icons.check, color: Color(0xFFB08D57)) : null,
              onTap: () {
                langProv.setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.translate, color: Color(0xFFB08D57)),
              title: const Text('हिंदी (Hindi)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              trailing: langProv.isHindi ? const Icon(Icons.check, color: Color(0xFFB08D57)) : null,
              onTap: () {
                langProv.setLanguage('hi');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFB08D57).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFB08D57), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
