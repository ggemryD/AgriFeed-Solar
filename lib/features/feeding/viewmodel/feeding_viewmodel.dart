import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/feeding_schedule_model.dart';
import '../repository/feeding_repository.dart';
import '../../alerts/viewmodel/alerts_viewmodel.dart'; // Import alerts viewmodel
import '../../alerts/model/alert_item.dart'; // Import AlertType

class FeedingViewModel extends ChangeNotifier {
  FeedingViewModel(this._repository, [this._alertsViewModel]) {
    _init();
  }

  final FeedingRepository _repository;
  final AlertsViewModel? _alertsViewModel; // Optional alerts viewmodel

  List<FeedingScheduleModel> _schedules = [];
  double _manualQuantity = 2.0;
  bool _isLoading = false;
  bool _isDispensing = false;
  double? _loadCellKg;
  Object? _error;
  
  // ESP32 synchronization state
  String? _feedingStatus;
  double? _targetWeight;
  StreamSubscription<String?>? _feedingStatusSub;
  StreamSubscription<double?>? _targetWeightSub;

  List<FeedingScheduleModel> get schedules => _schedules;
  double get manualQuantity => _manualQuantity;
  bool get isLoading => _isLoading;
  bool get isDispensing => _isDispensing;
  double? get loadCellKg => _loadCellKg;
  Object? get error => _error;
  bool get hasError => _error != null;
  
  // ESP32 sync getters
  String? get feedingStatus => _feedingStatus;
  double? get targetWeight => _targetWeight;
  bool get isFeedingActive => _feedingStatus != null && 
      _feedingStatus != 'IDLE' && 
      _feedingStatus != 'COMPLETE';

  StreamSubscription<List<FeedingScheduleModel>>? _schedulesSub;
  StreamSubscription<double?>? _loadSub;

  Future<void> _init() async {
    await _fetchData();
    _subscribeToLoadCell();
    _subscribeToFeedingStatus();
    _subscribeToTargetWeight();
  }

  Future<void> _fetchData() async {
    try {
      _setLoading(true);
      final schedulesStream = _repository.getSchedules();
      final loadCell = await _repository.getLoadCellSnapshot();
      
      _schedulesSub?.cancel();
      _schedulesSub = schedulesStream.listen((schedules) {
        _schedules = schedules;
        notifyListeners();
      });
      
      _loadCellKg = loadCell;
      _error = null;
    } catch (err) {
      _error = err;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await _fetchData();
  }

  void setManualQuantity(double value) {
    if (value == _manualQuantity) return;
    _manualQuantity = value;
    notifyListeners();
  }

  Future<bool> dispenseNow() async {
    if (_isDispensing) return false;
    _isDispensing = true;
    notifyListeners();
    try {
      await _repository.triggerManualFeed(_manualQuantity);
      _error = null;
      
      // Create feeding log in alerts
      if (_alertsViewModel != null) {
        await _alertsViewModel!.createFeedingLog(
          type: AlertType.manualFeed,
          weightKg: _manualQuantity,
          feedType: 'Manual',
        );
      }
      
      notifyListeners();
      return true;
    } catch (err) {
      _error = err;
      notifyListeners();
      if (kDebugMode) {
        print('Manual feed error: $err');
      }
      return false;
    } finally {
      _isDispensing = false;
      notifyListeners();
    }
  }

  Future<void> toggleSchedule(String scheduleId, bool enabled) async {
    try {
      await _repository.toggleSchedule(scheduleId, enabled);
      _error = null;
    } catch (err) {
      _error = err;
      notifyListeners();
    }
  }

  Future<void> updateSchedule(FeedingScheduleModel schedule) async {
    try {
      await _repository.updateSchedule(schedule);
      _error = null;
    } catch (err) {
      _error = err;
      notifyListeners();
    }
  }

  Future<bool> createSchedule({
    required int hour,
    required int minute,
    required double weightKg,
    bool enabled = true,
  }) async {
    try {
      await _repository.createSchedule(
        hour: hour,
        minute: minute,
        weightKg: weightKg,
        enabled: enabled,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (err) {
      _error = err;
      notifyListeners();
      if (kDebugMode) {
        print('Create schedule error: $err');
      }
      return false;
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _repository.deleteSchedule(scheduleId);
      _error = null;
      notifyListeners();
      return true;
    } catch (err) {
      _error = err;
      notifyListeners();
      if (kDebugMode) {
        print('Delete schedule error: $err');
      }
      return false;
    }
  }

  void _subscribeToLoadCell() {
    _loadSub?.cancel();
    _loadSub = _repository.subscribeLoadCell().listen((value) {
      _loadCellKg = value;
      notifyListeners();
    });
  }

  void _subscribeToFeedingStatus() {
    _feedingStatusSub?.cancel();
    _feedingStatusSub = _repository.getFeedingStatus().listen((status) {
      _feedingStatus = status;
      notifyListeners();
    });
  }

  void _subscribeToTargetWeight() {
    _targetWeightSub?.cancel();
    _targetWeightSub = _repository.getTargetWeight().listen((weight) {
      _targetWeight = weight;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _schedulesSub?.cancel();
    _loadSub?.cancel();
    _feedingStatusSub?.cancel();
    _targetWeightSub?.cancel();
    super.dispose();
  }
}
