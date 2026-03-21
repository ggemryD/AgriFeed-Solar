#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>
#include <HX711.h>
#include <RTClib.h>
#include <time.h>
#include <HardwareSerial.h>   //  SIM800L

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ---- WIFI AP MODE SETTINGS ----
#define AP_SSID "Pig-Feeder-Setup"

// ---- ULTRASONIC SENSOR ----
#define TRIG_PIN 5
#define ECHO_PIN 18

// ---- SERVO MOTORS ----
#define SERVO1_PIN 12
#define SERVO2_PIN 13
#define SERVO_BACKUP_PIN 14
Servo storageServo;
Servo dispenserServo;
Servo backupServo;

// ---- LOAD CELL (HX711) ----
#define LOADCELL_DOUT_PIN 32
#define LOADCELL_SCK_PIN 33
HX711 scale;
float calibration_factor = 104.8;
float targetWeight = 0;
bool isFeeding = false;

// ---- FEED STORAGE SETTINGS ----
const int LOW_FEED_THRESHOLD = 20;
const int BIN_HEIGHT = 30; // 30 = 12 inches, 25 = 10 inches
const int SENSOR_TO_FULL = 8;

// ---- SERVO POSITIONS ----
const int SERVO1_CLOSED = 0;
const int SERVO1_WIGGLE_POS1 = 30;
const int SERVO1_WIGGLE_POS2 = 60; 
const int SERVO2_CLOSED = 100;
const int SERVO2_OPEN = 10;
const int BACKUP_SERVO_CLOSED = 125;
const int BACKUP_SERVO_OPEN = 90;

// ---- BACKUP STORAGE SETTINGS ----
const int BACKUP_FILL_LEVEL = 80;
const int BACKUP_CHECK_INTERVAL = 3000;
bool backupIsOpen = false;
unsigned long lastBackupCheck = 0;

// ---- SIM800L ----
HardwareSerial sim800l(1);                    // UART1
#define SIM_RX_PIN 16                         // ESP32 GPIO16 → SIM800L TXD
#define SIM_TX_PIN 17                         // ESP32 GPIO17 → SIM800L RXD
#define ALERT_PHONE_NUMBER "+639703851090"   

bool simReady = false;
bool lowFeedAlertSent = false;               // Prevent repeated low feed alerts
unsigned long lastSimCheck = 0;

// ---- FIREBASE ----
#define DATABASE_URL "https://solar-smart-pig-feeder-default-rtdb.firebaseio.com"
#define DATABASE_SECRET "PMHybOYSJCdYVpEOE2UoL4emgJawTg3r5LjebD6U"

// ---- RTC MODULE ----
RTC_DS3231 rtc;
bool rtcAvailable = false;

// ---- NTP TIME SETTINGS ----
const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 28800;
const int daylightOffset_sec = 0;

// ---- OBJECTS ----
FirebaseData fbData;
FirebaseAuth auth;
FirebaseConfig config;
WebServer server(80);
Preferences preferences;

// ---- WIFI GLOBAL VARIABLES ----
String wifiSSID = "";
String wifiPassword = "";
String userUID = "";
bool wifiConnected = false;

// ---- NTP STATUS ----
bool ntpSynced = false;

// ---- SCHEDULE TRACKING ----
DateTime lastScheduleCheck;

// ---- GLOBAL VARIABLE FOR NTP TIME ----
struct tm ntpTimeInfo;
bool ntpTimeValid = false;

// ============================================================
// ✅ SIM800L FUNCTIONS
// ============================================================

void simSendAT(String cmd, int waitMs = 500) {
  sim800l.println(cmd);
  delay(waitMs);
  while (sim800l.available()) {
    Serial.write(sim800l.read());
  }
}

bool initSIM800L() {
  Serial.println("📱 Initializing SIM800L...");
  sim800l.begin(9600, SERIAL_8N1, SIM_RX_PIN, SIM_TX_PIN);
  delay(3000); // Wait for module boot

  // Test AT response
  for (int i = 0; i < 5; i++) {
    sim800l.println("AT");
    delay(1000);
    String response = "";
    while (sim800l.available()) {
      response += (char)sim800l.read();
    }
    if (response.indexOf("OK") >= 0) {
      Serial.println("✅ SIM800L responded!");
      simSendAT("AT+CMGF=1"); // Set SMS text mode
      simReady = true;
      return true;
    }
    Serial.println("   Attempt " + String(i + 1) + "/5...");
  }
  Serial.println("❌ SIM800L not responding!");
  simReady = false;
  return false;
}

