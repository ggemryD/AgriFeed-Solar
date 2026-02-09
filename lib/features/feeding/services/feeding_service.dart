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
    final feedData = {
      'type': 'manual',
      'weightKg': weightKg,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'triggered',
    };

    await _firebaseService.databaseRef
        .child('feeding')
        .child('manualFeeds')
        .push()
        .set(feedData);
  }

  Stream<double?> getLoadCellData() {
    return _firebaseService.databaseRef
        .child('devices')
        .child('loadCell')
        .child('weight')
        .onValue
        .map((event) {
      if (event.snapshot.value != null) {
        return (event.snapshot.value as num).toDouble();
      }
      return null;
    });
  }

  Future<void> updateLoadCellWeight(double weight) async {
    await _firebaseService.databaseRef
        .child('devices')
        .child('loadCell')
        .update({
      'weight': weight,
      'lastUpdated': DateTime.now().toIso8601String(),
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
