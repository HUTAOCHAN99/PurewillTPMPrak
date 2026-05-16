import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/data/services/community/notification_service.dart';
import 'package:purewill/domain/model/community_model.dart';

// Provider untuk notification service
final notificationServiceProvider = Provider((ref) => NotificationService());

// Provider untuk notifikasi real-time
final notificationsProvider = StreamProvider.autoDispose
    .family<List<CommunityNotification>, String>((ref, userId) {
  final notificationService = ref.read(notificationServiceProvider);
  return notificationService.streamNotifications(userId);
});

// Provider untuk jumlah notifikasi yang belum dibaca
final unreadNotificationsCountProvider = StreamProvider.autoDispose
    .family<int, String>((ref, userId) async* {
  final notificationService = ref.read(notificationServiceProvider);
  
  // Stream perubahan jumlah
  yield* notificationService.streamNotifications(userId).asyncMap(
    (notifications) => notifications.length,
  );
});

class NotificationBell extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onNotificationTap;
  
  const NotificationBell({
    super.key,
    required this.userId,
    this.onNotificationTap,
  });

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  bool _isDropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider(widget.userId));
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider(widget.userId));

    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: () {
            setState(() => _isDropdownOpen = !_isDropdownOpen);
            if (_isDropdownOpen) {
              _showNotificationsDropdown();
            }
          },
        ),
        
        // Badge untuk jumlah notifikasi yang belum dibaca
        Positioned(
          right: 8,
          top: 8,
          child: unreadCountAsync.when(
            data: (count) {
              if (count > 0) {
                return Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void _showNotificationsDropdown() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 250 + size.width,
        top: position.dy + size.height + 8,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _buildNotificationsList(),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Tutup dropdown saat klik di luar
    Future.delayed(const Duration(milliseconds: 100), () {
      GestureDetector(
        onTap: () {
          overlayEntry.remove();
          setState(() => _isDropdownOpen = false);
        },
        behavior: HitTestBehavior.translucent,
        child: Container(color: Colors.transparent),
      );
    });
  }

  Widget _buildNotificationsList() {
    final notificationsAsync = ref.watch(notificationsProvider(widget.userId));

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 50, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Tidak ada notifikasi',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final notificationService = 
                          ref.read(notificationServiceProvider);
                      notificationService.markAllAsRead(widget.userId);
                    },
                    child: const Text(
                      'Tandai semua dibaca',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // List notifikasi
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(notification);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildNotificationItem(CommunityNotification notification) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: notification.iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(notification.icon, color: notification.iconColor),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        notification.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: !notification.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
            )
          : null,
      onTap: () async {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.markAsRead(notification.id);
        
        // Navigasi ke post yang terkait
        if (notification.postId != null) {
          widget.onNotificationTap?.call();
          // TODO: Navigasi ke post detail
        }
      },
    );
  }
}