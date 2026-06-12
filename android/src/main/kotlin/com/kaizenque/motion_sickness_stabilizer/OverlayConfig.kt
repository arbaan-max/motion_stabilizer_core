package com.kaizenque.motion_sickness_stabilizer

/**
 * Native mirror of the Dart `MotionCueConfig`. Values arrive across the method
 * channel as a plain map; distances are in *logical* pixels and are scaled by
 * the display density when the view draws.
 */
data class OverlayConfig(
    // Bubbles (dots).
    val showDots: Boolean = true,
    val dotColor: Int = 0xFFFFFFFF.toInt(),
    val dotRadius: Float = 5f,
    val dotSpacing: Float = 56f,
    val placement: Int = 0, // 0 edges, 1 fullScreen, 2 sides, 3 center
    val dotShape: Int = 0, // 0 circle, 1 ring, 2 square, 3 diamond
    val dotBaseOpacity: Float = 0.32f,
    val dotMaxOpacity: Float = 0.9f,
    val dotReactToMotionOpacity: Boolean = true,
    val dotSizeJitter: Float = 0f,
    val dotGlow: Boolean = false,
    // Motion response.
    val gain: Float = 16f,
    val maxTravel: Float = 28f,
    val activationThreshold: Float = 0.25f,
    val maxIntensity: Float = 4f,
    val invertX: Boolean = false,
    val invertY: Boolean = false,
    val swapAxes: Boolean = false,
    // Divider / horizon.
    val dividerStyle: Int = 1, // 0 none,1 line,2 wavy,3 dashed,4 dualRail,5 filledHorizon,6 gradientBand
    val dividerColor: Int = 0xFFFFFFFF.toInt(),
    val dividerThickness: Float = 2.5f,
    val dividerOpacity: Float = 0.5f,
    val horizonFillColor: Int = 0x3340C4FF,
    val waveAmplitude: Float = 8f,
    val waveWavelength: Float = 140f,
    val waveSpeed: Float = 0.35f,
    val waveAnimated: Boolean = true,
    val waveReactsToMotion: Boolean = true,
    val levelWithHorizon: Boolean = true,
    val horizonStabilization: Float = 0.85f,
    // Focus dot.
    val showFocusDot: Boolean = false,
    val focusDotColor: Int = 0xFFFFFFFF.toInt(),
    val focusDotRadius: Float = 6f,
    val focusDotHaloRadius: Float = 18f,
    val focusDotHaloColor: Int = 0x33FFFFFF
) {
    companion object {
        fun fromMap(map: Map<*, *>?): OverlayConfig {
            if (map == null) return OverlayConfig()
            fun f(key: String, def: Float): Float =
                (map[key] as? Number)?.toFloat() ?: def
            fun i(key: String, def: Int): Int =
                (map[key] as? Number)?.toInt() ?: def
            fun b(key: String, def: Boolean): Boolean =
                (map[key] as? Boolean) ?: def
            return OverlayConfig(
                showDots = b("showDots", true),
                dotColor = i("dotColor", 0xFFFFFFFF.toInt()),
                dotRadius = f("dotRadius", 5f),
                dotSpacing = f("dotSpacing", 56f),
                placement = i("placement", 0),
                dotShape = i("dotShape", 0),
                dotBaseOpacity = f("dotBaseOpacity", 0.32f),
                dotMaxOpacity = f("dotMaxOpacity", 0.9f),
                dotReactToMotionOpacity = b("dotReactToMotionOpacity", true),
                dotSizeJitter = f("dotSizeJitter", 0f),
                dotGlow = b("dotGlow", false),
                gain = f("gain", 16f),
                maxTravel = f("maxTravel", 28f),
                activationThreshold = f("activationThreshold", 0.25f),
                maxIntensity = f("maxIntensity", 4f),
                invertX = b("invertX", false),
                invertY = b("invertY", false),
                swapAxes = b("swapAxes", false),
                dividerStyle = i("dividerStyle", 1),
                dividerColor = i("dividerColor", 0xFFFFFFFF.toInt()),
                dividerThickness = f("dividerThickness", 2.5f),
                dividerOpacity = f("dividerOpacity", 0.5f),
                horizonFillColor = i("horizonFillColor", 0x3340C4FF),
                waveAmplitude = f("waveAmplitude", 8f),
                waveWavelength = f("waveWavelength", 140f),
                waveSpeed = f("waveSpeed", 0.35f),
                waveAnimated = b("waveAnimated", true),
                waveReactsToMotion = b("waveReactsToMotion", true),
                levelWithHorizon = b("levelWithHorizon", true),
                horizonStabilization = f("horizonStabilization", 0.85f),
                showFocusDot = b("showFocusDot", false),
                focusDotColor = i("focusDotColor", 0xFFFFFFFF.toInt()),
                focusDotRadius = f("focusDotRadius", 6f),
                focusDotHaloRadius = f("focusDotHaloRadius", 18f),
                focusDotHaloColor = i("focusDotHaloColor", 0x33FFFFFF)
            )
        }
    }
}
