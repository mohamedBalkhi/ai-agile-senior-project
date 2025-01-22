package com.agilemeets.mobile

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "screen_capture_service"
        private const val SCREEN_CAPTURE_REQUEST_CODE = 1001
    }

    private var screenCapturePendingResult: MethodChannel.Result? = null
    private var methodChannel: MethodChannel? = null
    private var isChannelInitialized = false

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        if (!isChannelInitialized) {
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    // ---- SINGLE ENTRY POINT FOR SCREEN CAPTURE PERMISSION ----
                    "startScreenCapture" -> {
                        screenCapturePendingResult = result
                        val mgr = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        startActivityForResult(mgr.createScreenCaptureIntent(), SCREEN_CAPTURE_REQUEST_CODE)
                    }

                    // Stop the foreground service without re‐requesting permission
                    "stopScreenCaptureService" -> {
                        val serviceIntent = Intent(this, ScreenCaptureService::class.java)
                        stopService(serviceIntent)
                        result.success(null)
                    }

                    // Toggle wake lock
                    "keepScreenOn" -> {
                        val keepOn = call.arguments as Boolean
                        if (keepOn) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
            isChannelInitialized = true
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SCREEN_CAPTURE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Start the foreground service with user-granted data
                val serviceIntent = Intent(this, ScreenCaptureService::class.java).apply {
                    action = "START_CAPTURE"
                    putExtra("resultCode", resultCode)
                    putExtra("data", data)
                }
                startForegroundService(serviceIntent)

                // Return success info back to Flutter
                screenCapturePendingResult?.success(
                    mapOf(
                        "resultCode" to resultCode,
                        "data" to data.toUri(Intent.URI_INTENT_SCHEME)
                    )
                )
            } else {
                screenCapturePendingResult?.error(
                    "PERMISSION_DENIED",
                    "Screen capture permission denied",
                    null
                )
            }
            screenCapturePendingResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        // Forward permission results to Flutter plugins
        flutterEngine?.activityControlSurface?.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )
    }
}
