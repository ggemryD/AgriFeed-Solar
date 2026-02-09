import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/services/firebase_service.dart';
import '../model/alert_item.dart';

class AlertsService {
  final FirebaseService _firebaseService;

  AlertsService(this._firebaseService);

  Stream<List<AlertItem>> getAlerts() {
    final notificationsRef = _userNotificationsRef()
        .orderByChild('timestamp')
        .limitToLast(50);

    return notificationsRef.onValue.map((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> alerts =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        return alerts.entries.map((entry) {
          final alertData = Map<String, dynamic>.from(entry.value as Map);
          final normalized = _normalizeAlertData(alertData);

          return AlertItem(
            id: entry.key?.toString() ?? '',
            type: normalized.type,
            title: normalized.title,
            message: normalized.message,
            timestamp: normalized.timestamp,
            isRead: normalized.isRead,
            statusDetail: normalized.statusDetail,
          );
        }).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return <AlertItem>[];
    });
  }

  Future<void> markAsRead(String alertId) async {
    await _userNotificationsRef()
        .child(alertId)
        .update({'isRead': true, 'read': true});
  }

  Future<void> createAlert({
    required AlertType type,
    required String title,
    required String message,
    String? statusDetail,
  }) async {
    final alertData = {
      'type': _mapAlertTypeToString(type),
      'title': title,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
      if (statusDetail != null) 'statusDetail': statusDetail,
    };

    await _userNotificationsRef().push().set(alertData);
  }

  AlertType _mapStringToAlertType(String? type) {
    if (type == null) return AlertType.systemError;
    final normalized = type.replaceAll('-', '_').toUpperCase();
    switch (normalized) {
      case 'FEEDLOW':
      case 'FEED_LOW':
      case 'LOW_FEED':
        return AlertType.feedLow;
      case 'FEEDCOMPLETED':
      case 'FEED_COMPLETED':
      case 'COMPLETED_FEED':
        return AlertType.feedCompleted;
      case 'POWERSWITCH':
      case 'POWER_SWITCH':
      case 'ATS_SWITCH':
        return AlertType.powerSwitch;
      case 'SMSSTATUS':
      case 'SMS_STATUS':
        return AlertType.smsStatus;
      default:
        return AlertType.systemError;
    }
  }

  String _mapAlertTypeToString(AlertType type) {
    switch (type) {
      case AlertType.feedLow:
        return 'feedLow';
      case AlertType.feedCompleted:
        return 'feedCompleted';
      case AlertType.powerSwitch:
        return 'powerSwitch';
      case AlertType.smsStatus:
        return 'smsStatus';
      case AlertType.systemError:
        return 'systemError';
    }
  }

  _NormalizedAlert _normalizeAlertData(Map<String, dynamic> data) {
    final type = _mapStringToAlertType(data['type']?.toString());
    final title = (data['title'] as String?) ?? 'Alert';
    final message = (data['message'] as String?) ?? '';
    final timestamp = _parseTimestamp(data['timestamp']);
    final isRead =
        (data['isRead'] as bool?) ?? (data['read'] as bool?) ?? false;

    final statusParts = <String>[];
    final statusDetail = data['statusDetail']?.toString();
    final status = data['status']?.toString();
    final feedLevel = data['feedLevel'];

    if (statusDetail != null && statusDetail.isNotEmpty) {
      statusParts.add(statusDetail);
    }
    if (status != null && status.isNotEmpty && status != statusDetail) {
      statusParts.add(status);
    }
    if (feedLevel != null) {
      statusParts.add('Feed level: ${feedLevel.toString()}%');
    }

    return _NormalizedAlert(
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead,
      statusDetail: statusParts.isEmpty ? null : statusParts.join(' • '),
    );
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final asInt = int.tryParse(value);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
    }
    return DateTime.now();
  }

  DatabaseReference _userNotificationsRef() {
    final user = _requireUser();
    return _firebaseService.databaseRef
        .child('users')
        .child(user.uid)
        .child('notifications');
  }

  User _requireUser() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      throw StateError(
        'Attempted to access notifications without an authenticated user.',
      );
    }
    return user;
  }
}

class _NormalizedAlert {
  const _NormalizedAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.statusDetail,
  });

  final AlertType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? statusDetail;
}
