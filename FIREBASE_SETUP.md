# Firebase Configuration Guide for SafeZone

## Step-by-Step Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: **SafeZone**
4. Enable/disable Google Analytics (your choice)
5. Click "Create project"

---

### 2. Add Android App

1. In Firebase Console, click the Android icon
2. Enter package name: `com.example.safezone` (or your package name from `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place the file in: `android/app/google-services.json`

#### Update Android Files:

**File: `android/build.gradle.kts`**
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**File: `android/app/build.gradle.kts`**
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Add this line
}

android {
    defaultConfig {
        minSdk = 21 // Make sure this is at least 21
    }
}
```

**File: `android/app/src/main/AndroidManifest.xml`**
Add these permissions inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32"/>
```

---

### 3. Add iOS App

1. In Firebase Console, click the iOS icon
2. Enter bundle ID: `com.example.safezone` (from `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Drag `GoogleService-Info.plist` into the Runner folder in Xcode
6. Make sure "Copy items if needed" is checked

#### Update iOS Files:

**File: `ios/Runner/Info.plist`**
Add these keys:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby reports and pin report locations</string>

<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos of community issues</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to upload images</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need permission to save photos</string>
```

---

### 4. Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Go to **Sign-in method** tab
4. Enable **Google** sign-in provider
5. Set support email
6. Click "Save"

#### For Android (Get SHA-1):
```bash
cd android
./gradlew signingReport
```
Copy the SHA-1 from the debug keystore and add it in Firebase Console > Project Settings > Your apps > Android app > Add fingerprint

---

### 5. Set Up Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Click "Create database"
3. Choose "Start in production mode"
4. Select a location (choose nearest to your users)
5. Click "Enable"

#### Update Firestore Rules:

Go to **Rules** tab and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports collection
    match /reports/{reportId} {
      // Anyone can read reports
      allow read: if true;
      
      // Only authenticated users can create reports
      allow create: if request.auth != null;
      
      // Only the report owner can update or delete
      allow update, delete: if request.auth != null && 
                                resource.data.userId == request.auth.uid;
    }
  }
}
```

Click "Publish"

---

### 5.1 Set Up Realtime Database (RTDB)

1. Go to **Realtime Database** in Firebase Console
2. Click "Create database" and choose a location
3. Start in production mode (recommended)

#### RTDB Rules (with indexes)

Paste the following rules to enable reads/writes and add indexes for performant queries:

```json
{
  "rules": {
    "reports": {
      ".read": true,
      ".write": "auth != null",
      ".indexOn": ["userId", "status", "category"]
    },
    "users": {
      "$userId": {
        ".read": true,
        ".write": "auth != null && auth.uid === $userId"
      }
    }
  }
}
```

Notes:
- `".indexOn"` enables efficient queries like `orderByChild('userId').equalTo(uid)` and filters on `status`/`category`.
- You can also add `"createdAt"` to the index array if you plan to query by timestamp.

If you prefer deploying rules from the project, create `database.rules.json` at the project root and add RTDB config to `firebase.json`, then deploy with the Firebase CLI.

---

### 6. Set Up Firebase Storage

1. Go to **Storage** in Firebase Console
2. Click "Get started"
3. Choose "Start in production mode"
4. Click "Done"

#### Update Storage Rules:

Go to **Rules** tab and paste:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Reports images
    match /reports/{reportId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // User profile photos
    match /users/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Click "Publish"

---

### 7. Test the Setup

1. Run the app:
   ```bash
   flutter run
   ```

2. Try signing in with Google

3. Create a test report

4. Check Firebase Console:
   - Authentication > Users (should show your account)
   - Firestore > Data (should show users and reports collections)
   - Storage (should show uploaded images)

---

## 8. Install & Configure Firebase CLI

### Install Firebase CLI

#### Option 1: Using npm (Recommended)

```bash
npm install -g firebase-tools
```

Verify installation:
```bash
firebase --version
```

#### Option 2: Download from GitHub

1. Visit [Firebase CLI GitHub Releases](https://github.com/firebase/firebase-tools/releases)
2. Download the latest release for your OS (Windows `.exe`, macOS `.pkg`, or Linux binary)
3. Follow the installer prompts
4. Verify in terminal:
   ```bash
   firebase --version
   ```

#### Option 3: Using Homebrew (macOS)

```bash
brew install firebase-cli
```

---

### Configure Firebase CLI for Your Project

1. **Login to Firebase:**
   ```bash
   firebase login
   ```
   This opens your browser to authenticate with your Google account.

2. **Initialize Firebase in your project:**
   ```bash
   cd c:\Users\mahmu\Safezone\SafeZoneApp
   firebase init
   ```

3. **During `firebase init`, select these features:**
   - ✅ **Realtime Database**
   - ✅ **Firestore**
   - ✅ **Storage**
   - ✅ **Hosting** (optional, for web deployment)

4. **Choose your Firebase project** when prompted (select the SafeZone project)

5. **For Realtime Database:**
   - Choose a location (e.g., us-central1)
   - Start in locked mode (you'll update rules later)

---

### Deploy Firebase Rules via CLI

Once `firebase init` completes, you'll have a `firebase.json` file and rules files.

#### Create `database.rules.json`

After init, edit or create `database.rules.json` in your project root:

```json
{
  "rules": {
    "reports": {
      ".read": true,
      ".write": "auth != null",
      ".indexOn": ["userId", "status", "category", "createdAt"]
    },
    "users": {
      "$userId": {
        ".read": true,
        ".write": "auth != null && auth.uid === $userId"
      }
    }
  }
}
```

#### Update `firestore.rules`

Edit `firestore.rules` (created by `firebase init`):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                                resource.data.userId == request.auth.uid;
    }
  }
}
```

#### Deploy Rules

Deploy all rules at once:

```bash
firebase deploy --only database,firestore,storage
```

Or deploy specific services:

```bash
# Deploy only Realtime Database rules
firebase deploy --only database

# Deploy only Firestore rules
firebase deploy --only firestore

# Deploy only Storage rules
firebase deploy --only storage
```

---

### Verify Deployment

After deploying, check in Firebase Console:

1. Go to **Realtime Database** → **Rules** tab — should show your rules
2. Go to **Firestore** → **Rules** tab — should show your Firestore rules
3. Go to **Storage** → **Rules** tab — should show your Storage rules

---

## Common Issues & Solutions

### Issue: Build failed with "google-services.json not found"
**Solution**: Make sure the file is in `android/app/` directory, not `android/`

### Issue: Google Sign-In not working on Android
**Solution**: 
1. Make sure you added SHA-1 fingerprint in Firebase Console
2. Download the updated `google-services.json` after adding SHA-1
3. Replace the old file and rebuild

### Issue: "Permissions denied" errors in Firestore
**Solution**: Double-check your Firestore security rules match the ones above

### Issue: Camera/Location not working
**Solution**: Make sure you added all permissions to AndroidManifest.xml and Info.plist

### Issue: iOS build fails
**Solution**: 
1. Run `cd ios && pod install`
2. Open Xcode and clean build folder (Shift + Cmd + K)
3. Rebuild

### Issue: Firebase CLI login fails
**Solution**: 
1. Make sure you have a Google account
2. Try `firebase logout` then `firebase login` again
3. If using GitHub Actions or CI/CD, use service account credentials instead

### Issue: `firebase init` doesn't work or hangs
**Solution**: 
1. Make sure you're in the correct project directory
2. Try `firebase init` with `--interactive` flag
3. Check internet connection and firewall settings

### Issue: Rules deployment fails
**Solution**: 
1. Run `firebase deploy --only database,firestore,storage` with `--debug` flag for more info
2. Verify you have proper permissions in the Firebase project
3. Check that your rules files are valid JSON/JavaScript
4. Make sure `.indexOn` syntax is correct (array of strings)

---

## Verification Checklist

- [ ] Firebase project created
- [ ] Android app added with google-services.json
- [ ] iOS app added with GoogleService-Info.plist
- [ ] Google Sign-In enabled in Authentication
- [ ] Firestore database created
- [ ] Realtime Database created
- [ ] Storage enabled
- [ ] Permissions added to Android manifest
- [ ] Permissions added to iOS Info.plist
- [ ] SHA-1 added for Android (for Google Sign-In)
- [ ] Firebase CLI installed and logged in
- [ ] `firebase init` completed with rules files
- [ ] `database.rules.json` configured with indexes
- [ ] `firestore.rules` configured for collections
- [ ] Rules deployed via `firebase deploy`
- [ ] App builds successfully
- [ ] Can sign in with Google
- [ ] Can create and view reports

---

## Next Steps After Setup

1. **Test all features**: Sign in, create reports, view map, edit reports
2. **Add test data**: Create several reports to populate the feed
3. **Customize**: Update app name, package name, and icons
4. **Deploy**: Build release versions for Android/iOS

For questions or issues, refer to:
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
