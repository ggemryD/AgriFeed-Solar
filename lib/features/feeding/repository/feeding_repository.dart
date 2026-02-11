import 'dart:async';

import '../model/feeding_schedule_model.dart';
import '../services/feeding_service.dart';

class FeedingRepository {
  final FeedingService _feedingService;

  FeedingRepository(this._feedingService);

  Stream<List<FeedingScheduleModel>> getSchedules() {
    return _feedingService.getSchedules().map((schedules) {
      return schedules.map((schedule) {
        final parsedHour = schedule['hour'] as int?;
        final parsedMinute = schedule['minute'] as int?;
        final label = schedule['timeLabel'] as String?;
        final time = _resolveTime(parsedHour, parsedMinute, label);
        final hour = time.$1;
        final minute = time.$2;

        final timeLabel = label ?? _formatTimeLabel(hour, minute);

        return FeedingScheduleModel(
          id: schedule['id'] as String? ?? '',
          timeLabel: timeLabel,
          hour: hour,
          minute: minute,
          weightKg: (schedule['weightKg'] as num?)?.toDouble() ?? 0.0,
          isEnabled: schedule['isEnabled'] as bool? ?? false,
        );
      }).toList();
    });
  }

  Future<void> createSchedule({
    required int hour,
    required int minute,
    required double weightKg,
    bool enabled = true,
  }) async {
    final payload = {
      'hour': hour,
      'minute': minute,
      'timeLabel': _formatTimeLabel(hour, minute),
      'weightKg': weightKg,
      'isEnabled': enabled,
    };

    await _feedingService.createSchedule(payload);
  }

  Future<void> updateSchedule(FeedingScheduleModel schedule) async {
    await _feedingService.updateSchedule(schedule.id, {
      'hour': schedule.hour,
      'minute': schedule.minute,
      'timeLabel': schedule.timeLabel,
      'weightKg': schedule.weightKg,
      'isEnabled': schedule.isEnabled,
    });
  }

  Future<void> triggerManualFeed(double weightKg) async {
    await _feedingService.triggerManualFeed(weightKg);
  }

  Stream<double?> subscribeLoadCell() {
    return _feedingService.getLoadCellData();
  }

  Future<double?> getLoadCellSnapshot() async {
    final stream = subscribeLoadCell();
    double? result;
    await for (final value in stream) {
      result = value;
      break;
    }
    return result;
  }

  Future<void> toggleSchedule(String scheduleId, bool enabled) async {
    await _feedingService.updateSchedule(scheduleId, {'isEnabled': enabled});
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _feedingService.deleteSchedule(scheduleId);
  }

  // ESP32 synchronization methods
  Stream<String?> getFeedingStatus() {
    return _feedingService.getFeedingStatus();
  }

  Stream<double?> getTargetWeight() {
    return _feedingService.getTargetWeight();
  }

  (int, int) _resolveTime(int? hour, int? minute, String? label) {
    if (hour != null && minute != null) {
      return (hour, minute);
    }

    final parsed = _parseLabel(label);
    if (parsed != null) {
      return parsed;
    }

    return (0, 0);
  }

  (int, int)? _parseLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    final regex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
    final match = regex.firstMatch(label.trim());
    if (match == null) return null;

    final hour12 = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();

    if (hour12 == null || minute == null) return null;

    var hour24 = hour12 % 12;
    if (period == 'PM') {
      hour24 += 12;
    }
    if (period == 'AM' && hour12 == 12) {
      hour24 = 0;
    }

    return (hour24, minute);
  }

  String _formatTimeLabel(int hour, int minute) {
    final int hour12;
    if (hour == 0) {
      hour12 = 12;
    } else if (hour > 12) {
      hour12 = hour - 12;
    } else {
      hour12 = hour;
    }

    final period = hour >= 12 ? 'PM' : 'AM';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }
}
