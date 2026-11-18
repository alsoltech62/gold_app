import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  AuthProvider();

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null && _token!.trim().isNotEmpty) {
      final userSuccess = await fetchUser();
      if (userSuccess) {
        _isAuthenticated = true;
      } else {
        await logout();
      }
    } else {
      _isAuthenticated = false;
      _token = null;
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> fetchUser() async {
    try {
      final response = await _apiClient.get('/api/user/profile.php');
      if (response['success'] == true && response['data'] != null) {
        _user = response['data'];
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching user: $e');
      return false;
    }
  }

  Future<bool> sendOtp(String mobile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/auth/send_otp.php', {
        'mobile': mobile,
      });
      _isLoading = false;
      notifyListeners();
      return response['success'] ?? false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> sendSignupOtp(String mobile, {String? referralCode}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/auth/send_otp.php', {
        'mobile': mobile,
        'type': 'signup',
        if (referralCode != null && referralCode.trim().isNotEmpty) 'referral_code': referralCode.trim(),
      });
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/auth/signup.php', data);
      if (response['success'] == true && response['token'] != null) {
        _token = response['token'];
        _user = response['user'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
      }
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/auth/verify_otp.php', {
        'mobile': mobile,
        'otp': otp,
      });
      if (response['success'] == true) {
        _token = response['token'];
        _user = response['user'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _isAuthenticated = false;
    _token = null;
    _user = null;
    notifyListeners();
  }
}
