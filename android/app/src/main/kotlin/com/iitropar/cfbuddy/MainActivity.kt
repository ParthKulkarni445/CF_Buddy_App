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
      val contestChannel = NotificationChannel(
        "contest_reminders",
        "Contest Reminders",
        NotificationManager.IMPORTANCE_HIGH
      ).apply {
        description = "Notifications about upcoming contests"
      }

      val motivationChannel = NotificationChannel(
        "motivation_channel",
        "Motivation Channel",
        NotificationManager.IMPORTANCE_DEFAULT
      ).apply {
        description = "Daily motivational messages"
      }

      val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
      manager.createNotificationChannel(contestChannel)
      manager.createNotificationChannel(motivationChannel)
    }
  }
}