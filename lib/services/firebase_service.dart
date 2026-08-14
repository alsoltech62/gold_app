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
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
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
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
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
        AndroidNotification? android = message.notification?.android;
        String? imageUrl = notification?.android?.imageUrl ?? notification?.apple?.imageUrl;

        if (notification != null && android != null) {
          BigPictureStyleInformation? bigPictureStyleInformation;
          
          if (imageUrl != null) {
            try {
              final http.Response response = await http.get(Uri.parse(imageUrl));
              if (response.statusCode == 200) {
                bigPictureStyleInformation = BigPictureStyleInformation(
                  ByteArrayAndroidBitmap(response.bodyBytes),
                  largeIcon: ByteArrayAndroidBitmap(response.bodyBytes),
                  contentTitle: notification.title,
                  summaryText: notification.body,
                );
              }
            } catch (e) {
              debugPrint('Error downloading notification image: $e');
            }
          }

          flutterLocalNotificationsPlugin.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
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
        }
      });
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // api_client uses 'auth_token' instead of 'token'
      final userToken = prefs.getString('auth_token'); 

      if (userToken == null) return; // User not logged in

      final data = await ApiClient().post('/api/user/update_fcm.php', {'fcm_token': token});

      if (data['success'] == true) {
        debugPrint('FCM token sent to backend');
      } else {
        debugPrint('Failed to send FCM token');
      }
    } catch (e) {
      debugPrint('Error sending FCM token: $e');
    }
  }
}
