import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/notifications/data/notification_provider.dart';
import '../core/widgets/global_loader.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          final notifications = provider.notifications;

          return Column(
            children: [
              _buildHeader(context, provider.unreadCount),
              _buildFilterChips(),
              Expanded(
                child: provider.isLoading && notifications.isEmpty
                    ? const Center(child: GlobalLoader(size: 40))
                    : notifications.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => provider.fetchUnreadCount(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: notifications.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final item = notifications[index];
                                return _buildNotificationCard(context, item, provider);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unreadCount) {
    return Container(
      color: const Color(0xFF2E7D32),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Notifications',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildSimpleBadge(unreadCount, Icons.notifications_none_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBadge(int count, IconData icon) {
     return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        if (count > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildFilterPill('All', Colors.green, true),
            const SizedBox(width: 12),
            _buildFilterPill('Unread', Colors.orange, false),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, Color color, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No notifications found', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, dynamic item, NotificationProvider provider) {
    final bool isUnread = item['is_read'] == false;

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          provider.markAsRead(item['id']);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: isUnread ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
          border: Border.all(color: isUnread ? (const Color(0xFF2E7D32)).withOpacity(0.2) : Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUnread ? const Color(0xFFE8F5E9) : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_outlined, color: isUnread ? const Color(0xFF2E7D32) : Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'No Title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          color: isUnread ? Colors.black87 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['created_at'] != null ? _formatDate(item['created_at']) : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['message'] ?? '',
              style: TextStyle(color: isUnread ? Colors.black87 : Colors.grey[600], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }
}
