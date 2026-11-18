import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../services/firebase_service.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  bool get isHindi => _currentLanguage == 'hi';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('app_language') ?? 'en';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode != 'en' && langCode != 'hi') return;
    if (_currentLanguage == langCode) return;

    _currentLanguage = langCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', langCode);

      // Sync with backend database
      await ApiClient().post('/api/user/update_language.php', {
        'language': langCode,
      });

      // Update FCM token language registration
      await FirebaseService().syncLanguage(langCode);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  // Dynamic localization helper
  String getText(String enText, String hiText) {
    if (isHindi && hiText.trim().isNotEmpty) {
      return hiText;
    }
    return enText;
  }
}
