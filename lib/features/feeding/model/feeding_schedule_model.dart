class FeedingScheduleModel {
  const FeedingScheduleModel({
    required this.id,
    required this.timeLabel,
    required this.hour,
    required this.minute,
    required this.weightKg,
    required this.isEnabled,
  });

  final String id;
  final String timeLabel;
  final int hour;
  final int minute;
  final double weightKg;
  final bool isEnabled;

  FeedingScheduleModel copyWith({
    String? id,
    String? timeLabel,
    int? hour,
    int? minute,
    double? weightKg,
    bool? isEnabled,
  }) {
    return FeedingScheduleModel(
      id: id ?? this.id,
      timeLabel: timeLabel ?? this.timeLabel,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weightKg: weightKg ?? this.weightKg,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
