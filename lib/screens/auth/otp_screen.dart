import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_nav_screen.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  const OtpScreen({super.key, required this.mobile});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  int _resendTimer = 30;
  bool _canResend = false;
  bool _isResending = false;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    _tick();
  }

  void _tick() async {
    if (!mounted) return;
    if (_resendTimer > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendTimer--);
      _tick();
    } else {
      if (!mounted) return;
      setState(() => _canResend = true);
    }
  }

  void _handleResend() async {
    if (!_canResend || _isResending) return;
    setState(() => _isResending = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(widget.mobile);
    
    if (!mounted) return;
    setState(() => _isResending = false);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Resent Successfully!', style: TextStyle(color: Colors.green))));
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to resend OTP.')));
    }
  }

  void _handleVerify() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyOtp(widget.mobile, _otpController.text);
      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black.withOpacity(0.8),
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Verify OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn().slideX(),
                  Text(
                    'Enter the 6-digit code sent to ${widget.mobile}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                  const SizedBox(height: 50),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Color(0xFFB08D57),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(color: Colors.grey, letterSpacing: 10),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter OTP';
                      }
                      if (value.length != 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 400.ms).scale(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleVerify,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : const Text('VERIFY & LOGIN'),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 600.ms).scale(),
                  const SizedBox(height: 20),
                  Center(
                    child: _isResending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFB08D57), strokeWidth: 2))
                      : TextButton(
                          onPressed: _canResend ? _handleResend : null,
                          child: Text(
                            _canResend ? 'Resend Code' : 'Resend Code in ${_resendTimer}s',
                            style: TextStyle(color: _canResend ? const Color(0xFFB08D57) : Colors.grey),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
