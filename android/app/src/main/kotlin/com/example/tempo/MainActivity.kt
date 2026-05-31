package com.example.tempo

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.tempo/screen_wake"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
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
                    result.success(true)
                }
                "disable" -> {
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
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