void sendSMS(String message) {
  if (!simReady) {
    Serial.println("⚠️ SIM800L not ready, skipping SMS");
    return;
  }

  Serial.println("📤 Sending SMS: " + message);

  sim800l.println("AT+CMGF=1");
  delay(500);

  sim800l.print("AT+CMGS=\"");
  sim800l.print(ALERT_PHONE_NUMBER);
  sim800l.println("\"");
  delay(1000);

  sim800l.print(message);
  delay(500);
  sim800l.write(26); // Ctrl+Z
  delay(5000);

  String response = "";
  while (sim800l.available()) {
    char c = sim800l.read();
    response += c;
    Serial.write(c);
  }

  if (response.indexOf("+CMGS") >= 0) {
    Serial.println("✅ SMS sent successfully!");
  } else {
    Serial.println("❌ SMS send failed");
  }
}

// ============================================================

// ---- FUNCTION TO GET CURRENT TIME ----
DateTime getCurrentTime() {
  if (rtcAvailable) {
    return rtc.now();
  } else if (ntpTimeValid) {
    struct tm timeinfo;
    if (getLocalTime(&timeinfo)) {
      return DateTime(
        timeinfo.tm_year + 1900,
        timeinfo.tm_mon + 1,
        timeinfo.tm_mday,
        timeinfo.tm_hour,
        timeinfo.tm_min,
        timeinfo.tm_sec
      );
    }
  }
  return DateTime(2026, 1, 1, 0, 0, 0) + TimeSpan(millis() / 1000);
}

