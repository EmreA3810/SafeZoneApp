# SafeZone - Community Watch App

A Flutter mobile application that allows users to report and track community issues in their neighborhood. Users can report problems like road hazards, broken streetlights, graffiti, lost pets, and more with photos and location information.

## 🎯 Project Status: ✅ CORE FEATURES COMPLETE

All core features are fully implemented! Security features and enhanced moderation coming next.

## Features

### 🔐 Authentication ✅
- Google Sign-In integration
- Firebase Authentication
- User profile management
- Profile photo upload to Firebase Storage
- Auto-login on app restart
- Sign-out with confirmation

### 📱 Navigation & UI ✅
- **Bottom Navigation Bar**: 4 tabs (Feed, Map, My Reports, Profile)
- **Floating Action Button**: Quick access to create reports
- **Material Design 3**: Modern, responsive UI
- **Dark/Light Mode**: Toggle theme with persistent settings
- **Gesture-Based Navigation**: Click cards to view details

### 📋 Feed Page ✅
- Browse all community reports
- Beautiful card layout with images
- User info (name, photo, timestamp)
- Like/unlike functionality
- Status badges (5 types: Pending, Approved, In Progress, Resolved, Rejected)
- Category chips
- Location display
- **Filter by status and category**
- **Pull-to-refresh**
- **Click card to view full report details**

### 🗺️ Map View ✅
- Interactive map with OpenStreetMap
- Color-coded markers by status:
  - 🟠 Orange = Pending
  - 🔵 Blue = Approved
  - 🟡 Amber = In Progress
  - 🟢 Green = Resolved
  - 🔴 Red = Rejected
- Category-specific icons
- Current location marker
- Legend showing all status colors
- Search reports functionality
- **Click markers to view report details**
- My location button

### ➕ Report Submission Form ✅
- Title, description, category selection
- **9 report categories**:
  - Road Hazard, Streetlight, Graffiti, Lost Pet, Found Pet
  - Parking Issue, Noise Complaint, Waste Management, Other
- **Multiple photo upload** (camera & gallery)
- Photo preview with delete option
- **Location picker with address geocoding**
- Form validation
- Current location detection

### 📌 My Reports Page ✅
- Display user's submitted reports
- **Edit functionality** with pre-filled form
- **Delete functionality** with confirmation dialog
- Status indicators (color-coded badges)
- Pull-to-refresh
- Time-ago formatting

### 👤 Profile & Settings Page ✅
- User profile display:
  - Profile photo (circular avatar)
  - Display name
  - Email address
  - Reports submitted counter
- Profile photo upload with upload indicator
- **Dark/Light mode toggle** (persistent across sessions)
- **Liked Reports** section (view all liked reports)
- Admin Controls (for admin users)
- Notification Settings
- About app
- Sign out with confirmation

### ❤️ Liked Reports Screen ✅
- **Dedicated screen for all liked reports**
- **Accessible from Profile page**
- Click cards to view full report details
- Empty state message
- Shows like count

### 🎨 UI Features ✅
- Material Design 3
- Dark mode support with smooth transitions
- Responsive design (desktop, tablet, mobile)
- Smooth animations and transitions
- Image caching with lazy loading
- Loading states & error handling
- Confirmation dialogs
- Toast notifications
- Empty states

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
- **Provider Selectors**: Prevents unnecessary widget rebuilds on state changes
- **Real-time Updates**: Firebase handles offline sync and real-time data updates

## Tech Stack

- **Frontend**: Flutter & Dart, Material Design 3
- **State Management**: Provider
- **Backend**: Firebase
  - Authentication (Google Sign-In)
  - Firestore (user profiles)
  - Realtime Database (reports with indexed queries)
  - Cloud Storage (images)
- **Maps**: flutter_map with OpenStreetMap (free & no API key!)
- **Media**: Image Picker, flutter_image_compress, Cached Network Image
- **Location**: geolocator, geocoding
- **Time**: timeago

## Report Categories & Status

### Categories
Road Hazard • Streetlight • Graffiti • Lost Pet • Found Pet • Parking • Noise • Waste • Other

### Status Types
- 🟠 Pending - Awaiting admin review
- 🔵 Approved - Admin approved
- 🟡 In Progress - Being addressed
- 🟢 Resolved - Issue fixed
- 🔴 Rejected - Admin rejected

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── models/
│   ├── report_model.dart              # Report data model
│   └── user_model.dart                # User profile model
├── services/
│   ├── auth_service.dart              # Google Sign-In & Firebase Auth
│   └── report_service.dart            # CRUD operations
├── providers/
│   └── theme_provider.dart            # Dark/Light theme management
└── screens/
    ├── login_screen.dart              # Google Sign-In
    ├── home_screen.dart               # Bottom navigation
    ├── feed_screen.dart               # Reports feed with filters
    ├── map_screen.dart                # Interactive map
    ├── add_report_screen.dart         # Create/Edit report
    ├── location_picker_screen.dart    # Location selection
    ├── my_reports_screen.dart         # User's reports
    ├── liked_reports_screen.dart      # Liked reports screen
    └── profile_screen.dart            # Profile & settings
```

## Documentation

- **Quick Start**: See `QUICKSTART.md` for quick setup guide
- **Firebase Setup**: See `FIREBASE_SETUP.md` for detailed configuration
- **TODO List**: See `TODO.md` for upcoming features and roadmap

## Upcoming Features (Roadmap)

### Phase 1: Report Visibility & Security
- Private report visibility (pending/rejected only visible to creator & admins)
- Firestore security rule updates
- Admin moderation controls

### Phase 2: Subscriber Notifications
- Category subscriptions
- Firebase Cloud Messaging (FCM) integration
- Notification center
- Real-time notifications when reports become public

### Phase 3: Enhanced Admin Tools
- Moderation queue
- Rejection reason notes
- Comments section
- Report status history

Built with ❤️ using Flutter
