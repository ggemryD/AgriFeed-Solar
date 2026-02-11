enum AlertType { feedLow, feedCompleted, powerSwitch, systemError, smsStatus, manualFeed, scheduledFeed }

class AlertItem {
  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.statusDetail,
    this.feedWeight,
    this.feedType,
  });

  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? statusDetail;
  final double? feedWeight; // New: weight of feed dispensed
  final String? feedType; // New: type of feeding (manual/scheduled)

  AlertItem copyWith({bool? isRead}) {
    return AlertItem(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      statusDetail: statusDetail,
      feedWeight: feedWeight,
      feedType: feedType,
    );
  }
}