// ---- FUNCTION TO SYNC TIME WITH NTP ----
void syncTimeWithNTP() {
  if (!wifiConnected) return;
  Serial.println("⏰ Syncing time with NTP server...");
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  struct tm timeinfo;
  if (getLocalTime(&timeinfo)) {
    Serial.println("✅ NTP time retrieved!");
    ntpTimeInfo = timeinfo;
    ntpTimeValid = true;
    Serial.printf("   Current time: %04d-%02d-%02d %02d:%02d:%02d\n",
                  timeinfo.tm_year + 1900, timeinfo.tm_mon + 1, timeinfo.tm_mday,
                  timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
    if (rtcAvailable) {
      DateTime ntpTime(timeinfo.tm_year + 1900, timeinfo.tm_mon + 1, timeinfo.tm_mday,
                       timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
      rtc.adjust(ntpTime);
      Serial.println("✅ RTC synced with NTP");
    }
    ntpSynced = true;
  } else {
    Serial.println("❌ Failed to get NTP time");
    ntpTimeValid = false;
  }
}

// ---- FUNCTION TO READ ULTRASONIC ----
long readUltrasonicCM() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  long distance = duration * 0.034 / 2;
  return distance;
}

// ---- FUNCTION TO CALCULATE FEED LEVEL ----
int calculateFeedLevel(long distance) {
  int feedLevel = ((BIN_HEIGHT - distance) * 100) / (BIN_HEIGHT - SENSOR_TO_FULL);
  if (feedLevel > 100) feedLevel = 100;
  if (feedLevel < 0) feedLevel = 0;
  return feedLevel;
}

// ---- FUNCTION TO READ WEIGHT FROM LOAD CELL ----
float readWeight() {
  if (scale.is_ready()) {
    float weight = scale.get_units(10);
    return weight / 1000.0;
  }
  return 0;
}

// ---- WIGGLE SERVO 1 TO DISPENSE FEED ----
void wiggleStorageServo() {
  storageServo.write(SERVO1_WIGGLE_POS1);
  delay(200);
  storageServo.write(SERVO1_WIGGLE_POS2);
  delay(200);
}

// ============================================================
// ✅ BACKUP STORAGE MANAGEMENT (removed confirm counter to prevent reboots)
// ============================================================

void openBackupStorage() {
  if (backupIsOpen) return;

  Serial.println("\n========================================");
  Serial.println("🔓 OPENING BACKUP STORAGE");
  Serial.println("   Main storage is LOW");
  Serial.println("========================================");

  backupServo.write(BACKUP_SERVO_OPEN);
  backupIsOpen = true;

  if (wifiConnected && Firebase.ready() && userUID.length() > 0) {
    String basePath = "/users/" + userUID + "/devices/mainStorage";
    Firebase.RTDB.setString(&fbData, basePath + "/backupStatus", "OPEN");
    Firebase.RTDB.setString(&fbData, basePath + "/status", "LOW - REFILLING");
  }

  Serial.println("✅ Backup servo OPENED");
}

void closeBackupStorage() {
  if (!backupIsOpen) return;

  Serial.println("\n========================================");
  Serial.println("🔒 CLOSING BACKUP STORAGE");
  Serial.println("   Main storage sufficiently refilled");
  Serial.println("========================================");

  backupServo.write(BACKUP_SERVO_CLOSED);
  backupIsOpen = false;

  // ✅ Reset low feed alert so it can alert again next time
  lowFeedAlertSent = false;

  if (wifiConnected && Firebase.ready() && userUID.length() > 0) {
    String basePath = "/users/" + userUID + "/devices/mainStorage";
    Firebase.RTDB.setString(&fbData, basePath + "/backupStatus", "CLOSED");
  }

  Serial.println("✅ Backup servo CLOSED");
}

// ✅ Simplified: no confirm counter, just direct threshold check
void checkBackupStorage(int currentFeedLevel) {
  if (isFeeding) return;
  if (millis() - lastBackupCheck < BACKUP_CHECK_INTERVAL) return;
  lastBackupCheck = millis();

  if (!backupIsOpen) {
    if (currentFeedLevel <= LOW_FEED_THRESHOLD) {
      Serial.println("⚠️ Feed LOW (" + String(currentFeedLevel) + "%) - Opening backup");

      // ✅ Send SMS alert only once per low event
      if (!lowFeedAlertSent) {
        sendSMS("ALERT: Pig feeder feed storage is LOW (" + String(currentFeedLevel) + "%). Backup storage opening now.");
        lowFeedAlertSent = true;
      }

      openBackupStorage();
    }
  } else {
    Serial.println("🔄 Backup open — Main level: " + String(currentFeedLevel) +
                   "% (target: " + String(BACKUP_FILL_LEVEL) + "%)");
    if (currentFeedLevel >= BACKUP_FILL_LEVEL) {
      closeBackupStorage();
    }
  }
}

// ============================================================

// ---- FEEDING PROCESS ----
void performFeeding(String basePath, float targetKg, String feedType) {
  Serial.println("\n========================================");
  Serial.println("🍽️ STARTING FEEDING PROCESS");
  Serial.println("   Target Weight: " + String(targetKg) + " kg");
  Serial.println("   Type: " + feedType);
  Serial.println("========================================");

  isFeeding = true;
  Firebase.RTDB.setString(&fbData, basePath + "/feedingStatus", "DISPENSING");

  dispenserServo.write(SERVO2_CLOSED);
  Serial.println("🔒 Dispenser gate CLOSED");
  delay(1000);

  scale.tare();
  Serial.println("⚖️ Scale tared");
  delay(500);

  Serial.println("🔄 Wiggling Servo 1...");
  float currentWeight = 0;
  int wiggleCount = 0;

  while (currentWeight < targetKg && isFeeding) {
    wiggleStorageServo();
    wiggleCount++;
    currentWeight = readWeight();
    Firebase.RTDB.setFloat(&fbData, basePath + "/currentWeight", currentWeight);
    Serial.print("   Wiggle #" + String(wiggleCount));
    Serial.println(" | Weight: " + String(currentWeight, 2) + " kg / " + String(targetKg) + " kg");
    delay(300);
    if (wiggleCount > 300) {
      Serial.println("⚠️ Max wiggles reached, stopping...");
      break;
    }
  }

  storageServo.write(SERVO1_CLOSED);
  Serial.println("✅ Target weight reached! Servo 1 CLOSED");
  delay(1000);

  Serial.println("🐷 Opening dispenser gate...");
  Firebase.RTDB.setString(&fbData, basePath + "/feedingStatus", "DISPENSING_TO_PIG");
  dispenserServo.write(SERVO2_OPEN);
  delay(5000);

  dispenserServo.write(SERVO2_CLOSED);
  delay(1000);

  DateTime now = getCurrentTime();
  String feedingLogPath = "/users/" + userUID + "/feeding/" +
                          (feedType == "manual" ? "manualFeeds" : "scheduledFeeds");

  FirebaseJson feedingLog;
  feedingLog.set("status", "triggered");
  feedingLog.set("timestamp", now.timestamp());
  feedingLog.set("type", feedType);
  feedingLog.set("amount", currentWeight);

  if (Firebase.RTDB.pushJSON(&fbData, feedingLogPath.c_str(), &feedingLog)) {
    Serial.println("✅ Feeding logged");
  }

  isFeeding = false;
  Firebase.RTDB.setString(&fbData, basePath + "/feedingStatus", "COMPLETE");
  Firebase.RTDB.setString(&fbData, basePath + "/feedCommand", "NONE");
  Firebase.RTDB.setFloat(&fbData, basePath + "/currentWeight", 0);

  // ✅ Send SMS alert: feeding complete
  String smsMsg = "Pig feeder: Feeding COMPLETE. ";
  smsMsg += String(currentWeight, 2) + " kg dispensed. Type: " + feedType + ".";
  sendSMS(smsMsg);

  Serial.println("✅ FEEDING COMPLETE!\n");
}

// ---- CHECK FEEDING SCHEDULES ----
void checkFeedingSchedules() {
  if (isFeeding) return;
  if (userUID.length() == 0) return;
  if (!Firebase.ready()) return;

  DateTime now = getCurrentTime();

  if (lastScheduleCheck.isValid() &&
      (now.unixtime() - lastScheduleCheck.unixtime()) < 60) {
    return;
  }

  lastScheduleCheck = now;

  Serial.println("📅 Checking schedules at " + String(now.hour()) + ":" +
                 (now.minute() < 10 ? "0" : "") + String(now.minute()));

  String schedulePath = "/users/" + userUID + "/feeding/schedules";

  if (Firebase.RTDB.getJSON(&fbData, schedulePath.c_str())) {
    FirebaseJson &json = fbData.jsonObject();
    size_t len = json.iteratorBegin();
    Serial.println("   Found " + String(len) + " schedule(s)");

    String key, value;
    int type = 0;

    for (size_t i = 0; i < len; i++) {
      json.iteratorGet(i, type, key, value);

      FirebaseJsonData hourData, minuteData, enabledData, weightData;
      json.get(hourData, key + "/hour");
      json.get(minuteData, key + "/minute");
      json.get(enabledData, key + "/isEnabled");
      json.get(weightData, key + "/weightKg");

      if (enabledData.success && enabledData.to<bool>()) {
        int scheduleHour = hourData.to<int>();
        int scheduleMinute = minuteData.to<int>();
        float weight = weightData.to<float>();

        Serial.println("   Schedule " + String(i + 1) + ": " + String(scheduleHour) + ":" +
                       (scheduleMinute < 10 ? "0" : "") + String(scheduleMinute) +
                       " (" + String(weight) + " kg)");

        if (now.hour() == scheduleHour && now.minute() == scheduleMinute) {
          Serial.println("   ✅ MATCH! Triggering scheduled feeding...");
          String basePath = "/users/" + userUID + "/devices/mainStorage";
          performFeeding(basePath, weight, "scheduled");
          delay(60000);
          break;
        }
      }
    }
    json.iteratorEnd();
  }
}

// ---- LOAD WIFI CREDENTIALS ----
bool loadCredentials() {
  preferences.begin("wifi", true);
  wifiSSID = preferences.getString("ssid", "");
  wifiPassword = preferences.getString("password", "");
  userUID = preferences.getString("uid", "");
  preferences.end();
  Serial.println("📋 Saved credentials:");
  Serial.println("   SSID: " + (wifiSSID.length() > 0 ? wifiSSID : "(none)"));
  Serial.println("   UID: " + (userUID.length() > 0 ? userUID : "(none)"));
  return (wifiSSID.length() > 0 && wifiPassword.length() > 0);
}

// ---- SAVE WIFI CREDENTIALS ----
void saveCredentials(String ssid, String password, String uid) {
  preferences.begin("wifi", false);
  preferences.putString("ssid", ssid);
  preferences.putString("password", password);
  preferences.putString("uid", uid);
  preferences.end();
  Serial.println("✅ Credentials saved!");
}

// ---- CLEAR SAVED CREDENTIALS ----
void clearCredentials() {
  preferences.begin("wifi", false);
  preferences.clear();
  preferences.end();
  wifiSSID = "";
  wifiPassword = "";
  userUID = "";
  Serial.println("🗑️ Credentials cleared");
}

// ---- WEB SERVER HANDLERS ----
void handleStatus() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String status = wifiConnected ? "connected" : "disconnected";
  String response = "{\"status\":\"ok\",\"wifi_status\":\"" + status + "\",";
  response += "\"connected_to\":\"" + wifiSSID + "\",";
  response += "\"ip\":\"" + WiFi.localIP().toString() + "\"}";
  server.send(200, "application/json", response);
}

