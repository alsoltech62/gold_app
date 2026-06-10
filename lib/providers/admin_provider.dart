import 'package:flutter/material.dart';
import '../core/api_client.dart';

class AdminProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _adminStats;
  bool _isLoading = false;

  Map<String, dynamic>? get adminStats => _adminStats;
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
}
