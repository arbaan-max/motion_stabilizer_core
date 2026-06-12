package com.kaizenque.motion_sickness_stabilizer

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Method-channel entry point. Bridges the Dart [BackgroundOverlayService] to the
 * native [MotionOverlayService] foreground overlay.
 */
class MotionSicknessStabilizerPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "hasOverlayPermission" -> result.success(canDrawOverlays())

            "requestOverlayPermission" -> {
                if (!canDrawOverlays()) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:" + appContext.packageName)
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    appContext.startActivity(intent)
                }
                result.success(null)
            }

            "startOverlay" -> {
                if (!canDrawOverlays()) {
                    result.success(false)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val config = OverlayConfig.fromMap(call.arguments as? Map<*, *>)
                MotionOverlayService.start(appContext, config)
                result.success(true)
            }

            "updateConfig" -> {
                @Suppress("UNCHECKED_CAST")
                val config = OverlayConfig.fromMap(call.arguments as? Map<*, *>)
                MotionOverlayService.update(appContext, config)
                result.success(null)
            }

            "stopOverlay" -> {
                MotionOverlayService.stop(appContext)
                result.success(null)
            }

            "isOverlayRunning" -> result.success(MotionOverlayService.isRunning)

            else -> result.notImplemented()
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(appContext)
        } else {
            true
        }
    }

    companion object {
        private const val CHANNEL = "motion_sickness_stabilizer/overlay"
    }
}
