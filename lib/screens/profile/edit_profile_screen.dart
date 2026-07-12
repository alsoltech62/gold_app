import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
  final _panController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _dobController = TextEditingController();

  File? _aadharFront;
  File? _aadharBack;
  File? _panImage;
  final ImagePicker _picker = ImagePicker();

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
        
        // Upload KYC Docs if any selected
        if (_aadharFront != null || _aadharBack != null || _panImage != null) {
          var request = http.MultipartRequest('POST', Uri.parse('https://goldpay.odofast.in/backend/api/user/profile.php'));
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
                _buildField('Date of Birth (YYYY-MM-DD)', _dobController, readOnly: true, onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFFFD700),
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
                      _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                }),
                _buildField('City', _cityController),
                _buildField('Area', _areaController),
                _buildField('PAN Card', _panController),
                _buildField('Bank Name', _bankNameController),
                _buildField('Account No', _accNoController),
                _buildField('IFSC Code', _ifscController),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('KYC Documents', style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildImagePicker('Aadhar Card (Front)', _aadharFront, (f) => setState(() => _aadharFront = f)),
                _buildImagePicker('Aadhar Card (Back)', _aadharBack, (f) => setState(() => _aadharBack = f)),
                _buildImagePicker('PAN Card', _panImage, (f) => setState(() => _panImage = f)),

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

  Widget _buildField(String label, TextEditingController controller, {bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
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

  Widget _buildImagePicker(String title, File? file, Function(File) onPicked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () async {
          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            onPicked(File(image.path));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              file != null 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.upload_file, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
