import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/feeding_schedule_model.dart';
import '../repository/feeding_repository.dart';

class FeedingViewModel extends ChangeNotifier {
  FeedingViewModel(this._repository) {
    _init();
  }

  final FeedingRepository _repository;

  List<FeedingScheduleModel> _schedules = const [];
  double _manualQuantity = 2.5;
  bool _isLoading = true;
  bool _isDispensing = false;
  double? _loadCellKg;
  Object? _error;

  StreamSubscription<List<FeedingScheduleModel>>? _schedulesSub;
  StreamSubscription<double?>? _loadSub;

  List<FeedingScheduleModel> get schedules => _schedules;
  double get manualQuantity => _manualQuantity;
  bool get isLoading => _isLoading;
  bool get isDispensing => _isDispensing;
  double? get loadCellKg => _loadCellKg;
  Object? get error => _error;
  bool get hasError => _error != null;

  Future<void> _init() async {
    await _fetchData();
    _subscribeToLoadCell();
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
    super.dispose();
  }
}
