const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK with service account
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://safezone-44dd0-default-rtdb.firebaseio.com',
});

const db = admin.database();
const firestore = admin.firestore();

// Define a small grace window to account for slight clock skews
const GRACE_MS = parseInt(process.env.WORKER_START_GRACE_MS || '5000', 10);
const workerStartedAt = Date.now();
const workerStartIso = new Date(workerStartedAt - GRACE_MS).toISOString();

// Query only reports created at or after worker start time
const reportsQuery = db
  .ref('/reports')
  .orderByChild('createdAt')
  .startAt(workerStartIso);

console.log('🚀 SafeZone Notification Worker started');
console.log(`⏱️  Worker start cutoff: ${workerStartIso}`);
console.log('📡 Monitoring /reports for new entries and status changes...\n');

// Helper function to send notifications to web users based on preferences
async function sendToWebUsers(category, title, body, reportId, userName, userId) {
  try {
    // Query Firestore for web users (without compound index requirement)
    const usersSnapshot = await firestore
      .collection('users')
      .where('fcmTokenPlatform', '==', 'web')
      .get();

    if (usersSnapshot.empty) {
      return;
    }

    const webNotifications = [];

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userFcmToken = userData.fcmToken;
      
      // Skip if no valid token
      if (!userFcmToken) {
        continue;
      }
      
      const userPrefs = userData.notificationPreferences || {};

      // Skip if user is the report creator
      if (userDoc.id === userId) {
        continue;
      }

      // Check if user wants notifications for this category
      if (userPrefs[category] === true) {
        webNotifications.push({
          token: userFcmToken,
          notification: { title, body },
          data: {
            reportId: reportId,
            category: category,
            userName: userName,
            userId: userId,
          },
          webpush: {
            headers: {
              Urgency: 'high',
            },
            notification: {
              icon: '/icons/Icon-192.png',
              badge: '/icons/Icon-192.png',
            },
          },
        });
      }
    }

    if (webNotifications.length > 0) {
      // Send in batches
      await Promise.allSettled(
        webNotifications.map(msg => admin.messaging().send(msg))
      );
    }
  } catch (err) {
    console.error(`❌ Failed to send web notifications:`, err.message);
  }
}

// Track processed report IDs to avoid duplicates on restart
const processedReports = new Set();
const lastStatusByReport = new Map();

// Listen for new child additions to /reports
reportsQuery.on('child_added', async (snapshot) => {
  const reportId = snapshot.key;
  
  // Skip if already processed
  if (processedReports.has(reportId)) {
    return;
  }
  
  processedReports.add(reportId);
  
  const data = snapshot.val() || {};
  // Guard against pre-existing items missing createdAt or older than cutoff
  const createdAtStr = (data.createdAt || '').toString();
  if (!createdAtStr) {
    // No createdAt - treat as legacy/old; skip
    return;
  }
  try {
    const createdAtMs = Date.parse(createdAtStr);
    if (Number.isFinite(createdAtMs) && createdAtMs < workerStartedAt - GRACE_MS) {
      return;
    }
  } catch (_) {
    // If parsing fails, skip to avoid false positives
    return;
  }
  const category = (data.category || 'other').toString();
  const title = (data.title || 'New Report').toString();
  const userName = (data.userName || 'Someone').toString();
  const userId = (data.userId || '').toString();
  const description = (data.description || '').toString();
  const locationAddress = (data.locationAddress || '').toString();
  const createdAt = createdAtStr || new Date().toISOString();

  const topic = `category_${category}`;

  // Build notification body
  const bodyParts = [userName];
  if (locationAddress) bodyParts.push(`@ ${locationAddress}`);
  if (description) bodyParts.push(`- ${description.substring(0, 120)}`);
  const body = bodyParts.join(' ');

  const message = {
    topic,
    notification: {
      title,
      body,
    },
    data: {
      reportId: reportId,
      category: category,
      userName: userName,
      userId: userId,
    },
    android: {
      notification: {
        channelId: 'default_channel',
        priority: 'high',
      },
    },
  };

  try {
    await admin.messaging().send(message);
    // Track initial status for future change detection
    if (data.status) {
      lastStatusByReport.set(reportId, (data.status || 'pending').toString());
    }
  } catch (err) {
    console.error(`❌ Failed to send notification for report ${reportId}:`, err.message);
  }

  // Send to web users who have this category enabled in preferences
  await sendToWebUsers(category, title, body, reportId, userName, userId);
});

// Listen for status changes on existing reports
db.ref('/reports').on('child_changed', async (snapshot) => {
  const reportId = snapshot.key;
  const data = snapshot.val() || {};
  
  const status = (data.status || 'pending').toString();
  const title = (data.title || 'Your Report').toString();
  const userId = (data.userId || '').toString();
  const category = (data.category || 'other').toString();

  console.log(`📋 Status change detected for report ${reportId}: ${status}`);

  // Seed baseline for reports we haven't seen yet, then skip once
  if (!lastStatusByReport.has(reportId)) {
    console.log(`   First time seeing this report, setting baseline status: ${status}`);
    lastStatusByReport.set(reportId, status);
    return;
  }
  // Only notify when status actually changes
  const prevStatus = lastStatusByReport.get(reportId);
  if (prevStatus === status) {
    console.log(`   Status same as before (${status}), skipping notification`);
    return;
  }
  console.log(`   Status changed from ${prevStatus} to ${status}, sending notification`);
  lastStatusByReport.set(reportId, status);

  if (!userId) {
    console.log(`   No userId, skipping notification`);
    return;
  }

  // Get user's FCM token from Firestore
  let fcmToken = null;
  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      fcmToken = userDoc.data().fcmToken;
      console.log(`   Found FCM token for user ${userId}`);
    } else {
      console.log(`   User doc not found for ${userId}`);
    }
  } catch (err) {
    console.error(`❌ Failed to fetch FCM token for user ${userId}:`, err.message);
    return;
  }

  if (!fcmToken) {
    console.log(`   No FCM token for user ${userId}`);
    return;
  }

  // Build status-specific notification
  const statusDisplayNames = {
    pending: 'Pending Review',
    approved: 'Approved',
    inProgress: 'In Progress',
    resolved: 'Resolved',
    rejected: 'Rejected',
  };
  
  const statusName = statusDisplayNames[status] || status;
  const notificationTitle = `Report Status: ${statusName}`;
  const notificationBody = `Your report "${title}" is now ${statusName.toLowerCase()}`;

  const message = {
    token: fcmToken,
    notification: {
      title: notificationTitle,
      body: notificationBody,
    },
    data: {
      reportId: reportId,
      status: status,
      category: category,
      userId: userId,
      type: 'status_update',
    },
    android: {
      notification: {
        channelId: 'default_channel',
        priority: 'high',
      },
    },
  };

  try {
    await admin.messaging().send(message);
    console.log(`✅ Status notification sent to user ${userId} for report ${reportId}`);
  } catch (err) {
    console.error(`❌ Failed to send status notification:`, err.message);
  }
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\n🛑 Shutting down notification worker...');
  reportsQuery.off();
  db.ref('/reports').off();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n🛑 Shutting down notification worker...');
  reportsQuery.off();
  db.ref('/reports').off();
  process.exit(0);
});