void handleConnect() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  if (server.method() == HTTP_OPTIONS) { server.send(200); return; }

  if (server.hasArg("ssid") && server.hasArg("password")) {
    String newSSID = server.arg("ssid");
    String newPassword = server.arg("password");
    String newUID = server.hasArg("uid") ? server.arg("uid") : "";
    saveCredentials(newSSID, newPassword, newUID);
    wifiSSID = newSSID;
    wifiPassword = newPassword;
    userUID = newUID;
    server.send(200, "application/json",
      "{\"status\":\"success\",\"message\":\"WiFi updated! Reconnecting...\"}");
    delay(1000);
    WiFi.disconnect();
    delay(500);
    connectToWiFi();
  } else {
    server.send(400, "application/json",
      "{\"status\":\"error\",\"message\":\"Missing SSID or password\"}");
  }
}

void handleReset() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  clearCredentials();
  WiFi.disconnect();
  wifiConnected = false;
  server.send(200, "application/json",
    "{\"status\":\"success\",\"message\":\"WiFi credentials cleared\"}");
}

void handleInfo() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String html = "<!DOCTYPE html><html><head>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  html += "<style>body{font-family:Arial;padding:20px;}</style>";
  html += "<title>Pig Feeder Info</title></head><body>";
  html += "<h1>🐷 Pig Feeder Status</h1>";
  html += "<p><strong>Setup Network:</strong> " + String(AP_SSID) + "</p>";
  html += "<p><strong>Setup IP:</strong> " + WiFi.softAPIP().toString() + "</p>";
  if (wifiConnected) {
    html += "<p><strong>WiFi Status:</strong> ✅ Connected</p>";
    html += "<p><strong>Connected to:</strong> " + wifiSSID + "</p>";
    html += "<p><strong>WiFi IP:</strong> " + WiFi.localIP().toString() + "</p>";
    html += "<p><strong>Signal:</strong> " + String(WiFi.RSSI()) + " dBm</p>";
  } else {
    html += "<p><strong>WiFi Status:</strong> ❌ Not Connected</p>";
  }
  if (rtcAvailable) {
    DateTime now = rtc.now();
    html += "<p><strong>Current Time:</strong> " + String(now.timestamp()) + "</p>";
  }
  html += "<p><strong>Feeding:</strong> " + String(isFeeding ? "ACTIVE" : "IDLE") + "</p>";
  html += "<p><strong>Backup Storage:</strong> " + String(backupIsOpen ? "OPEN" : "CLOSED") + "</p>";
  html += "<p><strong>SIM800L:</strong> " + String(simReady ? "✅ Ready" : "❌ Not Ready") + "</p>";
  html += "</body></html>";
  server.send(200, "text/html", html);
}

