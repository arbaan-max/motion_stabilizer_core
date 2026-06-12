package com.kaizenque.motion_sickness_stabilizer

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Shader
import android.os.SystemClock
import android.view.Choreographer
import android.view.View
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Draws the motion-sickness UI inside the system overlay window: the bubble
 * field, the Earth-stable divider (in any style) and the focus dot. Mirrors the
 * Dart rendering so the overlay looks identical to the in-app layer.
 *
 * Distances in [OverlayConfig] are logical pixels and are scaled here by the
 * display density. A [Choreographer] frame loop keeps wavy/filled styles
 * animating smoothly even when the device is still.
 */
@SuppressLint("ViewConstructor")
class MotionCueView(context: Context, private var config: OverlayConfig) :
    View(context), Choreographer.FrameCallback {

    private val density = resources.displayMetrics.density
    private val startMs = SystemClock.uptimeMillis()

    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
    }

    // Driven by the service from sensor data.
    private var offsetX = 0f // logical px
    private var offsetY = 0f // logical px
    private var intensity = 0f // [0, 1]
    private var roll = 0f // radians
    private var pitch = 0f // radians

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        Choreographer.getInstance().postFrameCallback(this)
    }

    override fun onDetachedFromWindow() {
        Choreographer.getInstance().removeFrameCallback(this)
        super.onDetachedFromWindow()
    }

    override fun doFrame(frameTimeNanos: Long) {
        invalidate()
        Choreographer.getInstance().postFrameCallback(this)
    }

    fun setConfig(newConfig: OverlayConfig) {
        config = newConfig
        invalidate()
    }

    fun setMotion(
        offsetXLp: Float,
        offsetYLp: Float,
        intensity: Float,
        roll: Float,
        pitch: Float
    ) {
        this.offsetX = offsetXLp
        this.offsetY = offsetYLp
        this.intensity = intensity
        this.roll = roll
        this.pitch = pitch
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        drawDivider(canvas)
        if (config.showDots) drawDots(canvas)
        if (config.showFocusDot) drawFocusDot(canvas)
    }

    // ---------------------------------------------------------------------- //
    // Dots
    // ---------------------------------------------------------------------- //

    private val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }

    private fun drawDots(canvas: Canvas) {
        val opacity = if (config.dotReactToMotionOpacity) {
            config.dotBaseOpacity +
                (config.dotMaxOpacity - config.dotBaseOpacity) * intensity
        } else {
            config.dotBaseOpacity
        }
        if (opacity <= 0.01f) return

        val spacing = config.dotSpacing * density
        val radius = config.dotRadius * density
        if (spacing <= 0f) return

        val ring = config.dotShape == 1
        fillPaint.style = if (ring) Paint.Style.STROKE else Paint.Style.FILL
        if (ring) fillPaint.strokeWidth = radius * 0.45f
        fillPaint.color = applyAlpha(config.dotColor, opacity)

        val glow = config.dotGlow
        if (glow) {
            glowPaint.color = applyAlpha(config.dotColor, opacity * 0.45f)
            glowPaint.maskFilter = BlurMaskFilter(radius, BlurMaskFilter.Blur.NORMAL)
        }

        val dx = offsetX * density
        val dy = offsetY * density
        val cols = ceil(width / spacing).toInt() + 2
        val rows = ceil(height / spacing).toInt() + 2

        for (r in 0 until rows) {
            for (c in 0 until cols) {
                val baseX = (c - 1) * spacing + spacing / 2f
                val baseY = (r - 1) * spacing + spacing / 2f
                if (!isDotVisible(baseX, baseY)) continue
                val rr = radius * sizeFactor(r, c)
                val cx = baseX + dx
                val cy = baseY + dy
                if (glow) canvas.drawCircle(cx, cy, rr * 1.2f, glowPaint)
                drawDotShape(canvas, cx, cy, rr)
            }
        }
        fillPaint.style = Paint.Style.FILL
    }

    private fun drawDotShape(canvas: Canvas, cx: Float, cy: Float, r: Float) {
        when (config.dotShape) {
            2 -> canvas.drawRect(cx - r, cy - r, cx + r, cy + r, fillPaint) // square
            3 -> { // diamond
                val path = Path()
                path.moveTo(cx, cy - r)
                path.lineTo(cx + r, cy)
                path.lineTo(cx, cy + r)
                path.lineTo(cx - r, cy)
                path.close()
                canvas.drawPath(path, fillPaint)
            }
            else -> canvas.drawCircle(cx, cy, r, fillPaint) // circle / ring
        }
    }

    private fun sizeFactor(r: Int, c: Int): Float {
        if (config.dotSizeJitter <= 0f) return 1f
        var h = (r * 73856093) xor (c * 19349663)
        h = h and 0x7fffffff
        val unit = (h % 1000) / 1000f
        return 1f + (unit * 2 - 1) * config.dotSizeJitter
    }

    private fun isDotVisible(x: Float, y: Float): Boolean {
        return when (config.placement) {
            1 -> true // fullScreen
            2 -> { // sides
                val band = width * 0.22f
                x < band || x > width - band
            }
            3 -> { // center
                val dx = kotlin.math.abs(x - width / 2f)
                val dy = kotlin.math.abs(y - height / 2f)
                dx < width * 0.3f && dy < height * 0.22f
            }
            else -> { // edges
                val hBand = width * 0.22f
                val vBand = height * 0.16f
                val nearSide = x < hBand || x > width - hBand
                val nearTopBottom = y < vBand || y > height - vBand
                nearSide || nearTopBottom
            }
        }
    }

    // ---------------------------------------------------------------------- //
    // Divider
    // ---------------------------------------------------------------------- //

    private fun drawDivider(canvas: Canvas) {
        if (config.dividerStyle == 0) return
        if (config.dividerOpacity <= 0.01f) return

        val cx = width / 2f
        val cy = height / 2f
        val pitchShift = (pitch / (Math.PI.toFloat() / 2f)) * (height / 4f)
        val half = max(width, height).toFloat()

        canvas.save()
        canvas.translate(cx, cy + pitchShift)
        if (config.levelWithHorizon) {
            canvas.rotate(Math.toDegrees(-roll.toDouble()).toFloat())
        }

        strokePaint.color = applyAlpha(config.dividerColor, config.dividerOpacity)
        strokePaint.strokeWidth = config.dividerThickness * density

        when (config.dividerStyle) {
            1 -> drawStraight(canvas, half)
            3 -> drawDashed(canvas, half)
            2 -> drawWavy(canvas, half, fill = false)
            5 -> drawWavy(canvas, half, fill = true)
            4 -> drawDualRail(canvas, half)
            6 -> drawGradientBand(canvas, half)
        }

        canvas.restore()
    }

    private fun drawStraight(canvas: Canvas, half: Float) {
        val glow = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            color = applyAlpha(config.dividerColor, config.dividerOpacity * 0.4f)
            strokeWidth = config.dividerThickness * density * 3
        }
        canvas.drawLine(-half, 0f, half, 0f, glow)
        canvas.drawLine(-half, 0f, half, 0f, strokePaint)
        drawCentreTick(canvas)
    }

    private fun drawDashed(canvas: Canvas, half: Float) {
        val dash = 16f * density
        val gap = 12f * density
        var x = -half
        while (x < half) {
            canvas.drawLine(x, 0f, x + dash, 0f, strokePaint)
            x += dash + gap
        }
        drawCentreTick(canvas)
    }

    private fun waveY(x: Float, amp: Float, wl: Float): Float {
        val twoPi = (2 * Math.PI).toFloat()
        val reacts = config.waveReactsToMotion
        val phaseCycles =
            if (config.waveAnimated) {
                (SystemClock.uptimeMillis() - startMs) / 1000f * config.waveSpeed
            } else 0f
        val p = phaseCycles * twoPi
        val sway = if (reacts) offsetX * density * 0.04f else 0f
        val bob = if (reacts) offsetY * density * 0.35f else 0f
        val a = if (reacts) amp * (1 + intensity * 1.5f) else amp
        val primary = sin((x / wl) * twoPi + p + sway) * a
        val ripple = sin((x / (wl * 0.5f)) * twoPi - p * 1.7f) * a * 0.45f
        return primary + ripple + bob
    }

    private fun drawWavy(canvas: Canvas, half: Float, fill: Boolean) {
        val amp = (if (fill) min(config.waveAmplitude, 9f) else config.waveAmplitude) * density
        val wl = (if (config.waveWavelength <= 0f) 140f else config.waveWavelength) * density

        val path = Path()
        val step = 5f * density
        var x = -half
        var first = true
        while (x <= half) {
            val y = waveY(x, amp, wl)
            if (first) {
                path.moveTo(x, y); first = false
            } else {
                path.lineTo(x, y)
            }
            x += step
        }

        if (fill) {
            val fillPath = Path(path)
            fillPath.lineTo(half, half)
            fillPath.lineTo(-half, half)
            fillPath.close()
            fillPaint.color = applyAlpha(config.horizonFillColor, config.dividerOpacity)
            canvas.drawPath(fillPath, fillPaint)
        }
        canvas.drawPath(path, strokePaint)
    }

    private fun drawDualRail(canvas: Canvas, half: Float) {
        val nearGap = 0.32f
        val farGap = 0.06f
        canvas.drawLine(-half * nearGap, half, -half * farGap, -half, strokePaint)
        canvas.drawLine(half * nearGap, half, half * farGap, -half, strokePaint)
        for (i in 1..4) {
            val t = i / 5f
            val y = half - t * 2 * half
            val gap = (nearGap + (farGap - nearGap) * t) * half
            val tie = Paint(strokePaint)
            tie.strokeWidth = config.dividerThickness * density * (1 - t * 0.6f)
            canvas.drawLine(-gap, y, gap, y, tie)
        }
    }

    private fun drawGradientBand(canvas: Canvas, half: Float) {
        val bandHalf = max(config.waveAmplitude * 4f, 48f) * density
        val base = applyAlpha(config.dividerColor, config.dividerOpacity)
        val transparent = base and 0x00FFFFFF
        val shader = LinearGradient(
            0f, -bandHalf, 0f, bandHalf,
            intArrayOf(transparent, base, transparent),
            floatArrayOf(0f, 0.5f, 1f),
            Shader.TileMode.CLAMP
        )
        val bandPaint = Paint().apply { this.shader = shader }
        canvas.drawRect(-half, -bandHalf, half, bandHalf, bandPaint)
        canvas.drawLine(-half, 0f, half, 0f, strokePaint)
    }

    private fun drawCentreTick(canvas: Canvas) {
        canvas.drawLine(0f, -8f * density, 0f, 8f * density, strokePaint)
    }

    // ---------------------------------------------------------------------- //
    // Focus dot
    // ---------------------------------------------------------------------- //

    private fun drawFocusDot(canvas: Canvas) {
        val cx = width / 2f - offsetX * density
        val cy = height / 2f - offsetY * density
        val radius = config.focusDotRadius * density
        val halo = config.focusDotHaloRadius * density
        if (halo > radius) {
            fillPaint.color = config.focusDotHaloColor
            canvas.drawCircle(cx, cy, halo, fillPaint)
        }
        fillPaint.color = config.focusDotColor
        canvas.drawCircle(cx, cy, radius, fillPaint)
    }

    /** Multiplies a colour's alpha channel by [factor] (0..1). */
    private fun applyAlpha(color: Int, factor: Float): Int {
        val baseAlpha = (color ushr 24) and 0xFF
        val newAlpha = (baseAlpha * factor).toInt().coerceIn(0, 255)
        return (newAlpha shl 24) or (color and 0x00FFFFFF)
    }
}
