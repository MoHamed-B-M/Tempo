package com.example.tempo

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.tempo/screen_wake"
    private val FG_CHANNEL = "com.example.tempo/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    setWakeFlags(true)
                    result.success(true)
                }
                "disable" -> {
                    setWakeFlags(false)
                    result.success(true)
                }
                "launchAlarmActivity" -> {
                    launchAlarmActivity()
                    result.success(true)
                }
                "requestFullScreenIntentPermission" -> {
                    val granted = requestFullScreenIntentPermission()
                    result.success(granted)
                }
                "requestExactAlarmPermission" -> {
                    val granted = requestExactAlarmPermission()
                    result.success(granted)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FG_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    AlarmForegroundService.start(this)
                    result.success(true)
                }
                "stop" -> {
                    AlarmForegroundService.stop(this)
                    result.success(true)
                }
                "isRunning" -> {
                    result.success(isForegroundServiceRunning())
                }
                "bootCompleted" -> {
                    val prefs = getSharedPreferences("tempo_boot", Context.MODE_PRIVATE)
                    val flag = prefs.getBoolean("boot_completed", false)
                    if (flag) {
                        prefs.edit().putBoolean("boot_completed", false).apply()
                    }
                    result.success(flag)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isForegroundServiceRunning(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (AlarmForegroundService::class.java.name == service.service.className) {
                return true
            }
        }
        return false
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        setWakeFlags(true)
    }

    private fun setWakeFlags(enable: Boolean) {
        if (enable) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            } else {
                @Suppress("DEPRECATION")
                window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
                @Suppress("DEPRECATION")
                window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            }
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setShowWhenLocked(false)
                setTurnScreenOn(false)
            } else {
                @Suppress("DEPRECATION")
                window.clearFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
                @Suppress("DEPRECATION")
                window.clearFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            }
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun launchAlarmActivity() {
        val intent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            action = "com.example.tempo.ALARM_FULL_SCREEN"
        }
        startActivity(intent)
    }

    private fun requestFullScreenIntentPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            return notificationManager.areNotificationsEnabled()
        }
        return true
    }

    private fun requestExactAlarmPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            return alarmManager.canScheduleExactAlarms()
        }
        return true
    }
}
