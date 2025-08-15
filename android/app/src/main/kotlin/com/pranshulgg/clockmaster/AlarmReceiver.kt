package com.pranshulgg.clockmaster

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val CHANNEL_ID = "alarm_channel"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        val label = intent.getStringExtra("label") ?: "Alarm"
        val vibrate = intent.getBooleanExtra("vibrate", false)
        val sound = intent.getStringExtra("sound")


        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
        val isLocked = keyguardManager.isKeyguardLocked

        if (isLocked) {

            val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("id", id)
                putExtra("label", label)
                putExtra("vibrate", vibrate)
                putExtra("sound", sound)
            }

            val fullScreenPendingIntent = PendingIntent.getActivity(
                context,
                id,
                alarmIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager


            val channelId = "alarm_channel_locked"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "Alarms Locked",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alarm notifications on lock screen"
                    enableVibration(vibrate)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    setSound(null, null)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val notificationBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, channelId)
            } else {
                Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
            }

            val notification = notificationBuilder
                .setSmallIcon(R.drawable.baseline_timer_24)
                .setContentTitle(label)
                .setContentText("Alarm is ringing")
                .setCategory(Notification.CATEGORY_ALARM)
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .setAutoCancel(true)
                .setOngoing(true)
                .build()

            notificationManager.notify(id, notification)

        } else {

            val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
                putExtra("id", id)
                putExtra("label", label)
                putExtra("vibrate", vibrate)
                putExtra("sound", sound)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
//        val id = intent.getIntExtra("id", 0)
//        val label = intent.getStringExtra("label") ?: "Alarm"
//        val vibrate = intent.getBooleanExtra("vibrate", false)
//        val sound = intent.getStringExtra("sound")
//
//        val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
//            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
//            putExtra("id", id)
//            putExtra("label", label)
//            putExtra("vibrate", vibrate)
//            putExtra("sound", sound)
//        }
//
//        val fullScreenPendingIntent = PendingIntent.getActivity(
//            context,
//            id,
//            alarmIntent,
//            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
//        )
//
//        val notificationManager =
//            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
//
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            val channel = NotificationChannel(
//                CHANNEL_ID,
//                "Alarm Notifications",
//                NotificationManager.IMPORTANCE_HIGH
//            ).apply {
//                description = "Channel for Alarm notifications"
//                enableVibration(vibrate)
//                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
//                setSound(null, null)
//            }
//            notificationManager.createNotificationChannel(channel)
//        }
//
//        // Create PendingIntent for Snooze action
//        val snoozeIntent = Intent(context, AlarmActionReceiver::class.java).apply {
//            action = "ACTION_SNOOZE"
//            putExtra("id", id)
//            putExtra("vibrate", vibrate)
//            putExtra("sound", sound)
//            putExtra("label", label)
//        }
//        val snoozePendingIntent = PendingIntent.getBroadcast(
//            context,
//            id + 1000,  // unique request code to differentiate from others
//            snoozeIntent,
//            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
//        )
//
//        // Create PendingIntent for Stop action
//        val stopIntent = Intent(context, AlarmActionReceiver::class.java).apply {
//            action = "ACTION_STOP"
//            putExtra("id", id)
//        }
//        val stopPendingIntent = PendingIntent.getBroadcast(
//            context,
//            id + 2000,
//            stopIntent,
//            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
//        )
//
//        val notificationBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            Notification.Builder(context, CHANNEL_ID)
//        } else {
//            Notification.Builder(context)
//                .setPriority(Notification.PRIORITY_HIGH)
//        }
//
//        val notification = notificationBuilder
//            .setSmallIcon(R.drawable.baseline_timer_24)
//            .setContentTitle(label)
//            .setContentText("Alarm is ringing")
//            .setCategory(Notification.CATEGORY_ALARM)
//            .setFullScreenIntent(fullScreenPendingIntent, true)
//            .addAction(android.R.drawable.ic_lock_idle_alarm, "Snooze", snoozePendingIntent)
//            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
//            .setAutoCancel(true)
//            .setOngoing(true)
//            .build()
//
//        notificationManager.notify(id, notification)
//    }

}
