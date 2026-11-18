import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  final _holderNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accNoController = TextEditingController();
  final _ifscController = TextEditingController();

  final _panController = TextEditingController();
  final _aadharController = TextEditingController();

  File? _aadharFront;
  File? _aadharBack;
  File? _panImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user ?? {};
    final name = (user['name'] ?? '').toString();
    _nameController.text = (name.toLowerCase() == 'user') ? '' : name;
    _emailController.text = user['email'] ?? '';
    _dobController.text = user['dob'] ?? '';
    _areaController.text = user['address'] ?? '';
    _cityController.text = user['city'] ?? '';
    _stateController.text = user['state'] ?? '';
    _pincodeController.text = user['pincode'] ?? '';

    _holderNameController.text = user['account_holder_name'] ?? '';
    _bankNameController.text = user['bank_name'] ?? '';
    _accNoController.text = user['account_number'] ?? '';
    _ifscController.text = user['ifsc_code'] ?? '';

    _panController.text = user['pan_number'] ?? '';
    _aadharController.text = user['aadhar_number'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _holderNameController.dispose();
    _bankNameController.dispose();
    _accNoController.dispose();
    _ifscController.dispose();
    _panController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  int _calculateLocalPercentage() {
    int score = 10; // Mobile already verified
    if (_nameController.text.trim().isNotEmpty && _nameController.text.trim().toLowerCase() != 'user') score += 15;
    if (_emailController.text.trim().contains('@')) score += 10;
    if (_dobController.text.trim().isNotEmpty) score += 10;
    if (_areaController.text.trim().isNotEmpty) score += 5;
    if (_cityController.text.trim().isNotEmpty && _stateController.text.trim().isNotEmpty && _pincodeController.text.trim().isNotEmpty) score += 10;
    if (_bankNameController.text.trim().isNotEmpty && _accNoController.text.trim().isNotEmpty && _ifscController.text.trim().isNotEmpty) score += 20;
    if (_panController.text.trim().isNotEmpty || _panImage != null) score += 10;
    if (_aadharController.text.trim().isNotEmpty || _aadharFront != null) score += 10;
    return score > 100 ? 100 : score;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      final profileUrl = '${ApiClient.baseUrl}/api/user/profile.php';

      final response = await http.put(
        Uri.parse(profileUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dob': _dobController.text.trim(),
          'address': _areaController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'account_holder_name': _holderNameController.text.trim(),
          'bank_name': _bankNameController.text.trim(),
          'account_number': _accNoController.text.trim(),
          'ifsc_code': _ifscController.text.trim(),
          'pan_number': _panController.text.trim(),
          'aadhar_number': _aadharController.text.trim(),
        }),
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        // Upload KYC Docs if any selected
        if (_aadharFront != null || _aadharBack != null || _panImage != null) {
          var request = http.MultipartRequest('POST', Uri.parse(profileUrl));
          request.headers['Authorization'] = 'Bearer $token';

          if (_aadharFront != null) {
            request.files.add(await http.MultipartFile.fromPath('aadhar_front', _aadharFront!.path));
          }
          if (_aadharBack != null) {
            request.files.add(await http.MultipartFile.fromPath('aadhar_back', _aadharBack!.path));
          }
          if (_panImage != null) {
            request.files.add(await http.MultipartFile.fromPath('pan_image', _panImage!.path));
          }

          await request.send();
        }

        await auth.fetchUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to update profile')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completionPct = _calculateLocalPercentage();
    final isComplete = completionPct >= 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB08D57)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Dynamic Progress Banner at top
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: isComplete ? Colors.green.withOpacity(0.12) : const Color(0xFFB08D57).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isComplete ? Colors.green.withOpacity(0.3) : const Color(0xFFB08D57).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isComplete ? 'Profile 100% Complete' : 'Profile $completionPct% Complete',
                              style: TextStyle(
                                color: isComplete ? Colors.green : const Color(0xFFB08D57),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              isComplete ? Icons.verified : Icons.trending_up,
                              color: isComplete ? Colors.green : const Color(0xFFB08D57),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: completionPct / 100.0,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isComplete ? Colors.green : const Color(0xFFB08D57),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section 1: Personal Information
                  _buildSectionHeader('Personal Information', Icons.person_outline),
                  _buildField('Full Name', _nameController, hint: 'Enter your full legal name'),
                  _buildField('Email Address', _emailController, keyboardType: TextInputType.emailAddress, hint: 'your.name@example.com'),
                  _buildField(
                    'Date of Birth (YYYY-MM-DD)',
                    _dobController,
                    readOnly: true,
                    hint: 'Select your birth date',
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1930),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFB08D57),
                                onPrimary: Colors.black,
                                surface: Color(0xFF1E1E1E),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _dobController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                  _buildField('Delivery Address', _areaController, hint: 'House/Street/Area'),
                  Row(
                    children: [
                      Expanded(child: _buildField('City', _cityController, hint: 'City')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('State', _stateController, hint: 'State')),
                    ],
                  ),
                  _buildField('Pincode', _pincodeController, keyboardType: TextInputType.number, maxLength: 6, hint: '6-digit pincode'),

                  const SizedBox(height: 16),

                  // Section 2: Bank Details
                  _buildSectionHeader('Bank Account Details', Icons.account_balance_outlined),
                  _buildField('Account Holder Name', _holderNameController, hint: 'Name as per bank records'),
                  _buildField('Bank Name', _bankNameController, hint: 'e.g. State Bank of India'),
                  _buildField('Account Number', _accNoController, keyboardType: TextInputType.number, isPassword: true, hint: 'Enter account number'),
                  _buildField('IFSC Code', _ifscController, textCapitalization: TextCapitalization.characters, hint: 'e.g. SBIN0001234'),

                  const SizedBox(height: 16),

                  // Section 3: KYC Details
                  _buildSectionHeader('KYC & Documents', Icons.security_outlined),
                  _buildField('PAN Number', _panController, textCapitalization: TextCapitalization.characters, maxLength: 10, hint: 'e.g. ABCDE1234F'),
                  _buildField('Aadhaar Number', _aadharController, keyboardType: TextInputType.number, maxLength: 12, hint: '12-digit Aadhaar number'),

                  const SizedBox(height: 12),
                  _buildImagePicker('Aadhaar Card (Front)', _aadharFront, (f) => setState(() => _aadharFront = f)),
                  _buildImagePicker('Aadhaar Card (Back)', _aadharBack, (f) => setState(() => _aadharBack = f)),
                  _buildImagePicker('PAN Card', _panImage, (f) => setState(() => _panImage = f)),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB08D57),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: _updateProfile,
                      child: const Text(
                        'SAVE PROFILE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB08D57), size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFB08D57),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    bool isPassword = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          filled: true,
          fillColor: Colors.white.withOpacity(0.03),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB08D57), width: 1.5),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildImagePicker(String title, File? file, Function(File) onPicked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
          if (image != null) {
            onPicked(File(image.path));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: Border.all(
              color: file != null ? Colors.green.withOpacity(0.5) : Colors.white12,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    file != null ? Icons.check_circle : Icons.upload_file_outlined,
                    color: file != null ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: file != null ? Colors.green : Colors.white70,
                      fontWeight: file != null ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                file != null ? 'Selected' : 'Upload',
                style: TextStyle(
                  color: file != null ? Colors.green : const Color(0xFFB08D57),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
