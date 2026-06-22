import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications for demonstration
    final notifications = [
      _NotificationItem(
        title: 'New Borehole Assigned',
        body: 'Borehole BH-092 in village Maveli has been assigned to your team.',
        time: '2 hours ago',
        isRead: false,
        icon: Icons.water_drop_outlined,
        color: AppColors.primary,
      ),
      _NotificationItem(
        title: 'Recce Survey Approved',
        body: 'Admin approved Recce Survey for borehole BH-084.',
        time: 'Yesterday',
        isRead: true,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _NotificationItem(
        title: 'Rehabilitation Scheduled',
        body: 'Rehabilitation stage for BH-084 is marked as ready to start.',
        time: '3 days ago',
        isRead: true,
        icon: Icons.calendar_today_outlined,
        color: AppColors.info,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon block
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                const SizedBox(width: 14),
                // Text block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.time,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final IconData icon;
  final Color color;

  const _NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.color,
  });
}
