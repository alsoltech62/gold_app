import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final data = await ApiClient().get('/api/user/notifications.php');

      if (data['success'] == true) {
        setState(() {
          notifications = data['notifications'];
          isLoading = false;
        });
      } else {
         setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : notifications.isEmpty 
          ? const Center(child: Text('No notifications found.'))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      notif['type'] == 'transaction' ? Icons.receipt : Icons.notifications,
                      // color: AppTheme.gold,
                    ),
                    title: Text(notif['title'] ?? 'Notification'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notif['message'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          notif['created_at'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
