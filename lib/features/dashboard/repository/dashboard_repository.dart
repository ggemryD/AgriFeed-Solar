import 'dart:async';

import '../model/feed_status_model.dart';
import '../model/power_status_model.dart';
import '../services/dashboard_service.dart';

import '../../feeding/repository/feeding_repository.dart';
import '../../feeding/model/feeding_schedule_model.dart';
import '../../alerts/repository/alerts_repository.dart';
import '../../alerts/model/alert_item.dart';

class DashboardRepository {
  final DashboardService _dashboardService;
  final FeedingRepository feedingRepository;
  final AlertsRepository alertsRepository;

  DashboardRepository(
    this._dashboardService, {
    required this.feedingRepository,
    required this.alertsRepository,
  });

  Stream<FeedStatusModel?> subscribeFeedStatus() {
    return _dashboardService.getMainStorageStatus().asyncMap((storageData) async {
      print('📊 Storage Data: $storageData');
      
      if (storageData == null) {
        print('⚠️ No mainStorage data');
        return null;
      }

      // 1. Try to get times from Firebase storageData first
      DateTime? lastFeeding = storageData['lastFeedingTime'] != null
          ? DateTime.tryParse(storageData['lastFeedingTime'].toString())
          : null;
          
      DateTime? nextFeeding = storageData['nextFeedingTime'] != null
          ? DateTime.tryParse(storageData['nextFeedingTime'].toString())
          : null;

      // 2. Fallback: Fetch from AlertsRepository (History) if missing
      if (lastFeeding == null) {
        try {
          final alertsStream = alertsRepository.getAlerts();
          await for (final alerts in alertsStream) {
            final feedingLogs = alerts.where((a) => 
              a.type == AlertType.manualFeed || 
              a.type == AlertType.scheduledFeed
            ).toList();
            
            if (feedingLogs.isNotEmpty) {
              feedingLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              lastFeeding = feedingLogs.first.timestamp;
            }
            break; // Get one snapshot
          }
        } catch (e) {
          print('Error fetching last feeding from alerts: $e');
        }
      }

      // 3. Fallback: Calculate from FeedingRepository (Schedules) if missing
      if (nextFeeding == null) {
        try {
          final schedulesStream = feedingRepository.getSchedules();
          await for (final schedules in schedulesStream) {
            nextFeeding = _calculateNextFeeding(schedules);
            break; // Get one snapshot
          }
        } catch (e) {
          print('Error calculating next feeding: $e');
        }
      }

      // Use mainStorage data directly
      return FeedStatusModel(
        currentWeightKg: 0.0,  // Not used when feedLevel is available
        capacityKg: 100.0,
        lowFeedThresholdKg: 20.0,
        lastFeedingTime: lastFeeding,
        nextFeedingTime: nextFeeding,
        feedLevel: storageData['feedLevel'] as int?,
        storageStatus: storageData['status'] as String?,
      );
    });
  }

  DateTime? _calculateNextFeeding(List<FeedingScheduleModel> schedules) {
    if (schedules.isEmpty) return null;
    final now = DateTime.now();
    
    // Sort schedules by time
    final sorted = List<FeedingScheduleModel>.from(schedules)
      ..sort((a, b) {
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        return a.minute.compareTo(b.minute);
      });
      
    // Find next schedule today
    for (final schedule in sorted) {
      if (!schedule.isEnabled) continue;
      final scheduleTime = DateTime(now.year, now.month, now.day, schedule.hour, schedule.minute);
      if (scheduleTime.isAfter(now)) {
        return scheduleTime;
      }
    }
    
    // Find first schedule tomorrow
    for (final schedule in sorted) {
       if (!schedule.isEnabled) continue;
       return DateTime(now.year, now.month, now.day + 1, schedule.hour, schedule.minute);
    }
    
    return null;
  }

  Stream<PowerStatusModel?> subscribePowerStatus() {
    return _dashboardService.getPowerStatus().map((data) {
      print('⚡ Power Data: $data');
      
      if (data == null) {
        print('⚠️ No power data');
        return null;
      }
      
      return PowerStatusModel(
        batteryPercentage: (data['batteryPercentage'] as int?) ?? 0,
        isSolarCharging: (data['isSolarCharging'] as bool?) ?? false,
        isGridCharging: (data['isGridCharging'] as bool?) ?? false,
        isOnline: (data['isOnline'] as bool?) ?? true,
        motorActive: (data['motorActive'] as bool?) ?? false,
      );
    });
  }

  Future<FeedStatusModel?> getFeedStatus() async {
    try {
      print('🔍 Getting feed status...');
      final stream = subscribeFeedStatus();
      FeedStatusModel? result;
      await for (final value in stream) {
        result = value;
        break;
      }
      print('✅ Feed status: ${result?.feedLevel}%');
      return result;
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  Future<PowerStatusModel?> getPowerStatus() async {
    try {
      print('🔍 Getting power status...');
      final stream = subscribePowerStatus();
      PowerStatusModel? result;
      await for (final value in stream) {
        result = value;
        break;
      }
      print('✅ Power status loaded');
      return result;
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  // TODO: TESTING METHOD - Remove this after servo testing is complete
  // This method sets the feederCommand in /mainStorage/ for servo testing
  Future<void> setFeederCommand(String command) async {
    try {
      print('🔧 Setting feeder command to: $command');
      await _dashboardService.setFeederCommand(command);
      print('✅ Feeder command set successfully');
    } catch (e) {
      print('❌ Error setting feeder command: $e');
      rethrow;
    }
  }
}
