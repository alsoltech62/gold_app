import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../core/api_client.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class FirebaseService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Create the channel on the device
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');

      // Get the token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _sendTokenToBackend(token);
      }

      // Listen to token changes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });

      // Background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Got a message whilst in the foreground!');

        RemoteNotification? notification = message.notification;
        final data = message.data;

        // Check user language preference
        final prefs = await SharedPreferences.getInstance();
        final currentLang = prefs.getString('app_language') ?? 'en';

        // Select dynamic title and body based on Hindi/English setting
        String displayTitle = notification?.title ?? '';
        String displayBody = notification?.body ?? '';

        if (currentLang == 'hi') {
          if (data.containsKey('title_hi') && (data['title_hi'] ?? '').toString().isNotEmpty) {
            displayTitle = data['title_hi'];
          }
          if (data.containsKey('body_hi') && (data['body_hi'] ?? '').toString().isNotEmpty) {
            displayBody = data['body_hi'];
          }
        } else {
          if (data.containsKey('title_en') && (data['title_en'] ?? '').toString().isNotEmpty) {
            displayTitle = data['title_en'];
          }
          if (data.containsKey('body_en') && (data['body_en'] ?? '').toString().isNotEmpty) {
            displayBody = data['body_en'];
          }
        }

        // Image banner support
        String? imageUrl = data['image_url'] ??
            notification?.android?.imageUrl ??
            notification?.apple?.imageUrl;

        BigPictureStyleInformation? bigPictureStyleInformation;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final http.Response response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              bigPictureStyleInformation = BigPictureStyleInformation(
                ByteArrayAndroidBitmap(response.bodyBytes),
                largeIcon: ByteArrayAndroidBitmap(response.bodyBytes),
                contentTitle: displayTitle,
                summaryText: displayBody,
              );
            }
          } catch (e) {
            debugPrint('Error downloading notification banner: $e');
          }
        }

        flutterLocalNotificationsPlugin.show(
          id: message.hashCode,
          title: displayTitle,
          body: displayBody,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: bigPictureStyleInformation,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      });
    }
  }

  Future<void> syncLanguage(String langCode) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('auth_token');
      if (userToken == null) return;

      await ApiClient().post('/api/user/update_fcm.php', {
        'fcm_token': token,
        'preferred_language': langCode,
      });
      debugPrint('Synced language preference with FCM: $langCode');
    } catch (e) {
      debugPrint('Error syncing FCM language: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('auth_token');
      final lang = prefs.getString('app_language') ?? 'en';

      if (userToken == null) return; // User not logged in

      final data = await ApiClient().post('/api/user/update_fcm.php', {
        'fcm_token': token,
        'preferred_language': lang,
      });

      if (data['success'] == true) {
        debugPrint('FCM token & language registered with backend');
      } else {
        debugPrint('Failed to send FCM token');
      }
    } catch (e) {
      debugPrint('Error sending FCM token: $e');
    }
  }
}
