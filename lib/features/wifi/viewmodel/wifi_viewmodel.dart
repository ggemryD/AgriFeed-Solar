import 'package:flutter/foundation.dart';
import '../model/wifi_config_model.dart';
import '../services/wifi_service.dart';

class WiFiViewModel extends ChangeNotifier {
  WiFiViewModel(this._wifiService);

  final WiFiService _wifiService;

  bool _isConfiguring = false;
  bool _isTestingConnection = false;
  String? _errorMessage;
  bool _isESP32Connected = false;

  bool get isConfiguring => _isConfiguring;
  bool get isTestingConnection => _isTestingConnection;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isESP32Connected => _isESP32Connected;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> configureWiFi({
    required String ssid,
    required String password,
  }) async {
    _setConfiguring(true);
    clearError();

    try {
      final config = await _wifiService.buildConfig(ssid, password);
      if (config == null) {
        _errorMessage = 'No authenticated user found';
        return false;
      }

      final success = await _wifiService.sendConfigToESP32(config);
      if (!success) {
        _errorMessage = 'Failed to send configuration to ESP32';
        return false;
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Configuration failed: ${e.toString()}';
      if (kDebugMode) {
        print('WiFi config error: $e');
      }
      return false;
    } finally {
      _setConfiguring(false);
    }
  }

  Future<bool> testESP32Connection() async {
    _setTestingConnection(true);
    clearError();

    try {
      final isConnected = await _wifiService.testESP32Connection();
      _isESP32Connected = isConnected;
      
      if (!isConnected) {
        _errorMessage = 'ESP32 not found. Make sure it\'s in AP mode.';
      }
      
      return isConnected;
    } catch (e) {
      _errorMessage = 'Connection test failed: ${e.toString()}';
      _isESP32Connected = false;
      return false;
    } finally {
      _setTestingConnection(false);
    }
  }

  void _setConfiguring(bool value) {
    if (_isConfiguring != value) {
      _isConfiguring = value;
      notifyListeners();
    }
  }

  void _setTestingConnection(bool value) {
    if (_isTestingConnection != value) {
      _isTestingConnection = value;
      notifyListeners();
    }
  }
}
