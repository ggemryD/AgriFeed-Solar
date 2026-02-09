// import 'dart:async';

// import '../../../core/services/firebase_service.dart';

// class DashboardService {
//   final FirebaseService _firebaseService;

//   DashboardService(this._firebaseService);

//   Stream<Map<String, dynamic>?> getPowerStatus() {
//     return _firebaseService.databaseRef
//         .child('devices')
//         .child('powerStatus')
//         .onValue
//         .map((event) {
//           if (event.snapshot.value != null) {
//             return Map<String, dynamic>.from(event.snapshot.value as Map);
//           }
//           return null;
//         });
//   }

//   Stream<Map<String, dynamic>?> getFeedStatus() {
//     return _firebaseService.databaseRef
//         .child('devices')
//         .child('feedStatus')
//         .onValue
//         .map((event) {
//           if (event.snapshot.value != null) {
//             return Map<String, dynamic>.from(event.snapshot.value as Map);
//           }
//           return null;
//         });
//   }

//   Future<void> updatePowerStatus(Map<String, dynamic> status) async {
//     await _firebaseService.databaseRef
//         .child('devices')
//         .child('powerStatus')
//         .update(status);
//   }

//   Future<void> updateFeedStatus(Map<String, dynamic> status) async {
//     await _firebaseService.databaseRef
//         .child('devices')
//         .child('feedStatus')
//         .update(status);
//   }
// }
// -----------------------------------------------------
// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../../core/services/firebase_service.dart';

// class DashboardService {
//   final FirebaseService _firebaseService;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   DashboardService(this._firebaseService);

//   Stream<Map<String, dynamic>?> getPowerStatus() {
//     return _firebaseService.databaseRef
//         .child('devices')
//         .child('powerStatus')
//         .onValue
//         .map((event) {
//           if (event.snapshot.value != null) {
//             return Map<String, dynamic>.from(event.snapshot.value as Map);
//           }
//           return null;
//         });
//   }

//   Stream<Map<String, dynamic>?> getFeedStatus() {
//     return _firebaseService.databaseRef
//         .child('devices')
//         .child('feedStatus')
//         .onValue
//         .map((event) {
//           if (event.snapshot.value != null) {
//             return Map<String, dynamic>.from(event.snapshot.value as Map);
//           }
//           return null;
//         });
//   }

//   // NEW: Get ESP32 main storage data
//   Stream<Map<String, dynamic>?> getMainStorageStatus() {
//     final user = _auth.currentUser;
//     if (user == null) return Stream.value(null);

//     return _firebaseService.databaseRef
//         .child('users')
//         .child(user.uid)
//         .child('devices')
//         .child('mainStorage')
//         .onValue
//         .map((event) {
//           if (event.snapshot.value != null) {
//             return Map<String, dynamic>.from(event.snapshot.value as Map);
//           }
//           return null;
//         });
//   }

//   Future<void> updatePowerStatus(Map<String, dynamic> status) async {
//     await _firebaseService.databaseRef
//         .child('devices')
//         .child('powerStatus')
//         .update(status);
//   }

//   Future<void> updateFeedStatus(Map<String, dynamic> status) async {
//     await _firebaseService.databaseRef
//         .child('devices')
//         .child('feedStatus')
//         .update(status);
//   }
// }

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';

class DashboardService {
  final FirebaseService _firebaseService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DashboardService(this._firebaseService);

  // Get mainStorage data from user's path
  Stream<Map<String, dynamic>?> getMainStorageStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return Stream.value(null);
    }

    print('📡 Listening to: /users/${user.uid}/devices/mainStorage');
    
    return _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('mainStorage')
        .onValue
        .map((event) {
          print('📥 MainStorage data: ${event.snapshot.value}');
          if (event.snapshot.value != null) {
            return Map<String, dynamic>.from(event.snapshot.value as Map);
          }
          return null;
        });
  }

  // For now, return mock data or create these paths in Firebase
  Stream<Map<String, dynamic>?> getPowerStatus() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    // Check if powerStatus exists under user's devices
    return _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('powerStatus')
        .onValue
        .map((event) {
          if (event.snapshot.value != null) {
            return Map<String, dynamic>.from(event.snapshot.value as Map);
          }
          // Return default values if not exists
          return {
            'batteryPercentage': 0,
            'isSolarCharging': false,
            'isGridCharging': false,
            'isOnline': true,
            'motorActive': false,
          };
        });
  }

  Stream<Map<String, dynamic>?> getFeedStatus() {
    // This will use mainStorage data
    return getMainStorageStatus();
  }

  Future<void> updatePowerStatus(Map<String, dynamic> status) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('powerStatus')
        .update(status);
  }

  Future<void> updateFeedStatus(Map<String, dynamic> status) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('mainStorage')
        .update(status);
  }

  // TODO: TESTING METHOD - Remove this after servo testing is complete
  // This method sets the feederCommand in /mainStorage/ for servo testing
  Future<void> setFeederCommand(String command) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return;
    }
    
    try {
      print('🔧 Setting feederCommand to: $command at path: /users/${user.uid}/devices/mainStorage');
      await _firebaseService.databaseRef
          .child('users')
          .child(user.uid)
          .child('devices')
          .child('mainStorage')
          .update({'feederCommand': command});
      print('✅ Feeder command set successfully');
    } catch (e) {
      print('❌ Error setting feeder command: $e');
      rethrow;
    }
  }
  // END OF TESTING METHOD
}