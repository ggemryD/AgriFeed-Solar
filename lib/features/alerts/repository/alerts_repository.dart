import 'dart:async';
import '../model/alert_item.dart';
import '../services/alerts_service.dart';

class AlertsRepository {
  final AlertsService _alertsService;

  AlertsRepository(this._alertsService);

  Stream<List<AlertItem>> getAlerts() {
    return _alertsService.getAlerts();
  }

  Future<List<AlertItem>> markAsRead(String alertId) async {
    await _alertsService.markAsRead(alertId);
    final stream = getAlerts();
    List<AlertItem> result = [];
    await for (final value in stream) {
      result = value;
      break;
    }
    return result;
  }

  Stream<AlertItem> subscribeAlerts() {
    return getAlerts().map((alerts) => alerts.isNotEmpty ? alerts.first : 
      AlertItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AlertType.systemError,
        title: 'System Connected',
        message: 'Successfully connected to Firebase Realtime Database',
        timestamp: DateTime.now(),
        isRead: false,
      )
    );
  }
}
