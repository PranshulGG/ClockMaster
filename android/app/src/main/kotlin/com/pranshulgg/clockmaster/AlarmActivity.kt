package com.pranshulgg.clockmaster

import android.annotation.SuppressLint
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.TypedValue
import android.widget.Button
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.annotation.RequiresApi
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import java.text.SimpleDateFormat
import java.util.Date

class AlarmActivity : ComponentActivity() {
    private var mp: MediaPlayer? = null
    private var vibrateEnabled = false
    private var soundUri: String? = null
    private var alarmId = 0
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)



        window.addFlags(
            android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )


        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }


        setContentView(R.layout.activity_alarm)

        WindowCompat.setDecorFitsSystemWindows(window, true)

        val alarmTimeHour = findViewById<TextView>(R.id.alarm_hour)
        val alarmTimeMinute = findViewById<TextView>(R.id.alarm_minute)
        val screenWidth = resources.displayMetrics.widthPixels
        alarmTimeHour.setTextSize(TypedValue.COMPLEX_UNIT_PX, screenWidth / 2.5f)
        alarmTimeMinute.setTextSize(TypedValue.COMPLEX_UNIT_PX, screenWidth / 2.5f)


        alarmId = intent.getIntExtra("id", 0)
        val label = intent.getStringExtra("label") ?: "Alarm"
        vibrateEnabled = intent.getBooleanExtra("vibrate", false)
        soundUri = intent.getStringExtra("sound")

        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "clockmaster:alarmScreenLock"
        )
        wakeLock?.acquire()

        val prefs = getSharedPreferences("prefs", Context.MODE_PRIVATE)
        val timeFormatPref = prefs.getString("timeFormat", "12 hr") ?: "12 hr"

        val hourPattern = if (timeFormatPref == "24 hr") "HH" else "hh"
        val minutePattern = "mm"

        val hourText = SimpleDateFormat(hourPattern).format(Date())
        val minuteText = SimpleDateFormat(minutePattern).format(Date())

        findViewById<TextView>(R.id.alarm_hour).text = hourText
        findViewById<TextView>(R.id.alarm_minute).text = minuteText


        findViewById<Button>(R.id.btn_dismiss).setOnClickListener {
            stopAlarm()
            finish()
        }
        findViewById<Button>(R.id.btn_snooze).setOnClickListener {
            stopAlarm()
            scheduleSnooze(alarmId, 5)
            finish()
        }

        // Play custom sound
        val uri = soundUri?.let { Uri.parse(it) }
            ?: android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI
        try {
            mp = MediaPlayer().apply {
                setDataSource(this@AlarmActivity, uri)
                setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build())
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) { e.printStackTrace() }

        if (vibrateEnabled) {
            val v = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            val pattern = longArrayOf(0, 500, 500)

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(pattern, 0)
                v.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(pattern, 0)
            }
        }

    }

    private fun stopAlarm() {
        mp?.stop()
        mp?.release()
        mp = null

        if (vibrateEnabled) {
            val v = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            v.cancel()
        }
        wakeLock?.release()
        wakeLock = null

        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(alarmId)
    }

    @SuppressLint("ScheduleExactAlarm")
    @RequiresApi(23)
    private fun scheduleSnooze(id: Int, minutes: Int) {
        val am = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val trigger = System.currentTimeMillis() + minutes * 60 * 1000L
        val alarmIntent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("label", "Snoozed Alarm")
            putExtra("vibrate", vibrateEnabled)
            putExtra("sound", soundUri)
        }
        val pending = android.app.PendingIntent.getBroadcast(
            this, id, alarmIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        am.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, trigger, pending)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
    }
}