import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/alert_item.dart';
import '../repository/alerts_repository.dart';

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel(this._repository) {
    _init();
  }

  final AlertsRepository _repository;

  List<AlertItem> _alerts = const [];
  bool _isLoading = true;
  Object? _error;

  StreamSubscription<List<AlertItem>>? _subscription;

  List<AlertItem> get alerts => _alerts;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  bool get hasError => _error != null;

  Future<void> _init() async {
    await _loadAlerts();
    _subscribeToUpdates();
  }

  Future<void> _loadAlerts() async {
    try {
      _setLoading(true);
      final alertStream = _repository.getAlerts();
      
      _subscription?.cancel();
      _subscription = alertStream.listen((alerts) {
        _alerts = alerts;
        _error = null;
        _setLoading(false);
        notifyListeners();
      });
    } catch (err) {
      _error = err;
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await _loadAlerts();
  }

  Future<void> markAsRead(String alertId) async {
    try {
      await _repository.markAsRead(alertId);
      _error = null;
      notifyListeners();
    } catch (err) {
      _error = err;
      notifyListeners();
    }
  }

  void _subscribeToUpdates() {
    // Already handled in _loadAlerts with stream subscription
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
