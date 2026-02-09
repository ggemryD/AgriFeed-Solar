// import 'dart:developer' as developer;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import '../model/wifi_config_model.dart';

// class WiFiService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   Future<bool> sendConfigToESP32(WiFiConfigModel config) async {
//     try {
//       final url = Uri.parse('http://192.168.4.1/connect'); // ESP32 AP IP
//       final response = await http.post(
//         url,
//         body: config.toJson(),
//         headers: {
//           'Content-Type': 'application/x-www-form-urlencoded',
//         },
//       );

//       if (response.statusCode == 200) {
//         developer.log('✅ WiFi config sent successfully to ESP32');
//         return true;
//       } else {
//         developer.log('❌ Error sending WiFi config: ${response.statusCode}');
//         developer.log('Response body: ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       developer.log('❌ Exception sending WiFi config: $e');
//       return false;
//     }
//   }

//   Future<WiFiConfigModel?> buildConfig(String ssid, String password) async {
//     final user = _auth.currentUser;

//     if (user == null) {
//       developer.log('❌ No authenticated user found for WiFi config');
//       return null;
//     }

//     return WiFiConfigModel(
//       ssid: ssid,
//       password: password,
//       uid: user.uid,
//     );
//   }

//   Future<bool> testESP32Connection() async {
//     try {
//       final url = Uri.parse('http://192.168.4.1/status');
//       final response = await http.get(
//         url,
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(const Duration(seconds: 5));

//       return response.statusCode == 200;
//     } catch (e) {
//       developer.log('❌ ESP32 connection test failed: $e');
//       return false;
//     }
//   }
// }

import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/wifi_config_model.dart';

class WiFiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String esp32IP = 'http://192.168.4.1';

  Future<bool> sendConfigToESP32(WiFiConfigModel config) async {
    try {
      final url = Uri.parse('$esp32IP/connect');
      
      final body = {
        'ssid': config.ssid,
        'password': config.password,
        'uid': config.uid,
      };
      
      developer.log('📤 Sending config to ESP32...');
      developer.log('   SSID: ${config.ssid}');
      
      final response = await http.post(
        url,
        body: body,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ).timeout(const Duration(seconds: 10));

      developer.log('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          developer.log('✅ Config sent successfully!');
          return true;
        }
      }
      return false;
    } catch (e) {
      developer.log('❌ Error: $e');
      return false;
    }
  }

  Future<WiFiConfigModel?> buildConfig(String ssid, String password) async {
    final user = _auth.currentUser;

    if (user == null) {
      developer.log('❌ No user logged in');
      return null;
    }

    return WiFiConfigModel(
      ssid: ssid,
      password: password,
      uid: user.uid,
    );
  }

  Future<bool> testESP32Connection() async {
    try {
      developer.log('🔍 Testing connection to Pig-Feeder-Setup...');
      final url = Uri.parse('$esp32IP/status');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      developer.log('📥 Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      developer.log('❌ Not connected: $e');
      return false;
    }
  }
}