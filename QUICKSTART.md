# SafeZone - Quick Start Guide

## 🚀 Getting Started

Welcome to SafeZone! This guide will help you get the app up and running quickly.

## Prerequisites Checklist

Before you begin, make sure you have:

- [ ] Flutter SDK installed (version 3.9.0+)
- [ ] Android Studio or Xcode installed
- [ ] A Google account
- [ ] A Firebase account (free tier is fine)

## Quick Setup (5 Steps)

### Step 1: Install Dependencies ✅
```bash
flutter pub get
```
**Status**: Already done! ✓

### Step 2: Set Up Firebase (15-20 minutes)

**Option A: Using Firebase Console (Manual)**
Follow the detailed instructions in `FIREBASE_SETUP.md`:
1. Create Firebase project at https://console.firebase.google.com/
2. Add Android/iOS apps
3. Download & place config files
4. Enable Authentication, Firestore, Realtime Database, and Storage

**Option B: Using Firebase CLI (Recommended)**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize from project root
firebase init

# Deploy rules (includes indexes for optimal performance)
firebase deploy --only database,firestore,storage
```
See `FIREBASE_SETUP.md` section 8 for detailed Firebase CLI instructions.

### Step 3: Configure Permissions

**Android** - File: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS** - File: `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby reports</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access</string>
```

### Step 4: Run the App
```bash
flutter run
```

### Step 5: Test Core Features

1. **Sign In** with your Google account
2. **Create a Report**:
   - Tap the blue "Report" button
   - Fill in title: "Test Report"
   - Add description
   - Select category
   - Take/upload a photo (optional)
   - Select location
   - Submit
3. **View on Map** - Check the Map tab
4. **Check My Reports** - View your submitted reports
5. **Toggle Theme** - Go to Profile and switch dark mode

## App Structure Overview

```
SafeZone
├── Feed Tab        → Browse all community reports
├── Map Tab         → View reports on interactive map
├── My Reports Tab  → Manage your submissions
└── Profile Tab     → Settings and account info
```

## Features at a Glance

### 📋 Report Issues
- Road hazards, streetlights, graffiti, lost pets, and more
- Add photos from camera or gallery
- Pin exact location on map
- Track status (Pending → Approved → In Progress → Resolved)

### 🗺️ Interactive Map
- See all reports with color-coded markers
- Orange = Pending
- Amber = In Progress
- Green = Resolved

### 👤 User Profile
- View your report statistics
- Update profile photo
- Toggle dark/light theme
- Sign out

## Common First-Time Issues

### Can't sign in with Google?
1. Make sure Google Sign-In is enabled in Firebase Console
2. For Android: Add SHA-1 fingerprint to Firebase project
3. Download updated `google-services.json` after adding SHA-1

### Camera/Location not working?
- Check that permissions are added to AndroidManifest.xml (Android)
- Check that usage descriptions are in Info.plist (iOS)
- Grant permissions when the app asks

### App crashes on launch?
- Make sure Firebase config files are in the right place
- Run `flutter clean` then `flutter pub get`
- Rebuild the app

## Development Tips

### Hot Reload
Press `r` in the terminal while app is running to see changes instantly

### Clean Build
If things aren't working:
```bash
flutter clean
flutter pub get
flutter run
```

### View Logs
```bash
flutter logs
```

## What's Next?

After basic setup:

1. **Customize the app**
   - Change app name in `pubspec.yaml`
   - Update package name
   - Add custom app icon

2. **Explore features**
   - Try filtering reports by status
   - Edit and delete your reports
   - Check the interactive map

3. **Test with friends**
   - Add multiple test reports
   - View reports from different accounts
   - Test all categories

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── report_model.dart
│   └── user_model.dart
├── services/                    # Business logic
│   ├── auth_service.dart
│   └── report_service.dart
├── providers/                   # State management
│   └── theme_provider.dart
└── screens/                     # UI screens
    ├── login_screen.dart
    ├── home_screen.dart
    ├── feed_screen.dart
    ├── map_screen.dart
    ├── add_report_screen.dart
    ├── location_picker_screen.dart
    ├── my_reports_screen.dart
    └── profile_screen.dart
```

## Need Help?

- 📖 Read `README.md` for full documentation
- 🔥 Check `FIREBASE_SETUP.md` for complete Firebase setup (manual or CLI)
- 🔧 See `FIREBASE_SETUP.md` section 8 for Firebase CLI quick start
- 🐛 Check errors in terminal output
- 💬 Common issues are listed above

## Success Indicators

You'll know everything is working when:
- ✅ App launches without crashes
- ✅ Can sign in with Google
- ✅ Can create a report with photo
- ✅ Report appears in Feed and Map
- ✅ Can edit/delete your own reports
- ✅ Theme toggle works
- ✅ All tabs are functional

## Ready to Deploy?

Once testing is complete:
1. Update version in `pubspec.yaml`
2. Build release APK: `flutter build apk --release`
3. Build iOS: `flutter build ios --release`

---

**Congratulations!** 🎉 You're ready to use SafeZone to make your community a better place!

For detailed documentation, see `README.md`
For Firebase setup help, see `FIREBASE_SETUP.md`
