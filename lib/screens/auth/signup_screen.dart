import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await auth.signup({
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'aadhar_number': _aadharController.text,
        'pan_number': _panController.text,
      });

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Signup successful! Please login.')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Signup failed')),
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
            colors: [Colors.black, const Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn().slideX(),
                  const Text(
                    'Join the premium gold saving platform',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                  const SizedBox(height: 40),
                  
                  _buildSectionTitle('Personal Information'),
                  _buildTextField(_nameController, 'Full Name', Icons.person),
                  _buildTextField(_mobileController, 'Mobile Number', Icons.phone_android, keyboardType: TextInputType.phone),
                  _buildTextField(_emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Address Details'),
                  _buildTextField(_addressController, 'Full Address', Icons.home),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_cityController, 'City', Icons.location_city)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField(_stateController, 'State', Icons.map)),
                    ],
                  ),
                  _buildTextField(_pincodeController, 'Pincode', Icons.pin_drop, keyboardType: TextInputType.number),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Identity Verification'),
                  _buildTextField(_aadharController, 'Aadhar Number', Icons.credit_card, keyboardType: TextInputType.number),
                  _buildTextField(_panController, 'PAN Number', Icons.badge),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleSignup,
                          child: auth.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('REGISTER NOW'),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 400.ms).scale(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFFFD700), size: 20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
