import 'package:flutter/material.dart';
import '../core/api_client.dart';

class GoldProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _currentRate;
  Map<String, dynamic>? _silverRate;
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _sipHistory;
  List<dynamic> _tickets = [];
  List<dynamic> _deliveries = [];
  Map<String, dynamic>? _settings;
  bool _isLoading = false;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  Map<String, dynamic>? get currentRate => _currentRate;
  Map<String, dynamic>? get silverRate {
    if (_silverRate == null) return null;
    if (_silverRate!['current_rate'] != null) {
      return _silverRate!['current_rate'];
    }
    return _silverRate;
  }
  List<dynamic> get transactions => _transactions;
  Map<String, dynamic>? get sipHistory => _sipHistory;
  List<dynamic> get tickets => _tickets;
  List<dynamic> get deliveries => _deliveries;
  Map<String, dynamic>? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/user/dashboard.php');
      if (response['success'] == true) {
        _dashboardData = response['data'];
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCurrentRate() async {
    try {
      final response = await _apiClient.get('/api/gold/rate.php');
      if (response['success'] == true) {
        _currentRate = response['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching gold rate: $e');
    }
  }

  Future<void> fetchSilverRate() async {
    try {
      final response = await _apiClient.get('/api/silver/rate.php');
      if (response['success'] == true) {
        _silverRate = response['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching silver rate: $e');
    }
  }

  Future<void> fetchSettings() async {
    try {
      final response = await _apiClient.get('/api/user/settings.php');
      if (response['success'] == true) {
        _settings = response['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    }
  }

  Future<void> fetchSipHistory({String? metalType}) async {
    try {
      String url = '/api/user/sip_history.php';
      if (metalType != null && metalType != 'all') {
        url += '?metal_type=$metalType';
      }
      final response = await _apiClient.get(url);
      if (response['success'] == true) {
        _sipHistory = response['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching sip history: $e');
    }
  }

  Future<Map<String, dynamic>> cancelSip(int sipId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/user/cancel_sip.php', {
        'sip_id': sipId,
      });
      return response;
    } catch (e) {
      debugPrint('Error cancelling sip: $e');
      return {'success': false, 'message': 'Failed to cancel SIP'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/transactions/list.php');
      if (response['success'] == true) {
        _transactions = response['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTickets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/user/tickets.php');
      if (response['success'] == true) {
        _tickets = response['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createTicket(String subject, String description) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/user/tickets.php', {
        'subject': subject,
        'description': description,
      });
      _isLoading = false;
      if (response['success'] == true) {
        await fetchTickets();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<void> fetchDeliveries() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/user/deliveries.php');
      if (response['success'] == true) {
        _deliveries = response['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching deliveries: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestDelivery(double grams, String address, String city, String state, String pincode, [String metalType = 'gold']) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/delivery/request.php', {
        'grams': grams,
        'address': address,
        'delivery_address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'metal_type': metalType,
      });
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
        await fetchDeliveries();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> buyGold(double amountInr, String paymentMethod, String paymentId, {String? cashfreeOrderId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final body = {
        'amount_inr': amountInr,
        'payment_method': paymentMethod,
        'payment_id': paymentId,
      };
      if (cashfreeOrderId != null) body['cashfree_order_id'] = cashfreeOrderId;
      
      final response = await _apiClient.post('/api/gold/buy.php', body);
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> sellGold(double grams, {String? upiId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'gold_grams': grams,
      };
      if (upiId != null) body['upi_id'] = upiId;

      final response = await _apiClient.post('/api/gold/sell.php', body);
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> buySilver(double amountInr, String paymentMethod, {String? paymentId, String? cashfreeOrderId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final body = {
        'amount_inr': amountInr,
        'payment_method': paymentMethod,
      };
      if (paymentId != null) body['payment_id'] = paymentId;
      if (cashfreeOrderId != null) body['cashfree_order_id'] = cashfreeOrderId;

      final response = await _apiClient.post('/api/silver/buy.php', body);
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> sellSilver(double grams, {String? upiId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'grams': grams,
      };
      if (upiId != null) body['upi_id'] = upiId;

      final response = await _apiClient.post('/api/silver/sell.php', body);
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> depositFunds(double amount, String walletType, {String? orderId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'wallet_type': walletType,
      };
      if (orderId != null) body['order_id'] = orderId;
      final response = await _apiClient.post('/api/user/deposit.php', body);
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> withdrawFunds(double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/user/withdraw.php', {
        'amount': amount,
      });
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> updateSipSettings(bool active, double amount, String frequency, [String metalType = 'gold']) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/user/sip.php', {
        'active': active ? 1 : 0,
        'amount': amount,
        'frequency': frequency,
        'metal_type': metalType,
      });
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> createLockIn(int months, double grams, [String metalType = 'gold']) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/lockin/create.php', {
        'months': months,
        'grams': grams,
        'metal_type': metalType,
      });
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> createPaymentOrder(double amountInr) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/payment/create_order.php', {
        'amount_inr': amountInr,
      });
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }
}
