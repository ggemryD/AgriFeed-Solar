// import 'dart:async';

// import '../model/feed_status_model.dart';
// import '../model/power_status_model.dart';
// import '../services/dashboard_service.dart';

// class DashboardRepository {
//   final DashboardService _dashboardService;

//   DashboardRepository(this._dashboardService);

//   Stream<FeedStatusModel?> subscribeFeedStatus() {
//     return _dashboardService.getFeedStatus().map((data) {
//       if (data == null) return null;
      
//       return FeedStatusModel(
//         currentWeightKg: (data['currentWeightKg'] as num?)?.toDouble() ?? 0.0,
//         capacityKg: (data['capacityKg'] as num?)?.toDouble() ?? 80.0,
//         lowFeedThresholdKg: (data['lowFeedThresholdKg'] as num?)?.toDouble() ?? 20.0,
//         lastFeedingTime: data['lastFeedingTime'] != null
//             ? DateTime.parse(data['lastFeedingTime'])
//             : null,
//         nextFeedingTime: data['nextFeedingTime'] != null
//             ? DateTime.parse(data['nextFeedingTime'])
//             : null,
//       );
//     });
//   }

//   Stream<PowerStatusModel?> subscribePowerStatus() {
//     return _dashboardService.getPowerStatus().map((data) {
//       if (data == null) return null;
      
//       return PowerStatusModel(
//         batteryPercentage: (data['batteryPercentage'] as int?) ?? 0,
//         isSolarCharging: (data['isSolarCharging'] as bool?) ?? false,
//         isGridCharging: (data['isGridCharging'] as bool?) ?? false,
//         isOnline: (data['isOnline'] as bool?) ?? false,
//         motorActive: (data['motorActive'] as bool?) ?? false,
//       );
//     });
//   }

//   Future<FeedStatusModel?> getFeedStatus() async {
//     final stream = subscribeFeedStatus();
//     FeedStatusModel? result;
//     await for (final value in stream) {
//       result = value;
//       break;
//     }
//     return result;
//   }

//   Future<PowerStatusModel?> getPowerStatus() async {
//     final stream = subscribePowerStatus();
//     PowerStatusModel? result;
//     await for (final value in stream) {
//       result = value;
//       break;
//     }
//     return result;
//   }
// }

//------------------------------------------

// import 'dart:async';

// import '../model/feed_status_model.dart';
// import '../model/power_status_model.dart';
// import '../services/dashboard_service.dart';

// class DashboardRepository {
//   final DashboardService _dashboardService;

//   DashboardRepository(this._dashboardService);

//   Stream<FeedStatusModel?> subscribeFeedStatus() {
//     // Combine both feedStatus and mainStorage streams
//     return _dashboardService.getFeedStatus().asyncMap((feedData) async {
//       // Get mainStorage data
//       Map<String, dynamic>? storageData;
//       await for (final data in _dashboardService.getMainStorageStatus()) {
//         storageData = data;
//         break; // Get first value
//       }

//       if (feedData == null && storageData == null) return null;

//       return FeedStatusModel(
//         currentWeightKg: (feedData?['currentWeightKg'] as num?)?.toDouble() ?? 0.0,
//         capacityKg: (feedData?['capacityKg'] as num?)?.toDouble() ?? 80.0,
//         lowFeedThresholdKg: (feedData?['lowFeedThresholdKg'] as num?)?.toDouble() ?? 20.0,
//         lastFeedingTime: feedData?['lastFeedingTime'] != null
//             ? DateTime.parse(feedData!['lastFeedingTime'])
//             : null,
//         nextFeedingTime: feedData?['nextFeedingTime'] != null
//             ? DateTime.parse(feedData!['nextFeedingTime'])
//             : null,
//         // ESP32 mainStorage data
//         feedLevel: storageData?['feedLevel'] as int?,
//         storageStatus: storageData?['status'] as String?,
//       );
//     });
//   }

//   Stream<PowerStatusModel?> subscribePowerStatus() {
//     return _dashboardService.getPowerStatus().map((data) {
//       if (data == null) return null;
      
//       return PowerStatusModel(
//         batteryPercentage: (data['batteryPercentage'] as int?) ?? 0,
//         isSolarCharging: (data['isSolarCharging'] as bool?) ?? false,
//         isGridCharging: (data['isGridCharging'] as bool?) ?? false,
//         isOnline: (data['isOnline'] as bool?) ?? false,
//         motorActive: (data['motorActive'] as bool?) ?? false,
//       );
//     });
//   }

//   Future<FeedStatusModel?> getFeedStatus() async {
//     final stream = subscribeFeedStatus();
//     FeedStatusModel? result;
//     await for (final value in stream) {
//       result = value;
//       break;
//     }
//     return result;
//   }

//   Future<PowerStatusModel?> getPowerStatus() async {
//     final stream = subscribePowerStatus();
//     PowerStatusModel? result;
//     await for (final value in stream) {
//       result = value;
//       break;
//     }
//     return result;
//   }
// }

import 'dart:async';

import '../model/feed_status_model.dart';
import '../model/power_status_model.dart';
import '../services/dashboard_service.dart';

class DashboardRepository {
  final DashboardService _dashboardService;

  DashboardRepository(this._dashboardService);

  Stream<FeedStatusModel?> subscribeFeedStatus() {
    return _dashboardService.getMainStorageStatus().map((storageData) {
      print('📊 Storage Data: $storageData');
      
      if (storageData == null) {
        print('⚠️ No mainStorage data');
        return null;
      }

      // Use mainStorage data directly
      return FeedStatusModel(
        currentWeightKg: 0.0,  // Not used when feedLevel is available
        capacityKg: 100.0,
        lowFeedThresholdKg: 20.0,
        lastFeedingTime: null,  // Add these fields to Firebase if needed
        nextFeedingTime: null,
        feedLevel: storageData['feedLevel'] as int?,
        storageStatus: storageData['status'] as String?,
      );
    });
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
  // END OF TESTING METHOD
}