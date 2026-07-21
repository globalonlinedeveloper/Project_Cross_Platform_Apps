enum NotificationKind { renewal, priceHike, unused, budget, info }

/// Client-side notification model. In demo mode these are derived from the
/// subscription list (mirroring the design); with a backend they'd be fetched.
class AppNotification {
  const AppNotification({
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
  });

  final NotificationKind kind;
  final String title;
  final String body;
  final String time;
}
