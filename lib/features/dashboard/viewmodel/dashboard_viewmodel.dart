import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/feed_status_model.dart';
import '../model/power_status_model.dart';
import '../repository/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository) {
    _loadInitial();
  }

  final DashboardRepository _repository;

  FeedStatusModel? _feedStatus;
  PowerStatusModel? _powerStatus;
  bool _isLoading = true;
  Object? _error;
  String? _feederCommand;
  String? _feederStatus;

  StreamSubscription<FeedStatusModel?>? _feedSub;
  StreamSubscription<PowerStatusModel?>? _powerSub;

  FeedStatusModel? get feedStatus => _feedStatus;
  PowerStatusModel? get powerStatus => _powerStatus;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  Object? get error => _error;
  String? get feederCommand => _feederCommand;
  String? get feederStatus => _feederStatus;

  Future<void> _loadInitial() async {
    try {
      _isLoading = true;
      notifyListeners();
      final results = await Future.wait([
        _repository.getFeedStatus(),
        _repository.getPowerStatus(),
      ]);
      _feedStatus = results[0] as FeedStatusModel?;
      _powerStatus = results[1] as PowerStatusModel?;
      _error = null;
      _subscribeToUpdates();
    } catch (err) {
      _error = err;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() {
    _loadInitial();
  }

  // TODO: TESTING METHODS - Remove these after servo testing is complete
  // These methods are for testing the servo control functionality
  // They interact with the /mainStorage/ node in Firebase Realtime Database
  
  Future<void> openFeeder() async {
    try {
      // Set feederCommand to "OPEN" in /mainStorage/
      await _repository.setFeederCommand('OPEN');
      _feederCommand = 'OPEN';
      notifyListeners();
    } catch (err) {
      _error = err;
      notifyListeners();
    }
  }

  Future<void> closeFeeder() async {
    try {
      // Set feederCommand to "CLOSE" in /mainStorage/
      await _repository.setFeederCommand('CLOSE');
      _feederCommand = 'CLOSE';
      notifyListeners();
    } catch (err) {
      _error = err;
      notifyListeners();
    }
  }

  Future<void> resetFeederCommand() async {
    try {
      // Set feederCommand back to "NONE" in /mainStorage/
      await _repository.setFeederCommand('NONE');
      _feederCommand = 'NONE';
      notifyListeners();
    } catch (err) {
      _error = err;
      notifyListeners();
    }
  }
  // END OF TESTING METHODS

  void _subscribeToUpdates() {
    _feedSub?.cancel();
    _feedSub = _repository.subscribeFeedStatus().listen((event) {
      _feedStatus = event;
      notifyListeners();
    });

    _powerSub?.cancel();
    _powerSub = _repository.subscribePowerStatus().listen((event) {
      _powerStatus = event;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    _powerSub?.cancel();
    super.dispose();
  }
}
