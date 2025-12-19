# SafeZone - Community Watch App

A Flutter mobile application that allows users to report and track community issues in their neighborhood. Users can report problems like road hazards, broken streetlights, graffiti, lost pets, and more with photos and location information.

## Features

### 🔐 Authentication
- Google Sign-In integration
- User profile management
- Profile photo upload

### 📱 Core Features
- **Feed Page**: Browse all community reports with filtering options (All, Pending, In Progress, Resolved)
- **Map View**: Interactive map showing all reported issues with markers colored by status
- **Report Submission**: 
  - Add title, description, and category
  - Upload multiple photos from camera or gallery
  - Pin exact location on map with address
- **My Reports**: View, edit, and delete your own reports
- **Profile & Settings**: 
  - Update profile photo
  - Toggle dark/light theme
  - View report statistics
  - Sign out

### 🎨 UI Features
- Material Design 3
- Dark mode support
- Responsive design
- Smooth animations
- Image caching

## Setup Instructions

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Firebase account
- Android Studio / Xcode for mobile development

### Firebase Setup

See `FIREBASE_SETUP.md` for detailed instructions. Quick summary:

**Option 1: Manual Setup (Firebase Console)**
1. Create Firebase project at https://console.firebase.google.com/
2. Enable Authentication (Google Sign-In)
3. Create Firestore Database
4. Create Realtime Database (for optimized queries)
5. Enable Storage
6. Download and place config files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/` (via Xcode)

**Option 2: Firebase CLI (Recommended)**
```bash
npm install -g firebase-tools
firebase login
firebase init
firebase deploy --only database,firestore,storage
```
This automatically deploys optimized rules with indexes for better query performance.

For complete Firebase CLI walkthrough, see `FIREBASE_SETUP.md` section 8.

### Installation Steps

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase** (follow setup above)

3. **Run the app**
   ```bash
   flutter run
   ```

## Permissions Required

### Android
- Internet access
- Location (GPS)
- Camera
- Photo library

### iOS
- Location when in use
- Camera usage
- Photo library access

## Tech Stack

- **Frontend**: Flutter & Dart, Material Design 3
- **State Management**: Provider
- **Backend**: Firebase
  - Authentication (Google Sign-In)
  - Firestore (user profiles)
  - Realtime Database (reports with indexed queries)
  - Cloud Storage (images)
- **Maps**: flutter_map with OpenStreetMap
- **Media**: Image Picker, flutter_image_compress, Cached Network Image
- **Location**: geolocator, geocoding

## Performance Optimizations

- **RTDB Indexes**: Queries filtered by `userId`, `status`, `category` for efficient data retrieval
- **Image Compression**: Auto-compress uploads to base64 (target width 800px, quality 70%)
- **Lazy Loading**: Cached network images with fallbacks
- **Debounced Search**: Reduces unnecessary rebuilds
- **Provider Selectors**: Prevents unnecessary widget rebuilds on state changes

## Report Categories

Road Hazard • Streetlight • Graffiti • Lost Pet • Found Pet • Parking • Noise • Waste • Other

## Documentation

- **Quick Start**: See `QUICKSTART.md` for 5-step setup
- **Firebase Setup**: See `FIREBASE_SETUP.md` for detailed configuration and CLI instructions
- **TODO List**: See `TODO.md` for planned features and optimizations

Built with ❤️ using Flutter
