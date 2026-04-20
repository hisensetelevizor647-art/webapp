package com.oleksandrai.app

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity hosts the Flutter engine and a small MethodChannel bridge for
 * features that need native access:
 *   - openAssistSettings  -> system "Digital assistant app" page
 *   - captureScreenshot   -> one-shot MediaProjection capture via
 *                            [ScreenshotActivity]
 *   - launchApp           -> re-open the task from the overlay
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.oleksandrai.app/assistant"
        var pendingScreenshotResult: MethodChannel.Result? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAssistSettings" -> {
                    openAssistSettings()
                    result.success(null)
                }
                "openOverlaySettings" -> {
                    openOverlaySettings()
                    result.success(null)
                }
                "captureScreenshot" -> {
                    captureScreenshot(result)
                }
                "launchApp" -> {
                    relaunchApp()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // If the user launched the app via the ASSIST intent we just route
        // straight into the normal UI. A production build could additionally
        // broadcast an event so Flutter knows to open the overlay surface.
        val action = intent?.action
        if (action == Intent.ACTION_ASSIST || action == Intent.ACTION_VOICE_COMMAND) {
            // no-op; HomeShell has an explicit button to show the overlay
        }
    }

    private fun openAssistSettings() {
        // Settings.ACTION_VOICE_INPUT_SETTINGS is the most widely supported
        // entry point for picking a default assistant.
        val intent = Intent(Settings.ACTION_VOICE_INPUT_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        try {
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback: global settings
            startActivity(Intent(Settings.ACTION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            })
        }
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        }
    }

    private fun captureScreenshot(result: MethodChannel.Result) {
        pendingScreenshotResult = result
        val i = Intent(this, ScreenshotActivity::class.java)
        i.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(i)
    }

    private fun relaunchApp() {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        if (launch != null) {
            launch.component = ComponentName(this, MainActivity::class.java)
            launch.flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            startActivity(launch)
        }
    }
}
