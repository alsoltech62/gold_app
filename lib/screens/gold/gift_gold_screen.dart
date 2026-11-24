import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/gold_provider.dart';
import '../../providers/auth_provider.dart';

class GiftGoldScreen extends StatefulWidget {
  const GiftGoldScreen({super.key});

  @override
  State<GiftGoldScreen> createState() => _GiftGoldScreenState();
}

class _GiftGoldScreenState extends State<GiftGoldScreen> {
  final _amountController = TextEditingController();
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController(text: 'Wishing you wealth, health & joy with 24K pure digital gold! 🎁');

  double _grams = 0.0;
  String _paymentMethod = 'CASHFREE';
  bool _isLoading = false;

  final List<double> _quickAmounts = [100, 500, 1000, 2100, 5000];
  final List<String> _quickGreetings = [
    'Happy Birthday 🎂',
    'Congratulations 🎉',
    'Best Wishes ✨',
    'With Love ❤️',
    'Happy Anniversary 💍',
    'Prosperity & Joy 🌟'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoldProvider>(context, listen: false).fetchCurrentRate();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _mobileController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _calculateGrams(String value) {
    if (value.isEmpty) {
      setState(() => _grams = 0.0);
      return;
    }
    final amount = double.tryParse(value) ?? 0.0;
    final rateRaw = Provider.of<GoldProvider>(context, listen: false).currentRate?['rate_per_gram'];
    final rate = rateRaw != null ? double.tryParse(rateRaw.toString()) ?? 0.0 : 0.0;
    if (rate > 0) {
      setState(() => _grams = amount / rate);
    }
  }

  void _selectQuickAmount(double amt) {
    _amountController.text = amt.toInt().toString();
    _calculateGrams(_amountController.text);
  }

  void _handleSendGift() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum gift amount is ₹10'), backgroundColor: Colors.red),
      );
      return;
    }

    final mobile = _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final cleanMobile = mobile.length > 10 ? mobile.substring(mobile.length - 10) : mobile;
    if (cleanMobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number'), backgroundColor: Colors.red),
      );
      return;
    }

    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    final userMobile = (currentUser?['mobile'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
    final cleanUserMobile = userMobile.length > 10 ? userMobile.substring(userMobile.length - 10) : userMobile;
    if (cleanMobile == cleanUserMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot gift gold to yourself!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final goldProvider = Provider.of<GoldProvider>(context, listen: false);

    final res = await goldProvider.createGoldGift(
      amountInr: amount,
      recipientMobile: cleanMobile,
      recipientName: _nameController.text.trim(),
      message: _messageController.text.trim(),
      paymentMethod: _paymentMethod,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'] ?? {};
      if (_paymentMethod == 'CASHFREE') {
        final paymentUrl = data['payment_url'];
        final orderId = data['order_id'];
        final giftCode = data['gift_code'];
        final shareLink = data['share_link'];

        if (paymentUrl != null) {
          try {
            final Uri url = Uri.parse(paymentUrl);
            if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (mounted) {
                _showCashfreeGiftVerificationDialog(orderId, giftCode, shareLink, amount, cleanMobile);
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open payment page'), backgroundColor: Colors.red),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error launching payment: $e'), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        // Wallet payment success
        _showGiftSuccessDialog(
          giftCode: data['gift_code'] ?? '',
          shareLink: data['share_link'] ?? 'https://goldbarpe.com/claim-gift?code=${data['gift_code']}',
          amount: amount,
          grams: (data['gold_grams'] != null) ? double.tryParse(data['gold_grams'].toString()) ?? _grams : _grams,
          recipientMobile: cleanMobile,
          recipientName: _nameController.text.trim(),
          message: _messageController.text.trim(),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to create gold gift'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCashfreeGiftVerificationDialog(String orderId, String giftCode, String shareLink, double amount, String recipientMobile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFB08D57), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Color(0xFFB08D57)),
            SizedBox(width: 10),
            Text('Complete Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Please complete the payment in the opened browser window, then tap "Verify Payment" to activate your gift.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB08D57),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isLoading = true);
              final verifyRes = await Provider.of<GoldProvider>(context, listen: false)
                  .verifyGiftPayment(orderId, giftCode: giftCode);
              setState(() => _isLoading = false);

              if (!mounted) return;

              if (verifyRes['success'] == true) {
                final vData = verifyRes['data'] ?? {};
                _showGiftSuccessDialog(
                  giftCode: giftCode,
                  shareLink: vData['share_link'] ?? shareLink,
                  amount: amount,
                  grams: (vData['gold_grams'] != null) ? double.tryParse(vData['gold_grams'].toString()) ?? _grams : _grams,
                  recipientMobile: recipientMobile,
                  recipientName: _nameController.text.trim(),
                  message: _messageController.text.trim(),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(verifyRes['message'] ?? 'Payment verification failed.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Verify Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGiftSuccessDialog({
    required String giftCode,
    required String shareLink,
    required double amount,
    required double grams,
    required String recipientMobile,
    required String recipientName,
    required String message,
  }) {
    final senderName = Provider.of<AuthProvider>(context, listen: false).user?['name'] ?? 'Your Friend';
    final shareText = '''🎁 Hi! $senderName has gifted you ${grams.toStringAsFixed(4)}g of 24K Pure Digital Gold (worth ₹${amount.toStringAsFixed(2)}) on Gold Platform!

Message: "$message"

👉 Click here to claim your Gold:
$shareLink

Install the app or open the website with mobile $recipientMobile to claim directly to your vault!''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFFB08D57), width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFB08D57).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB08D57), width: 2),
              ),
              child: const Icon(Icons.card_giftcard, color: Color(0xFFB08D57), size: 36),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            const Text(
              'Gold Gift Sent Successfully! 🎉',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Share this claim link with $recipientMobile so they can claim their ${grams.toStringAsFixed(4)}g 24K gold.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Gift Summary Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gift Amount:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pure 24K Gold:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text('${grams.toStringAsFixed(4)}g', style: const TextStyle(color: Color(0xFFB08D57), fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recipient:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(recipientName.isNotEmpty ? '$recipientName ($recipientMobile)' : recipientMobile, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // WhatsApp Share Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final encodedText = Uri.encodeComponent(shareText);
                  final waUri = Uri.parse('https://wa.me/91$recipientMobile?text=$encodedText');
                  try {
                    await launchUrl(waUri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    Share.share(shareText);
                  }
                },
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),

            // Copy Link & System Share Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB08D57),
                      side: const BorderSide(color: Color(0xFFB08D57)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gift claim link copied to clipboard! 📋')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Link', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Share.share(shareText);
                    },
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Link', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Back to buy flow
              },
              child: const Text('Done / Return', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldProvider = Provider.of<GoldProvider>(context);
    final rateRaw = goldProvider.currentRate?['rate_per_gram'];
    final rate = rateRaw != null ? double.tryParse(rateRaw.toString()) ?? 0.0 : 0.0;
    final userData = goldProvider.dashboardData ?? {};
    final inrWallet = double.tryParse(userData['inr_wallet']?.toString() ?? '0') ?? 0.0;
    final japsanWallet = double.tryParse(userData['japsan_wallet']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Gift Pure 24K Gold 🎁'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFB08D57).withOpacity(0.25),
                    const Color(0xFF1E1E1E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFB08D57).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB08D57).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard, color: Color(0xFFB08D57), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gift 24K Gold to Anyone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          rate > 0 ? 'Live Rate: ₹${rate.toStringAsFixed(2)}/g' : 'Loading live gold rate...',
                          style: const TextStyle(color: Color(0xFFB08D57), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),

            // Amount Input
            const Text('Gift Amount (₹)', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              onChanged: _calculateGrams,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Color(0xFFB08D57), fontSize: 22, fontWeight: FontWeight.bold),
                hintText: '500',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFB08D57), width: 1.5),
                ),
                suffixText: _grams > 0 ? '${_grams.toStringAsFixed(4)}g' : '',
                suffixStyle: const TextStyle(color: Color(0xFFB08D57), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickAmounts.map((amt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('₹${amt.toInt()}'),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      backgroundColor: const Color(0xFF1E1E1E),
                      side: BorderSide(color: const Color(0xFFB08D57).withOpacity(0.3)),
                      onPressed: () => _selectQuickAmount(amt),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Recipient Details Section
            const Text('Recipient Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_android, color: Color(0xFFB08D57)),
                prefixText: '+91 ',
                prefixStyle: const TextStyle(color: Colors.white70),
                counterText: '',
                labelText: 'Recipient Mobile Number *',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFB08D57))),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFB08D57)),
                labelText: 'Recipient Name (Optional)',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFB08D57))),
              ),
            ),
            const SizedBox(height: 20),

            // Greeting Message Section
            const Text('Greeting Message', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickGreetings.map((g) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(g),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                      backgroundColor: const Color(0xFF1E1E1E),
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                      onPressed: () {
                        setState(() {
                          _messageController.text = '$g! Wishing you pure prosperity with 24K Gold.';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _messageController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a personal greeting message...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFB08D57))),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Section
            const Text('Select Payment Method', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildPaymentOption(
              id: 'CASHFREE',
              title: 'Online Payment (UPI, Cards, NetBanking)',
              subtitle: 'Instant & Secure via Cashfree',
              icon: Icons.flash_on,
            ),
            if (inrWallet > 0)
              _buildPaymentOption(
                id: 'INR_WALLET',
                title: 'INR Wallet',
                subtitle: 'Available: ₹${inrWallet.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
              ),
            if (japsanWallet > 0)
              _buildPaymentOption(
                id: 'JAPSAN_WALLET',
                title: 'Japsan Coin Ecosystem Wallet',
                subtitle: 'Available: ₹${japsanWallet.toStringAsFixed(2)}',
                icon: Icons.monetization_on,
              ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB08D57),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _handleSendGift,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Gift Gold Now',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFB08D57) : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFB08D57) : Colors.grey, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFFB08D57) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
