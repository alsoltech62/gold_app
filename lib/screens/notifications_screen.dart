import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/language_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      fetchNotifications(lang);
    });
  }

  Future<void> fetchNotifications([String? lang]) async {
    setState(() => isLoading = true);
    final activeLang = lang ?? Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    try {
      final data = await ApiClient().get('/api/user/notifications.php?lang=$activeLang');

      if (data['success'] == true) {
        setState(() {
          notifications = data['notifications'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => isLoading = false);
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 250,
                    color: AppColors.darkGrey,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppColors.darkGrey,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isHindi = langProvider.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? 'अधिसूचनाएं' : 'Notifications'),
        actions: [
          // Language Switch Pill Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.lighterGrey,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    langProvider.setLanguage('en');
                    fetchNotifications('en');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !isHindi ? AppColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'EN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !isHindi ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    langProvider.setLanguage('hi');
                    fetchNotifications('hi');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHindi ? AppColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'हिं',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isHindi ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => fetchNotifications(langProvider.currentLanguage),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          isHindi ? 'कोई नई अधिसूचना नहीं मिली' : 'No notifications found.',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];

                      final titleEn = notif['title_en'] ?? notif['title'] ?? '';
                      final titleHi = notif['title_hi'] ?? titleEn;
                      final msgEn = notif['message_en'] ?? notif['message'] ?? '';
                      final msgHi = notif['message_hi'] ?? msgEn;

                      final displayTitle = isHindi ? (titleHi.isNotEmpty ? titleHi : titleEn) : (titleEn.isNotEmpty ? titleEn : titleHi);
                      final displayMsg = isHindi ? (msgHi.isNotEmpty ? msgHi : msgEn) : (msgEn.isNotEmpty ? msgEn : msgHi);

                      final imageUrl = notif['image_url'] as String?;
                      final createdAt = notif['created_at'] ?? '';
                      final type = notif['type'] ?? 'general';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.lighterGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: type == 'transaction'
                                ? AppColors.gold.withOpacity(0.3)
                                : Colors.white10,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Optional Banner Image
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _showImageDialog(context, imageUrl),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            height: 160,
                                            color: Colors.black26,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.gold,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) =>
                                            const SizedBox.shrink(),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Content Section
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        type == 'transaction'
                                            ? Icons.receipt_long
                                            : Icons.notifications_active,
                                        color: AppColors.gold,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayTitle,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            displayMsg,
                                            style: TextStyle(
                                              color: Colors.grey.shade300,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                createdAt,
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              if (isHindi && titleEn.isNotEmpty && titleEn != titleHi)
                                                Text(
                                                  'EN available',
                                                  style: TextStyle(
                                                    color: AppColors.gold.withOpacity(0.7),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
