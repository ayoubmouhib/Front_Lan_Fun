# LinguaConnect 🌍

**Learn Languages, Make Friends**

LinguaConnect is a cross-platform Flutter application that connects language learners around the world. It pairs users with language-exchange partners, and provides chat, audio/video calls, vocabulary practice, quizzes, mini-games, and gamification to keep learners motivated.

---

## ✨ Features

### Authentication & Onboarding
- Splash screen with session resolution (auto-login via secure token storage)
- Onboarding flow for first-time users
- Email/password sign up & login, email verification, and password recovery
- Google Sign-In support

### Discovery & Matching
- Discover and search for language partners by language, proficiency level, and interests
- Partner & user profile pages
- Send/accept match (follow) requests and manage connections
- "My Connections" overview

### Conversations & Calls
- Real-time one-to-one chat over WebSockets
- Audio and video calls powered by **LiveKit (WebRTC)**
- Post-call rating screen for feedback on partners

### Learning Tools
- **Vocabulary**: build a personal word list with audio pronunciation (record & playback)
- **Quizzes**: language proficiency / practice quizzes
- **Practice sessions** for guided study
- **Mini-games** to reinforce learning

### Gamification & Social
- Achievements, leaderboard, and daily challenges
- User reviews & ratings
- Notifications center
- Block/unblock users

### App Experience
- Light & dark themes (Material 3, Poppins via Google Fonts) with persisted theme preference
- Smooth page transitions and responsive layouts for phones, tablets, and desktop

---

## 🛠 Tech Stack

| Category | Package(s) |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart SDK `^3.11.4`) |
| State management & routing | [`get`](https://pub.dev/packages/get) (GetX – controllers, bindings, navigation) |
| HTTP client | [`dio`](https://pub.dev/packages/dio) |
| Real-time messaging | [`web_socket_channel`](https://pub.dev/packages/web_socket_channel) |
| Audio/Video calls | [`livekit_client`](https://pub.dev/packages/livekit_client) (WebRTC) |
| Local storage | [`shared_preferences`](https://pub.dev/packages/shared_preferences), [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) |
| Authentication | [`google_sign_in`](https://pub.dev/packages/google_sign_in) |
| Media | [`record`](https://pub.dev/packages/record), [`audioplayers`](https://pub.dev/packages/audioplayers), [`image_picker`](https://pub.dev/packages/image_picker), [`cached_network_image`](https://pub.dev/packages/cached_network_image) |
| UI / Animation | [`google_fonts`](https://pub.dev/packages/google_fonts), [`lottie`](https://pub.dev/packages/lottie), [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) |
| Utilities | [`intl`](https://pub.dev/packages/intl), [`logger`](https://pub.dev/packages/logger), [`path_provider`](https://pub.dev/packages/path_provider) |

---

## 📁 Project Structure

```
lib/
├── config/                  # Constants, routes, theme configuration
│   ├── constants.dart
│   ├── routes.dart
│   └── theme.dart
├── data/
│   ├── datasources/
│   │   ├── local/           # Secure storage / shared preferences wrapper
│   │   └── remote/           # Dio-based API clients (auth, user, matching, quiz, etc.)
│   ├── models/               # Data models (user, conversation, match, quiz, vocabulary...)
│   └── repositories/         # Repository layer mediating between APIs and controllers
├── presentation/
│   ├── bindings/              # GetX dependency bindings per feature
│   ├── controllers/           # GetX controllers (business/UI logic)
│   ├── screens/                # Feature screens (auth, home, conversation, profile, ...)
│   ├── themes/                 # App theming
│   └── widgets/                # Reusable widgets (buttons, cards, inputs, messages...)
├── services/                  # Cross-cutting services (e.g. WebSocket service)
├── utils/                      # Helpers (validators, responsive utilities)
└── main.dart                   # App entry point
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.11.4` or compatible)
- A running instance of the LinguaConnect backend (REST API + WebSocket server)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd application
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure the backend endpoint**

   By default, the app points at a local backend. Update `lib/config/constants.dart` if your backend runs elsewhere:
   ```dart
   static const String apiBaseUrl = 'http://localhost:3000';
   static const String wsBaseUrl  = 'ws://localhost:3000';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Supported Platforms

This project is configured for:

- 📱 Android
- 🍎 iOS
- 🌐 Web
- 🖥️ Windows, macOS, Linux

---

## 🎨 Theming

The app uses a Material 3 design system with a custom **indigo/emerald** color palette, the **Poppins** font (via Google Fonts), and full light/dark mode support. Theme preference is persisted locally and restored on launch.

---

## ✅ Testing

Run the test suite with:

```bash
flutter test
```

---

## 📄 License

This project currently has no license specified.
