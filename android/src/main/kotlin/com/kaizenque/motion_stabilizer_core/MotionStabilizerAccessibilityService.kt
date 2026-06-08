package com.kaizenque.motion_stabilizer_core

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

/**
 * Optional convenience: when the user enables "Motion Stabilizer Cues" in the
 * system Accessibility settings, the overlay turns on automatically and stays
 * available across every app — no need to keep the host Flutter app open.
 *
 * The overlay window itself still requires the draw-over-other-apps permission;
 * request it from Dart via [BackgroundOverlayService.requestOverlayPermission].
 */
class MotionStabilizerAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        // Start with sensible defaults; the host app can refine the look at any
        // time through BackgroundOverlayService.updateConfig(...).
        MotionOverlayService.start(applicationContext, OverlayConfig())
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // No per-event work needed; the native overlay is sensor-driven.
    }

    override fun onInterrupt() {}

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        MotionOverlayService.stop(applicationContext)
        return super.onUnbind(intent)
    }
}
