import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

    initFCM ()async{
        await _firebaseMessaging.requestPermission();

        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
            print("FCM Token: $token");
        } else {
            print("Failed to get FCM token");
        }

        await _firebaseMessaging.subscribeToTopic('contest-reminders');

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            print("onMessage: ${message.notification?.title} - ${message.notification?.body}");
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            print("onMessageOpenedApp: ${message.notification?.title} - ${message.notification?.body}");
        });

    }
}