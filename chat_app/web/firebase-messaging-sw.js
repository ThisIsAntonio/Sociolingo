importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
        apiKey: "put your api key",
        authDomain: "put your auth domain",
        projectId: "put your project id",
        storageBucket: "put your storage bucket",
        messagingSenderId: "put your messaging sender id",
        appId: "put your app id",
        databaseURL: "put your database url",
        measurementId: "put your measurement id"
});

// Necessary to receive background messages:
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
    console.log('Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: 'icons/logo.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});