// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAP-QrOX_amyaCy9A7i-3UYGTLT94mkgHI",
  authDomain: "shivayscreation-new.firebaseapp.com",
  projectId: "shivayscreation-new",
  messagingSenderId: "492835221543",
  appId: "1:492835221543:web:acd713d549a5aaf5cf5e02"
});

const messaging = firebase.messaging();
