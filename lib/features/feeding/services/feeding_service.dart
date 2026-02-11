import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/services/firebase_service.dart';

class FeedingService {
  final FirebaseService _firebaseService;

  FeedingService(this._firebaseService);

  Stream<List<Map<String, dynamic>>> getSchedules() {
    final schedulesRef = _userSchedulesRef();

    return schedulesRef.onValue
        .map((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> schedules =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        return schedules.entries
            .map((entry) {
              final schedule = Map<String, dynamic>.from(entry.value as Map);
              final key = entry.key?.toString();
              if (key != null && schedule['id'] == null) {
                schedule['id'] = key;
              }
              return schedule;
            })
            .toList();
      }
      return <Map<String, dynamic>>[];
    });
  }

  Future<void> createSchedule(Map<String, dynamic> data) async {
    final schedulesRef = _userSchedulesRef();
    final newRef = schedulesRef.push();
    final key = newRef.key;

    await newRef.set({
      ...data,
      if (key != null) 'id': key,
    });
  }

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    await _userSchedulesRef().child(scheduleId).update(data);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _userSchedulesRef().child(scheduleId).remove();
  }

  Future<void> triggerManualFeed(double weightKg) async {
    final user = _requireUser();
    
    // Store feeding log for history
    final feedData = {
      'type': 'manual',
      'weightKg': weightKg,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'triggered',
    };

    await _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('feeding')
        .child('manualFeeds')
        .push()
        .set(feedData);

    // Set target weight for ESP32 and trigger feeding
    await _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('mainStorage')
        .update({
      'targetWeight': weightKg,
      'feedCommand': 'FEED', // ESP32 expects "FEED" not "OPEN"
    });
  }

  Stream<double?> getLoadCellData() {
    final user = _requireUser();
    return _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('mainStorage')
        .child('currentWeight') // ESP32 writes to currentWeight, not loadCell/weight
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value == null) return null;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value);
          return null;
        });
  }

  Future<void> updateLoadCellWeight(double weight) async {
    final user = _requireUser();
    await _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('loadCell')
        .update({
      'weight': weight,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  // Get feeding status from ESP32
  Stream<String?> getFeedingStatus() {
    final user = _requireUser();
    return _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('mainStorage')
        .child('feedingStatus')
        .onValue
        .map((event) => event.snapshot.value?.toString());
  }

  // Get target weight from ESP32
  Stream<double?> getTargetWeight() {
    final user = _requireUser();
    return _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('devices')
        .child('mainStorage')
        .child('targetWeight')
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value == null) return null;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value);
          return null;
        });
  }

  DatabaseReference _userSchedulesRef() {
    final user = _requireUser();
    return _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('feeding')
        .child('schedules');
  }

  User _requireUser() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      throw StateError('Attempted to access feeding schedules without an authenticated user.');
    }
    return user;
  }
}
