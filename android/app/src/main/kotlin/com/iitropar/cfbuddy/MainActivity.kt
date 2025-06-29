package com.iitropar.cfbuddy

import android.os.Bundle 
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        "contest_reminders",               // must match channelId
        "Contest Reminders",
        NotificationManager.IMPORTANCE_HIGH
      ).apply {
        description = "Notifications about upcoming contests"
      }
      (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
        .createNotificationChannel(channel)
    }
  }
}