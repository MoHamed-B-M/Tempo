package com.example.tempo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device booted — setting reschedule flag")
            val prefs: SharedPreferences =
                context.getSharedPreferences("tempo_boot", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("boot_completed", true).apply()
        }
    }
}
