package com.shivayscreation;

import android.util.Log;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class MyFirebaseMessagingService extends FirebaseMessagingService {

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);
        // Handle FCM messages here
        Log.d("FCM", "Message received: " + remoteMessage.getData());
    }

    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        // Handle token refresh
        Log.d("FCM", "New token: " + token);
    }
}
