enum NotificationType { match, message, call, achievement, system }

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.routePath,
    this.routeArgs,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;
  final String? routePath;
  final Map<String, dynamic>? routeArgs;

  String get typeLabel => switch (type) {
        NotificationType.match       => 'Match',
        NotificationType.message     => 'Message',
        NotificationType.call        => 'Call',
        NotificationType.achievement => 'Achievement',
        NotificationType.system      => 'System',
      };
}