// ---- START SETUP NETWORK ----
void startSetupNetwork() {
  Serial.println("\n========================================");
  Serial.println("🔧 STARTING SETUP NETWORK");
  Serial.println("========================================");
  WiFi.softAP(AP_SSID);
  Serial.println("✅ Setup network: " + String(AP_SSID));
  Serial.println("   IP: " + WiFi.softAPIP().toString());
  server.on("/", HTTP_GET, handleInfo);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/connect", HTTP_POST, handleConnect);
  server.on("/connect", HTTP_OPTIONS, handleConnect);
  server.on("/reset", HTTP_POST, handleReset);
  server.begin();
  Serial.println("✅ Web server running\n");
}

// ---- CONNECT TO WIFI ----
void connectToWiFi() {
  if (wifiSSID.length() == 0) {
    Serial.println("ℹ️ No WiFi credentials");
    wifiConnected = false;
    return;
  }
  Serial.println("📶 Connecting to WiFi: " + wifiSSID);
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("✅ WiFi Connected! IP: " + WiFi.localIP().toString());
    wifiConnected = true;
    initializeFirebase();
  } else {
    Serial.println("❌ WiFi connection failed!");
    wifiConnected = false;
  }
}

// ---- INITIALIZE FIREBASE ----
void initializeFirebase() {
  Serial.println("🔥 Initializing Firebase...");
  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  if (Firebase.ready()) {
    if (userUID.length() == 0) { Serial.println("❌ No user UID!"); return; }
    String basePath = "/users/" + userUID + "/devices/mainStorage";
    Firebase.RTDB.setString(&fbData, basePath + "/status", "SUFFICIENT");
    Firebase.RTDB.setInt(&fbData, basePath + "/feedLevel", 0);
    Firebase.RTDB.setString(&fbData, basePath + "/feedCommand", "NONE");
    Firebase.RTDB.setString(&fbData, basePath + "/feedingStatus", "IDLE");
    Firebase.RTDB.setFloat(&fbData, basePath + "/targetWeight", 0);
    Firebase.RTDB.setFloat(&fbData, basePath + "/currentWeight", 0);
    Firebase.RTDB.setString(&fbData, basePath + "/backupStatus", "CLOSED");
    Serial.println("✅ Firebase ready!");
    syncTimeWithNTP();
  }
}

