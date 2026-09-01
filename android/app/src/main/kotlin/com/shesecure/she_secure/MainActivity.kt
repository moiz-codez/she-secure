package com.shesecure.she_secure

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Fake Call's scheduled ring needs to show over a locked screen, the same
/// way a real incoming call does. Dart calls "showOverLockScreen" (via
/// this channel) once it sees the fake-call notification's payload — that
/// happens very early (Flutter's engine-attach phase), well before the
/// first frame is composited, so setting these flags then still shows the
/// activity over the lock screen correctly. Any other app launch never
/// calls this, so normal behavior is untouched.
class MainActivity : FlutterActivity() {
    private val channelName = "she_secure/lockscreen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "showOverLockScreen") {
                showOverLockScreen()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }
}
