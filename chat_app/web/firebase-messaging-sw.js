importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyDb6GMwxxnc4O8Rh7Lw3TCG8jYCm1lui60",
    authDomain: "sociolingo-project.firebaseapp.com",
    projectId: "sociolingo-project",
    storageBucket: "sociolingo-project.appspot.com",
    messagingSenderId: "1065841467151",
    appId: "1:1065841467151:web:df66b762cde6a6ff0b687a",
    databaseURL:
        "https://sociolingo-project-default-rtdb.firebaseio.com/",
    measurementId: "G-D6SLD741Y9",
});
// Necessary to receive background messages:
const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
    console.log("onBackgroundMessage", m);
});