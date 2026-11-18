import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_nav_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _mobileFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _mobileController = TextEditingController();
  final _referralController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  int _resendTimer = 30;
  bool _canResend = false;
  bool _isResending = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _mobileController.dispose();
    _referralController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_mobileFormKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await auth.sendSignupOtp(
      _mobileController.text.trim(),
      referralCode: _referralController.text.trim(),
    );

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() => _isOtpSent = true);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully! Please check your SMS.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (response['already_registered'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Already registered. Please login.'),
            action: SnackBarAction(
              label: 'LOGIN',
              textColor: const Color(0xFFB08D57),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to send OTP')),
        );
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || _isResending) return;
    setState(() => _isResending = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await auth.sendSignupOtp(
      _mobileController.text.trim(),
      referralCode: _referralController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (response['success'] == true) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to resend OTP')),
      );
    }
  }

  Future<void> _handleVerifyAndSignup() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await auth.signup({
      'mobile': _mobileController.text.trim(),
      'otp': _otpController.text.trim(),
      'referral_code': _referralController.text.trim(),
    });

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Registration successful! Welcome to Gold Platform.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (_isOtpSent) {
              setState(() {
                _isOtpSent = false;
                _otpController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black.withOpacity(0.9),
              const Color(0xFF14120E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: !_isOtpSent ? _buildMobileStep() : _buildOtpStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStep() {
    return Form(
      key: _mobileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFB08D57).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB08D57).withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Color(0xFFB08D57), size: 14),
                SizedBox(width: 6),
                Text(
                  '50 JC Welcome Bonus',
                  style: TextStyle(color: Color(0xFFB08D57), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 16),
          const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 150.ms).slideX(),
          const SizedBox(height: 6),
          const Text(
            'Enter your mobile number to get started. No lengthy forms required!',
            style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
          ).animate().fadeIn(delay: 250.ms).slideX(),
          const SizedBox(height: 40),

          // Mobile Number Field
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone_android, color: Color(0xFFB08D57), size: 22),
              prefixText: '+91 ',
              prefixStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              hintText: 'Enter 10-digit number',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter mobile number';
              }
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                return 'Please enter valid 10-digit number';
              }
              return null;
            },
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 20),

          // Referral Code (Optional)
          TextFormField(
            controller: _referralController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Referral Code (Optional)',
              prefixIcon: Icon(Icons.group_outlined, color: Color(0xFFB08D57), size: 22),
              hintText: "Referrer's mobile number",
            ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 36),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB08D57),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('GET OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                );
              },
            ),
          ).animate().fadeIn(delay: 550.ms).scale(),

          const SizedBox(height: 32),

          // Sign In Option
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(color: Color(0xFFB08D57), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 650.ms),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFB08D57).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB08D57).withOpacity(0.3)),
            ),
            child: const Text(
              'Step 2 of 2 · Verification',
              style: TextStyle(color: Color(0xFFB08D57), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 16),
          const Text(
            'Verify OTP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 150.ms).slideX(),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Sent to +91 ${_mobileController.text.trim()}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isOtpSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text(
                  'Change',
                  style: TextStyle(color: Color(0xFFB08D57), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 250.ms).slideX(),
          const SizedBox(height: 40),

          // OTP field
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              color: Color(0xFFB08D57),
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(color: Colors.grey, letterSpacing: 10),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter 6-digit OTP';
              }
              if (value.trim().length != 6) {
                return 'OTP must be 6 digits';
              }
              return null;
            },
          ).animate().fadeIn(delay: 350.ms).scale(),

          const SizedBox(height: 24),

          // Resend row
          Center(
            child: _isResending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFB08D57), strokeWidth: 2))
                : TextButton(
                    onPressed: _canResend ? _handleResendOtp : null,
                    child: Text(
                      _canResend ? 'Resend Code' : 'Resend Code in ${_resendTimer}s',
                      style: TextStyle(color: _canResend ? const Color(0xFFB08D57) : Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
          ).animate().fadeIn(delay: 450.ms),

          const SizedBox(height: 24),

          // Verify & Sign Up button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleVerifyAndSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB08D57),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                        )
                      : const Text(
                          'VERIFY & SIGN UP',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                        ),
                );
              },
            ),
          ).animate().fadeIn(delay: 550.ms).scale(),
        ],
      ),
    );
  }
}
