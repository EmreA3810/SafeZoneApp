# SafeZone Notification Worker

A standalone Node.js service that watches Firebase Realtime Database for new or updated reports and sends FCM notifications to mobile and web clients.

## What this worker does
- Listens to `/reports` in RTDB for new reports and status changes
- Sends FCM topic notifications (category_<name>) for new reports
- Sends direct FCM notifications for report status changes
- Optionally delivers notifications to web users who enabled a category

## Quick start (local)
1) From the project root: `cd notification-worker`
2) Install deps: `npm install`
3) Add your Firebase service account JSON as `serviceAccountKey.json` in this folder
4) Start: `npm start`
5) Watch the console for `SafeZone Notification Worker started`

## Using in another copy of the app
If you duplicate the project elsewhere, repeat these bits in the new location:
- Place a valid `serviceAccountKey.json` in notification-worker/ (never commit it)
- Run `npm install` inside notification-worker/
- Update Firebase URLs/IDs in [worker.js](worker.js#L5-L17) if the new app uses a different Firebase project
- Start with `npm start` (or the provided scripts) and verify it logs that it is monitoring `/reports`

## Setup details

### 1) Firebase service account key
1. Go to Firebase Console → Project Settings → Service accounts
2. Generate new private key
3. Save as `serviceAccountKey.json` in notification-worker/

⚠️ Keep this file secret; it is ignored by Git.

### 2) Configure Firebase project IDs/URLs
Edit [worker.js](worker.js#L5-L17) if you change Firebase projects (databaseURL, etc.).

### 3) Install dependencies
```powershell
cd notification-worker
npm install
```

### 4) Run
```powershell
npm start
```
Expected console output:
```
🚀 SafeZone Notification Worker started
📡 Monitoring /reports for new entries and status changes...
```

### 5) Test
1. Open the app and create a report
2. Console should show a send log for `category_<yourCategory>`
3. Subscribed devices (and eligible web users) get the notification

## Deploying (free-friendly)
- Local only: keep a terminal open while developing
- Render: root=`notification-worker`, build=`npm install`, start=`npm start`, env var `SERVICE_ACCOUNT_KEY` with JSON string
- Railway: root=`notification-worker`, add `serviceAccountKey.json` as file secret or use `SERVICE_ACCOUNT_KEY`
- Fly.io: `fly launch` inside notification-worker/

To use an env var instead of a file, replace in worker.js:
```javascript
const serviceAccount = require('./serviceAccountKey.json');
```
with
```javascript
const serviceAccount = JSON.parse(process.env.SERVICE_ACCOUNT_KEY);
```

## How it works
1. Query `/reports` ordered by `createdAt`, starting at worker start time
2. On `child_added`, sends topic notification and web user notifications (if opted in)
3. On `child_changed`, detects status transitions and sends a direct notification to the report owner
4. Uses `default_channel` Android channel for parity with the app

## Troubleshooting
- "Cannot find module './serviceAccountKey.json'": place the key file or set `SERVICE_ACCOUNT_KEY`
- No notifications: verify RTDB path, ensure tokens exist, confirm topics match `category_<name>`
- Status updates not firing: ensure `status` field actually changes and user has an FCM token in Firestore

## Useful shortcuts (Windows)
- Double-click `start-worker.bat`
- PowerShell: double-click `start-worker.ps1`
- Auto-start on login: `Win + R` → `shell:startup` → copy `start-worker.bat` there
