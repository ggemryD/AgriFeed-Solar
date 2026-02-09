# AgriFeed Solar

**AgriFeed Solar** is a solar-powered smart feeding system designed to support
sustainable piggery production through automated, weight-based feed dispensing,
real-time monitoring, and intelligent notifications.

The system integrates IoT, renewable energy, and mobile technology to improve
feeding efficiency, reduce feed waste, and ensure reliable operation even in
areas with unstable electricity using an Automatic Transfer Switch (ATS).

---

## 🐷 Project Overview

This project aims to:
- Automate pig feeding using scheduled and weight-based dispensing
- Utilize solar energy for cost-efficient and sustainable operation
- Monitor feed levels and machine status remotely
- Send real-time alerts via mobile notifications and SMS
- Support sustainable livestock farming practices

---

## ⚙️ System Features

- ☀️ **Solar-Powered System**
  - 100W–200W solar panel
  - Charge controller and 12V battery
  - Automatic Transfer Switch (ATS)

- ⚖️ **Weight-Based Feed Detection**
  - Load cell sensor with HX711 amplifier
  - Accurate feed measurement to prevent overfeeding

- ⏰ **Scheduled Automatic Dispensing**
  - Programmable feeding schedules
  - Stepper/DC motor-controlled feed release

- 🌐 **IoT-Based Monitoring**
  - Real-time data via Firebase
  - Mobile app dashboard

- 🔔 **Notification System**
  - Push notifications (Firebase Cloud Messaging)
  - SMS alerts via GSM module for low feed and feeding completion

- 📦 **Backup Feed Storage**
  - Automatic refill mechanism when feed level is low

---

## 📱 Mobile Application

The mobile app allows farmers to:
- View real-time feed levels and power status
- Control manual and scheduled feeding
- Receive alerts and notifications
- Manage user profile and farm information

**Architecture:** MVVM (Model–View–ViewModel)  
**Frontend:** Flutter  
**Backend:** Firebase Realtime Database & Cloud Functions  

---

## 🧠 System Architecture

**Hardware:**
- ESP32 microcontroller
- Load cell sensors
- GSM module (SIM800/SIM900)
- Solar power system with battery and ATS

**Software:**
- Flutter mobile application
- Firebase Realtime Database
- Firebase Cloud Functions (2nd Gen)
- Firebase Cloud Messaging (FCM)

