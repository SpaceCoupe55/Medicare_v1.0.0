// Firebase Cloud Messaging service worker — handles background push notifications.
// Must stay at /firebase-messaging-sw.js (served from web root).

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'AIzaSyDPNYfTi3q1r0JSR6UUyaSJIEBgyMUc1aw',
  authDomain:        'medicare-admin-b7266.firebaseapp.com',
  projectId:         'medicare-admin-b7266',
  storageBucket:     'medicare-admin-b7266.firebasestorage.app',
  messagingSenderId: '636213838433',
  appId:             '1:636213838433:web:d3bd8c89deb97c13652020',
});

const messaging = firebase.messaging();

// Handle background messages (app is closed or in background tab).
messaging.onBackgroundMessage((payload) => {
  const { title = 'Medicare', body = '' } = payload.notification ?? {};
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
  });
});
