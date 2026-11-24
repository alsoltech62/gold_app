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
  List<dynamic> _pendingGifts = [];
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
  List<dynamic> get pendingGifts => _pendingGifts;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/user/dashboard.php');
      if (response['success'] == true) {
        _dashboardData = response['data'];
        if (_dashboardData?['pending_gifts'] != null) {
          _pendingGifts = List<dynamic>.from(_dashboardData!['pending_gifts']);
        } else {
          _pendingGifts = [];
        }
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

  Future<Map<String, dynamic>> updateSipSettings(bool active, double amount, String frequency, [String metalType = 'gold', Map<String, dynamic>? extra]) async {
    _isLoading = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'active': active ? 1 : 0,
        'amount': amount,
        'frequency': frequency,
        'metal_type': metalType,
      };
      if (extra != null) {
        body.addAll(extra);
      }
      final response = await _apiClient.post('/api/sip/setup.php', body);
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
        await fetchSipHistory(metalType: metalType);
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error'};
    }
  }

  Future<Map<String, dynamic>> cancelSip(int sipId, [String? metalType]) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/user/cancel_sip.php', {
        'sip_id': sipId,
      });
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
        await fetchSipHistory(metalType: metalType);
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

  Future<Map<String, dynamic>> createPaymentOrder(double amountInr, {String metalType = 'gold'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/payment/create_order.php', {
        'amount_inr': amountInr,
        'metal_type': metalType,
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

  Future<Map<String, dynamic>> createGoldGift({
    required double amountInr,
    required String recipientMobile,
    String? recipientName,
    String? message,
    required String paymentMethod,
    String? utr,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'action': 'create',
        'amount_inr': amountInr,
        'recipient_mobile': recipientMobile,
        'recipient_name': recipientName ?? '',
        'message': message ?? 'Wishing you pure 24K Gold! 🎁',
        'payment_method': paymentMethod,
      };
      if (utr != null && utr.isNotEmpty) body['utr'] = utr;

      final response = await _apiClient.post('/api/gold/gift.php', body);
      _isLoading = false;
      if (response['success'] == true) {
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyGiftPayment(String orderId, {String? giftCode}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/gold/gift.php', {
        'action': 'verify_payment',
        'order_id': orderId,
        if (giftCode != null) 'gift_code': giftCode,
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
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  Future<List<dynamic>> fetchPendingGifts() async {
    try {
      final response = await _apiClient.get('/api/gold/gift.php?action=pending_gifts');
      if (response['success'] == true && response['data'] != null) {
        _pendingGifts = List<dynamic>.from(response['data']);
        notifyListeners();
        return _pendingGifts;
      }
    } catch (e) {
      debugPrint('Error fetching pending gifts: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> claimGoldGift(dynamic giftId, {String? giftCode}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/api/gold/gift.php', {
        'action': 'claim',
        'gift_id': giftId,
        if (giftCode != null) 'gift_code': giftCode,
      });
      _isLoading = false;
      if (response['success'] == true) {
        _pendingGifts.removeWhere((g) => g['id'] == giftId || (giftCode != null && g['gift_code'] == giftCode));
        await fetchDashboard();
      }
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchMyGifts() async {
    try {
      final response = await _apiClient.get('/api/gold/gift.php?action=my_gifts');
      if (response['success'] == true) {
        return response['data'] ?? {};
      }
    } catch (e) {
      debugPrint('Error fetching my gifts: $e');
    }
    return {};
  }
}
