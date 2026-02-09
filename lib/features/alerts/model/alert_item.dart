enum AlertType { feedLow, feedCompleted, powerSwitch, systemError, smsStatus }

class AlertItem {
  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.statusDetail,
  });

  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? statusDetail;

  AlertItem copyWith({bool? isRead}) {
    return AlertItem(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      statusDetail: statusDetail,
    );
  }
}
