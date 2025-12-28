// Firebase Messaging Service Worker for Flutter Web
// Docs: https://firebase.google.com/docs/cloud-messaging/js/receive

importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// Initialize Firebase using the same config as your app
self.firebaseConfig = {
  apiKey: 'AIzaSyAovBfCU-tH6fOlBGP17Czuh69h5GfM594',
  appId: '1:756814622033:web:189cdb808b71441b4f7770',
  messagingSenderId: '756814622033',
  projectId: 'safezone-44dd0',
  authDomain: 'safezone-44dd0.firebaseapp.com',
  databaseURL: 'https://safezone-44dd0-default-rtdb.firebaseio.com',
  storageBucket: 'safezone-44dd0.firebasestorage.app',
  measurementId: 'G-RZZVX4GCFY',
};

firebase.initializeApp(self.firebaseConfig);

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[Service Worker] Received background message:', payload);
  
  const title = payload.notification?.title || 'SafeZone Notification';
  const options = {
    body: payload.notification?.body || 'New activity in your area',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
    requireInteraction: false,
    tag: payload.data?.reportId || 'safezone-notification',
  };
  
  console.log('[Service Worker] Showing notification:', title, options);
  return self.registration.showNotification(title, options);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[Service Worker] Notification clicked:', event.notification);
  event.notification.close();
  
  const reportId = event.notification.data?.reportId;
  const url = reportId ? `/#/report?id=${reportId}` : '/';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Focus existing window if possible
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus().then(() => {
            if (reportId) {
              client.postMessage({
                type: 'NOTIFICATION_CLICKED',
                reportId: reportId,
              });
            }
          });
        }
      }
      // Otherwise open new window
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});
