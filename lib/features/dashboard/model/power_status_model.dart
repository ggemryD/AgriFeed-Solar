class PowerStatusModel {
  const PowerStatusModel({
    required this.batteryPercentage,
    required this.isSolarCharging,
    required this.isGridCharging,
    required this.isOnline,
    required this.motorActive,
  });

  final int batteryPercentage;
  final bool isSolarCharging;
  final bool isGridCharging;
  final bool isOnline;
  final bool motorActive;

  String get chargingSource {
    if (isSolarCharging) return 'Solar';
    if (isGridCharging) return 'Grid (ATS)';
    return 'Idle';
  }
}
