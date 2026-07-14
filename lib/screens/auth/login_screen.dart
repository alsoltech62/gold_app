import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendOtp(_mobileController.text);
      if (success) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(mobile: _mobileController.text),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const SizedBox(height: 60),
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFFB08D57),
                    size: 50,
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 30),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                  const Text(
                    'Login to manage your gold savings',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(),
                  const SizedBox(height: 50),
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone_android, color: Color(0xFFB08D57)),
                      hintText: 'Enter your 10 digit mobile number',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter mobile number';
                      }
                      if (value.length != 10) {
                        return 'Enter a valid 10 digit number';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : const Text('GET OTP'),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 800.ms).scale(),
                  const SizedBox(height: 30),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                          },
                          child: const Text(
                            "Register Now",
                            style: TextStyle(color: Color(0xFFB08D57), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1.seconds),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