// ---- SETUP ----
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n🐷 SMART PIG FEEDER\n");

  // ✅ Init SIM800L first
  initSIM800L();

  if (rtc.begin()) {
    rtcAvailable = true;
    Serial.println("✅ RTC initialized");
    if (rtc.lostPower()) {
      Serial.println("⚠️ RTC lost power");
      rtc.adjust(DateTime(2026, 1, 1, 0, 0, 0));
    }
  } else {
    Serial.println("❌ RTC not found");
  }

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  Serial.println("✅ Ultrasonic sensor initialized");

  storageServo.attach(SERVO1_PIN);
  dispenserServo.attach(SERVO2_PIN);
  backupServo.attach(SERVO_BACKUP_PIN);
  storageServo.write(SERVO1_CLOSED);
  dispenserServo.write(SERVO2_CLOSED);
  backupServo.write(BACKUP_SERVO_CLOSED);
  Serial.println("✅ Servos initialized (including backup)");

  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(calibration_factor);
  scale.tare();
  Serial.println("✅ Load cell initialized");

  WiFi.mode(WIFI_AP_STA);
  startSetupNetwork();
  if (loadCredentials()) {
    connectToWiFi();
  }

  Serial.println("🚀 System ready!\n");
}

// ---- MAIN LOOP ----
void loop() {
  server.handleClient();

  if (wifiSSID.length() > 0 && WiFi.status() != WL_CONNECTED && wifiConnected) {
    Serial.println("⚠️ WiFi lost! Reconnecting...");
    wifiConnected = false;
    ntpSynced = false;
    connectToWiFi();
  }

  long distance = readUltrasonicCM();
  int feedLevel = calculateFeedLevel(distance);

  // ✅ Backup check (simplified, no confirm counter)
  checkBackupStorage(feedLevel);

  if (wifiConnected && Firebase.ready() && userUID.length() > 0) {
    static unsigned long lastNTPSync = 0;
    if (!ntpSynced || (millis() - lastNTPSync > 3600000)) {
      syncTimeWithNTP();
      lastNTPSync = millis();
    }

    static unsigned long lastTimePrint = 0;
    if (millis() - lastTimePrint > 30000) {
      DateTime now = getCurrentTime();
      Serial.println("⏰ Current Time: " + String(now.year()) + "-" +
                     String(now.month()) + "-" + String(now.day()) + " " +
                     String(now.hour()) + ":" +
                     (now.minute() < 10 ? "0" : "") + String(now.minute()) + ":" +
                     (now.second() < 10 ? "0" : "") + String(now.second()));
      lastTimePrint = millis();
    }

    String basePath = "/users/" + userUID + "/devices/mainStorage";
    Firebase.RTDB.setInt(&fbData, basePath + "/feedLevel", feedLevel);

    String status;
    if (feedLevel <= LOW_FEED_THRESHOLD && backupIsOpen) {
      status = "LOW - REFILLING";
    } else if (feedLevel <= LOW_FEED_THRESHOLD) {
      status = "LOW";
    } else {
      status = "SUFFICIENT";
    }
    Firebase.RTDB.setString(&fbData, basePath + "/status", status);

    checkFeedingSchedules();

    if (!isFeeding && Firebase.RTDB.getString(&fbData, basePath + "/feedCommand")) {
      String command = fbData.stringData();
      if (command == "FEED") {
        if (Firebase.RTDB.getFloat(&fbData, basePath + "/targetWeight")) {
          targetWeight = fbData.floatData();
          if (targetWeight > 0) {
            performFeeding(basePath, targetWeight, "manual");
          } else {
            Firebase.RTDB.setString(&fbData, basePath + "/feedCommand", "NONE");
          }
        }
      }
    }
  }

  delay(1000);
}
