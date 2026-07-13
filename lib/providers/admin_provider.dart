import 'package:flutter/material.dart';
import '../core/api_client.dart';

class AdminProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _adminStats;
  Map<String, dynamic> _settings = {};
  bool _isLoading = false;

  Map<String, dynamic>? get adminStats => _adminStats;
  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> fetchAdminDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/admin/dashboard.php');
      if (response['success'] == true) {
        _adminStats = response['data'];
      }
    } catch (e) {
      debugPrint('Error fetching admin dashboard: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateGoldRate(double rate) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/admin/gold_rate.php', {
        'rate_per_gram': rate,
        'date': DateTime.now().toIso8601String().split('T')[0],
      });
      _isLoading = false;
      notifyListeners();
      return response['success'] == true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/admin/settings.php');
      if (response['success'] == true && response['data'] != null) {
        _settings = response['data'];
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/admin/settings.php', newSettings);
      if (response['success'] == true) {
        _settings.addAll(newSettings);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
