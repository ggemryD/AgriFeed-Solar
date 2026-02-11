// class FeedStatusModel {
//   const FeedStatusModel({
//     required this.currentWeightKg,
//     required this.capacityKg,
//     required this.lowFeedThresholdKg,
//     required this.lastFeedingTime,
//     required this.nextFeedingTime,
//   });

//   final double currentWeightKg;
//   final double capacityKg;
//   final double lowFeedThresholdKg;
//   final DateTime? lastFeedingTime;
//   final DateTime? nextFeedingTime;

//   bool get isLow => currentWeightKg <= lowFeedThresholdKg;
//   double get fillPercentage =>
//       capacityKg == 0 ? 0 : (currentWeightKg / capacityKg).clamp(0, 1);
// }


class FeedStatusModel {
  const FeedStatusModel({
    required this.currentWeightKg,
    required this.capacityKg,
    required this.lowFeedThresholdKg,
    required this.lastFeedingTime,
    required this.nextFeedingTime,
    this.feedLevel,
    this.storageStatus,
  });

  final double currentWeightKg;
  final double capacityKg;
  final double lowFeedThresholdKg;
  final DateTime? lastFeedingTime;
  final DateTime? nextFeedingTime;
  
  // New fields from ESP32 mainStorage
  final int? feedLevel;  // 0-100% from ultrasonic sensor
  final String? storageStatus;  // "LOW" or "SUFFICIENT"

  bool get isLow => 
      (feedLevel != null && feedLevel! <= 20) || 
      (storageStatus == "LOW") ||
      currentWeightKg <= lowFeedThresholdKg;
      
  double get fillPercentage {
    // Prioritize ESP32 sensor data if available
    if (feedLevel != null) {
      return (feedLevel! / 100).clamp(0.0, 1.0);
    }
    // Fallback to weight calculation
    return capacityKg == 0 ? 0 : (currentWeightKg / capacityKg).clamp(0.0, 1.0);
  }
  
  String get feedLevelDisplay {
    if (feedLevel != null) {
      return '$feedLevel%';
    }
    return '${(fillPercentage * 100).toStringAsFixed(0)}%';
  }

  FeedStatusModel copyWith({
    double? currentWeightKg,
    double? capacityKg,
    double? lowFeedThresholdKg,
    DateTime? lastFeedingTime,
    DateTime? nextFeedingTime,
    int? feedLevel,
    String? storageStatus,
  }) {
    return FeedStatusModel(
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      capacityKg: capacityKg ?? this.capacityKg,
      lowFeedThresholdKg: lowFeedThresholdKg ?? this.lowFeedThresholdKg,
      lastFeedingTime: lastFeedingTime ?? this.lastFeedingTime,
      nextFeedingTime: nextFeedingTime ?? this.nextFeedingTime,
      feedLevel: feedLevel ?? this.feedLevel,
      storageStatus: storageStatus ?? this.storageStatus,
    );
  }
}