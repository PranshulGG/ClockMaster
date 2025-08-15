package com.pranshulgg.clockmaster

import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmActionReceiver : BroadcastReceiver() {
    @SuppressLint("ScheduleExactAlarm")
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("id", 0)
        val action = intent.action ?: return

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        when (action) {
            "ACTION_SNOOZE" -> {
                val vibrate = intent.getBooleanExtra("vibrate", false)
                val label = intent.getStringExtra("label") ?: "Snoozed Alarm"
                val sound = intent.getStringExtra("sound")

                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val trigger = System.currentTimeMillis() + 5 * 60 * 1000L

                val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
                    putExtra("id", alarmId)
                    putExtra("label", label)
                    putExtra("vibrate", vibrate)
                    putExtra("sound", sound)
                }
                val pending = PendingIntent.getBroadcast(
                    context,
                    alarmId,
                    alarmIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
                } else {
                    am.setExact(AlarmManager.RTC_WAKEUP, trigger, pending)
                }

                notificationManager.cancel(alarmId)
            }

            "ACTION_STOP" -> {
                notificationManager.cancel(alarmId)
            }
        }
    }
}
