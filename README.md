# 🕉️ Japamala - Digital Mantra Counter

A beautiful, modern Flutter application for digital mantra counting and spiritual practice tracking. Japamala brings the ancient tradition of mala bead counting into the digital age with a clean, intuitive interface and powerful features.

**Note:** I created this app initially for my own personal use, but later decided to release it as open source because I found that there was no japamala app that was independent of any specific dharma or religious tradition. This app is designed to be universally usable for anyone interested in mantra practice, regardless of their spiritual background. I also wanted to keep it free from Google Services Framework (GSF) to maintain user privacy and independence.

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

### 🧘‍♀️ Core Functionality
- **Custom Mantra Creation**: Add unlimited mantras with personalized names and target counts
- **Digital Bead Counter**: Tap-to-count interface with haptic feedback
- **Progress Tracking**: Visual progress indicators and completion statistics
- **Session History**: Automatic logging of all meditation sessions

### 📱 User Experience
- **Material Design 3**: Modern, beautiful UI with light/dark theme support
- **Haptic Feedback**: Satisfying tactile responses for each bead count
- **Offline First**: Works completely offline with local data storage
- **Privacy-Friendly**: No internet permission, no file access, no notifications - your practice stays private
- **Cross-Platform**: Android, iOS, Web, Windows, macOS, and Linux support

### 🛠️ Advanced Features
- **Gratitude Journal**: Daily gratitude notes with date-based organization
- **Calendar View**: Visual practice calendar with completion tracking
- **Breathing Exercises**: Guided breathing patterns for meditation
- **Meditation Timer**: Customizable meditation sessions with intervals
- **Data Persistence**: Hive database for reliable local storage

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** (^3.9.2) - [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (included with Flutter)
- **Android Studio** (for Android development) or **Xcode** (for iOS development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/japamala.git
   cd japamala
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS (on macOS):**
```bash
flutter build ios --release
```

## 📁 Project Structure

```
japamala/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models (Hive objects)
│   ├── providers/                # State management (Provider pattern)
│   ├── screens/                  # UI screens and pages
│   └── services/                 # Business logic and utilities
├── android/                      # Android platform code
├── ios/                          # iOS platform code
├── web/                          # Web platform code
├── windows/                      # Windows platform code
├── macos/                        # macOS platform code
├── linux/                        # Linux platform code
├── test/                         # Unit and widget tests
└── docs/                         # Documentation
```

## 🏗️ Architecture

- **State Management**: Provider pattern for reactive state updates
- **Data Persistence**: Hive NoSQL database for local storage
- **UI Framework**: Flutter with Material Design 3
- **Platform Integration**: Native Android/iOS features via platform channels

## 🤝 Contributing

We welcome contributions!

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes and add tests
4. Run tests: `flutter test`
5. Format code: `flutter format .`
6. Submit a pull request

### Code Style
- Follow Dart's [effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` for consistent formatting
- Write meaningful commit messages

## 📋 Roadmap

See [requirements.md](requirements.md) for detailed development roadmap and feature specifications.

### Planned Features
- [ ] Advanced statistics and insights
- [ ] Custom themes and personalization

## 🐛 Bug Reports & Feature Requests

- **Bug Reports**: [GitHub Issues](https://github.com/yourusername/japamala/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/yourusername/japamala/discussions)
- **Security Issues**: Contact maintainers directly

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by traditional mala bead counting practices
- Built with ❤️ using Flutter
- Special thanks to the Flutter and Dart communities


---

**🕉️ May your practice bring peace and clarity to your mind. 🕉️**
