import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _panController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user ?? {};
    _nameController.text = user['name'] ?? '';
    _emailController.text = user['email'] ?? '';
    _panController.text = user['pan_number'] ?? '';
    _bankNameController.text = user['bank_name'] ?? '';
    _accNoController.text = user['account_number'] ?? '';
    _ifscController.text = user['ifsc_code'] ?? '';
    _cityController.text = user['city'] ?? '';
    _areaController.text = user['address'] ?? '';
    _dobController.text = user['dob'] ?? '';
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      
      final response = await http.put(
        Uri.parse('https://goldpay.odofast.in/backend/api/user/profile.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text,
          'email': _emailController.text,
          'pan_number': _panController.text,
          'bank_name': _bankNameController.text,
          'account_number': _accNoController.text,
          'ifsc_code': _ifscController.text,
          'city': _cityController.text,
          'address': _areaController.text,
          'dob': _dobController.text,
        }),
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        await auth.fetchUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to update')));
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildField('Full Name', _nameController),
                _buildField('Email', _emailController),
                _buildField('Date of Birth (YYYY-MM-DD)', _dobController),
                _buildField('City', _cityController),
                _buildField('Area', _areaController),
                _buildField('PAN Card', _panController),
                _buildField('Bank Name', _bankNameController),
                _buildField('Account No', _accNoController),
                _buildField('IFSC Code', _ifscController),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: _updateProfile,
                  child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
        ),
      ),
    );
  }
}
