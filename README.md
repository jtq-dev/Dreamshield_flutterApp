# 🌙 DreamShield — App Concept (SEP 758 Final)

A next-generation sleep wellbeing app concept built with Flutter, designed to help users achieve calmer nights and deeper recovery.

## ✨ Concept
DreamShield rests on three pillars:
1. 💤 **Sleep Tracking** — quick nightly logs + effortless edits  
2. 🧠 **Coaching Insights** — trends + actionable tips  
3. 🎧 **Soundscape Studio** — pink/brown/white noise mixer + breathing pacer  

The prototype emphasizes elegance, speed, and realism: multi-screen navigation, persistence, dialogs, theming, and web-ready behavior.

---

## 🧩 Key Features (Mapped to Rubric)
- 🗺️ **Screens & Navigation**
  - **Home**: personalized overview dashboard
  - **Sessions**: chronological sleep history
  - **Studio**: noise mixer + breathing pacer
  - **Explore**: interactive map for discovery
- 🔐 **Auth (Firebase Email/Password)**
  - User-scoped data under `users/{uid}`
- 👤 **Profile**
  - Goal + dark theme preferences (SharedPreferences) + Alerts
- ✅ **Consent Sheet**
  - One-time privacy notice
- 🌐 **Resilient Web**
  - Fallback behavior when sensors/BLE are unavailable

---

## 🎬 Demo
- Video: (add your link)
- Live Web (optional): (add link)

---

## 🛠 Tech Stack
- Flutter / Dart
- Firebase Auth + Firestore
- SharedPreferences
- Google Maps (Explore screen)
- Responsive UI + Theming

---

## 🚀 Run Locally

### Prereqs
- Flutter SDK installed
- Android Studio or VS Code
- (Optional) Firebase project

### Install
```bash
flutter pub get
