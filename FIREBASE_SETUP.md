# 🔐 Firebase Configuration Setup

## ⚠️ Important Security Notice

This repository does NOT include sensitive Firebase configuration files for security reasons. You need to add your own Firebase credentials to run this project.

## 📝 Setup Instructions

### 1. Firebase Configuration Files

You need to create the following files with your actual Firebase credentials:

#### **For Dart/Flutter** (`lib/firebase_options.dart`)
1. Copy the template file:
   ```bash
   cp lib/firebase_options.example.dart lib/firebase_options.dart
   ```

2. Get your Firebase configuration:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project (or create a new one)
   - Run FlutterFire CLI: `flutterfire configure`
   - Or manually replace the placeholder values in `firebase_options.dart`

#### **For Android** (`android/app/google-services.json`)
1. Copy the template file:
   ```bash
   cp android/app/google-services.example.json android/app/google-services.json
   ```

2. Get the actual file:
   - Go to Firebase Console → Project Settings
   - Under "Your apps" → Select your Android app
   - Download `google-services.json`
   - Place it in `android/app/` directory

#### **For iOS** (if applicable)
- Download `GoogleService-Info.plist` from Firebase Console
- Place it in `ios/Runner/` directory

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## 🔒 Security Best Practices

- **NEVER** commit these files to version control:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

- These files are already added to `.gitignore`
- Only share template/example files
- Use environment-specific configurations for production

## 🚀 Quick Start with FlutterFire CLI

The easiest way to configure Firebase:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure your project
flutterfire configure
```

This will automatically create the `firebase_options.dart` file with your credentials.

## 📚 Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

---

⚡ **Note**: Make sure you have set up a Firebase project before following these steps.
