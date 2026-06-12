package com.kaizenque.motion_sickness_stabilizer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.WindowManager
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.sqrt

/**
 * Foreground service that floats a [MotionCueView] over every other app using a
 * `TYPE_APPLICATION_OVERLAY` window, and feeds it filtered accelerometer data.
 *
 * The overlay is non-touchable, so taps pass straight through to whatever app
 * is underneath.
 */
class MotionOverlayService : Service(), SensorEventListener {

    private lateinit var windowManager: WindowManager
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var cueView: MotionCueView? = null

    private var config = OverlayConfig()

    // Low-pass gravity / linear-acceleration filter (mirrors the Dart side).
    private var gravityX = 0f
    private var gravityY = 0f
    private var gravityZ = SensorManager.STANDARD_GRAVITY
    private var linX = 0f
    private var linY = 0f
    private var smoothedIntensity = 0f
    private var seeded = false
    private var stableRoll = 0f
    private var stablePitch = 0f
    private var angleSeeded = false

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        pendingConfig?.let { config = it }
        startInForeground()
        addOverlay()
        sensorManager.registerListener(
            this,
            accelerometer,
            SensorManager.SENSOR_DELAY_GAME
        )
        instance = this
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        pendingConfig?.let { applyConfig(it) }
        return START_STICKY
    }

    private fun startInForeground() {
        val channelId = "motion_sickness_stabilizer_cues"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                channelId,
                getString(R.string.motion_sickness_stabilizer_notification_channel),
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val notification = builder
            .setContentTitle(getString(R.string.motion_sickness_stabilizer_notification_title))
            .setContentText(getString(R.string.motion_sickness_stabilizer_notification_text))
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun addOverlay() {
        val view = MotionCueView(this, config)
        cueView = view

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        windowManager.addView(view, params)
    }

    fun applyConfig(newConfig: OverlayConfig) {
        config = newConfig
        cueView?.setConfig(newConfig)
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return
        val rx = event.values[0]
        val ry = event.values[1]
        val rz = event.values[2]

        if (!seeded) {
            gravityX = rx; gravityY = ry; gravityZ = rz
            seeded = true
        } else {
            val a = 0.92f
            gravityX = gravityX * a + rx * (1 - a)
            gravityY = gravityY * a + ry * (1 - a)
            gravityZ = gravityZ * a + rz * (1 - a)
        }

        val instX = rx - gravityX
        val instY = ry - gravityY
        val s = 0.78f
        linX = linX * s + instX * (1 - s)
        linY = linY * s + instY * (1 - s)

        // Map device axes to the screen, honouring config transforms.
        var ax = linX
        var ay = linY
        if (config.swapAxes) {
            val t = ax; ax = ay; ay = t
        }
        if (config.invertX) ax = -ax
        if (config.invertY) ay = -ay

        val dx = deadZone(ax, config.activationThreshold) * config.gain
        val dy = -deadZone(ay, config.activationThreshold) * config.gain
        val travel = config.maxTravel
        val offsetX = (-dx).coerceIn(-travel, travel)
        val offsetY = (-dy).coerceIn(-travel, travel)

        val horizontal = sqrt(linX * linX + linY * linY)
        val rawIntensity = mapRange(
            horizontal,
            config.activationThreshold,
            config.maxIntensity,
            0f,
            1f
        )
        smoothedIntensity = smoothedIntensity * 0.8f + rawIntensity * 0.2f

        val roll = atan2(gravityX, gravityZ)
        val pitch = atan2(
            gravityY,
            sqrt(gravityX * gravityX + gravityZ * gravityZ)
        )

        // Heavily smooth the horizon angle so quick shakes don't rotate it.
        val sf = config.horizonStabilization.coerceIn(0f, 0.99f)
        if (!angleSeeded) {
            stableRoll = roll
            stablePitch = pitch
            angleSeeded = true
        } else {
            stableRoll = stableRoll * sf + roll * (1 - sf)
            stablePitch = stablePitch * sf + pitch * (1 - sf)
        }

        cueView?.setMotion(offsetX, offsetY, smoothedIntensity, stableRoll, stablePitch)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        sensorManager.unregisterListener(this)
        cueView?.let {
            try {
                windowManager.removeView(it)
            } catch (_: IllegalArgumentException) {
                // Already removed.
            }
        }
        cueView = null
        instance = null
        isRunning = false
        super.onDestroy()
    }

    private fun deadZone(value: Float, threshold: Float): Float {
        if (abs(value) <= threshold) return 0f
        return if (value > 0) value - threshold else value + threshold
    }

    private fun mapRange(
        value: Float,
        inMin: Float,
        inMax: Float,
        outMin: Float,
        outMax: Float
    ): Float {
        if (inMax == inMin) return outMin
        val t = ((value - inMin) / (inMax - inMin)).coerceIn(0f, 1f)
        return outMin + (outMax - outMin) * t
    }

    companion object {
        private const val NOTIFICATION_ID = 8801

        @Volatile
        var isRunning: Boolean = false
            private set

        private var instance: MotionOverlayService? = null
        private var pendingConfig: OverlayConfig? = null

        fun start(context: Context, config: OverlayConfig) {
            pendingConfig = config
            val running = instance
            if (running != null) {
                running.applyConfig(config)
                return
            }
            val intent = Intent(context, MotionOverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun update(context: Context, config: OverlayConfig) {
            pendingConfig = config
            instance?.applyConfig(config)
        }

        fun stop(context: Context) {
            pendingConfig = null
            context.stopService(Intent(context, MotionOverlayService::class.java))
        }
    }
}
