class WiFiConfigModel {
  final String ssid;
  final String password;
  final String uid;

  WiFiConfigModel({
    required this.ssid,
    required this.password,
    required this.uid,
  });

  Map<String, String> toJson() {
    return {
      'ssid': ssid,
      'password': password,
      'uid': uid,
    };
  }

  factory WiFiConfigModel.fromJson(Map<String, dynamic> json) {
    return WiFiConfigModel(
      ssid: json['ssid'] as String,
      password: json['password'] as String,
      uid: json['uid'] as String,
    );
  }
}
