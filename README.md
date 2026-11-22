# 🍲 Smart Leftover & Food Rescue Tracker

[![Flutter](https://img.shields.io/badge/Flutter-v3.2+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Vercel](https://img.shields.io/badge/Vercel-Deployment%20Ready-000000?logo=vercel&logoColor=white)](https://vercel.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

A production-ready mobile and web platform that connects surplus food providers (hotels, hostels, restaurants, bakeries) with verified recipients (orphanages, shelters, community kitchens, neighbors) to rescue food before it spoils.

---

## 🌟 Core Features

### 🏨 1. Food Provider Dashboard
- **Quick-Post Surplus Food**: Upload food photo via Cloudinary with automatic WebP compression, select food categories (Veg, Non-Veg, Vegan, Bakery), specify portions, preparation time, and a mandatory best-before countdown timer.
- **Hygiene & Safety Pledge**: Mandatory declaration confirming adherence to sanitary standards before listings go live.
- **Partial Claims**: Toggle allowing large batches (e.g. 50 meals) to be claimed partially across multiple recipients.
- **Live Inventory Manager**: Real-time listing cards with live ticking countdown badges (<1h critical red, 1-3h warning amber, >3h fresh green) and one-tap status toggles.
- **Handover Verification**: Verify and complete pickups via a 4-digit OTP or QR code presented by recipients.
- **Impact Analytics**: Real-time metrics tracking meals saved, kg CO2e prevented, and groundwater conserved.

### 🤝 2. Food Recipient Dashboard
- **Urgency Map & Live Feed**: Interactive map displaying color-coded geohash pins based on remaining safe window alongside a distance-sorted feed.
- **Smart Filters**: Filter by dietary category, search radius (1 to 15 km), and minimum serving sizes for bulk orphanage requirements.
- **Instant Claim & 30-Minute Atomic Lock**: Firestore atomic transaction prevents double-booking race conditions by locking reservations for 30 minutes.
- **Handover OTP & QR Code**: Generates a 4-digit verification code and QR code for verification at pickup.
- **Turn-by-Turn Navigation**: One-tap direct routing via Google Maps Directions API.

---

## 🏗️ Architecture & Technology Stack

- **Mobile Framework**: Flutter (Dart) using Riverpod for reactive state management.
- **Backend & Database**: Firebase Authentication (Email/Password + Phone OTP) and Cloud Firestore with strict security rules.
- **Proximity Alerts**: Firebase Cloud Messaging (FCM) triggered via Cloud Functions within a 5 km geohash radius.
- **Maps & Geolocation**: Google Maps SDK, Leaflet (Web Preview), and Haversine geohash distance algorithms.
- **Media Optimization**: Cloudinary unsigned WebP upload preset.

---

## 🚀 Getting Started

### Local Web Preview
```bash
python -m http.server 8085 --directory web_preview
```
Access at `http://localhost:8085`.

### Mobile Application (Android)
```bash
flutter pub get
flutter run -d android
```

### Deploy to Vercel
Connect this GitHub repository to [Vercel](https://vercel.com) or run:
```bash
vercel --prod
```

---

## 📄 License
This project is licensed under the MIT License.
