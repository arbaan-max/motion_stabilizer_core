import 'package:flutter/widgets.dart';

/// Where the field of motion-cue dots is anchored on screen.
enum CuePlacement {
  /// Dots clustered along the four edges, centre kept clear (Apple-style).
  edges,

  /// Dots tiled across the whole screen, including the centre.
  fullScreen,

  /// Dots along the left and right edges only.
  sides,

  /// Dots clustered in a central cluster (a "fixation field").
  center,
}

/// The shape drawn for each bubble.
enum DotShape { circle, ring, square, diamond }

/// The visual style of the Earth-stable reference line ("horizon" / divider).
///
/// A stable horizon gives the eyes a reference frame that agrees with the inner
/// ear — a core motion-sickness remedy. Pick the look that suits your UI.
enum DividerStyle {
  /// No divider.
  none,

  /// A clean straight line with a soft glow.
  line,

  /// A flowing, multi-harmonic wave (water-like). See [MotionCueConfig.waveAnimated]
  /// and [MotionCueConfig.waveReactsToMotion].
  wavy,

  /// A dashed straight line.
  dashed,

  /// Two parallel rails (road / track feel).
  dualRail,

  /// Fills the area below the horizon with [MotionCueConfig.horizonFillColor]
  /// (the "light-blue bottom half" look), with a flowing top edge.
  filledHorizon,

  /// A soft gradient band fading out above and below the horizon.
  gradientBand,
}

/// Visual + behavioural configuration shared by the in-app overlay and the
/// native Android system overlay.
///
/// Everything about the motion-sickness UI is driven from here: toggle the
/// bubbles, the focus dot and the horizon independently, choose styles, and
/// tune every colour and size. The same object is serialised across the method
/// channel to the native overlay via [toMap]/[fromMap].
///
/// Prefer the named constructors ([MotionCueConfig.gentle],
/// [MotionCueConfig.standard], [MotionCueConfig.intense],
/// [MotionCueConfig.calmHorizon]) as medically-informed starting points, then
/// [copyWith] to adjust.
@immutable
class MotionCueConfig {
  const MotionCueConfig({
    // Bubbles (dots).
    this.showDots = true,
    this.dotColor = const Color(0xFFFFFFFF),
    this.dotRadius = 5.0,
    this.dotSpacing = 56.0,
    this.placement = CuePlacement.edges,
    this.dotShape = DotShape.circle,
    this.dotBaseOpacity = 0.32,
    this.dotMaxOpacity = 0.9,
    this.dotReactToMotionOpacity = true,
    this.dotSizeJitter = 0.0,
    this.dotGlow = false,
    // Motion response.
    this.gain = 16.0,
    this.maxTravel = 28.0,
    this.activationThreshold = 0.25,
    this.maxIntensity = 4.0,
    this.invertX = false,
    this.invertY = false,
    this.swapAxes = false,
    // Horizon / divider.
    this.dividerStyle = DividerStyle.line,
    this.dividerColor = const Color(0xFFFFFFFF),
    this.dividerThickness = 2.5,
    this.dividerOpacity = 0.5,
    this.horizonFillColor = const Color(0x3340C4FF),
    this.waveAmplitude = 8.0,
    this.waveWavelength = 140.0,
    this.waveSpeed = 0.35,
    this.waveAnimated = true,
    this.waveReactsToMotion = true,
    this.levelWithHorizon = true,
    this.horizonStabilization = 0.85,
    // Focus dot.
    this.showFocusDot = false,
    this.focusDotColor = const Color(0xFFFFFFFF),
    this.focusDotRadius = 6.0,
    this.focusDotHaloRadius = 18.0,
    this.focusDotHaloColor = const Color(0x33FFFFFF),
  }) : assert(dotRadius > 0),
       assert(dotSpacing > 0),
       assert(gain >= 0),
       assert(maxTravel >= 0),
       assert(dotSizeJitter >= 0 && dotSizeJitter <= 1),
       assert(horizonStabilization >= 0 && horizonStabilization < 1),
       assert(dotBaseOpacity >= 0 && dotBaseOpacity <= 1),
       assert(dotMaxOpacity >= 0 && dotMaxOpacity <= 1);

  // ---------------------------------------------------------------------------
  // Bubbles (dots)
  // ---------------------------------------------------------------------------

  /// Whether to draw the field of motion-cue dots ("bubbles").
  final bool showDots;

  /// Colour of each dot.
  final Color dotColor;

  /// Radius of each dot in logical pixels.
  final double dotRadius;

  /// Distance between dots in the field, in logical pixels.
  final double dotSpacing;

  /// Where the dot field is drawn.
  final CuePlacement placement;

  /// Shape of each bubble.
  final DotShape dotShape;

  /// Dot opacity when the device is at rest. Keep this above zero so the cues
  /// stay visible (and never "disappear") while still — motion then *moves*
  /// them rather than revealing them.
  final double dotBaseOpacity;

  /// Dot opacity at full motion ([maxIntensity]).
  final double dotMaxOpacity;

  /// When `true`, dot opacity ramps from [dotBaseOpacity] to [dotMaxOpacity]
  /// with motion (brighter when shaking). When `false`, dots hold a constant
  /// [dotBaseOpacity] regardless of motion.
  final bool dotReactToMotionOpacity;

  /// Per-bubble random size variation in `[0, 1]`. `0` = uniform; `0.5` = sizes
  /// vary by ±50%. Deterministic, so bubbles don't flicker.
  final double dotSizeJitter;

  /// Whether to draw a soft glow around each bubble.
  final bool dotGlow;

  // ---------------------------------------------------------------------------
  // Motion response
  // ---------------------------------------------------------------------------

  /// Logical pixels of dot travel per m/s^2 of linear acceleration.
  final double gain;

  /// Maximum dot displacement in logical pixels (caps the travel).
  final double maxTravel;

  /// Linear acceleration (m/s^2) below which motion is ignored (jitter guard).
  final double activationThreshold;

  /// Acceleration (m/s^2) at which the opacity ramp reaches its maximum.
  final double maxIntensity;

  /// Flip the horizontal response (for reverse-mounted devices).
  final bool invertX;

  /// Flip the vertical response.
  final bool invertY;

  /// Swap the X and Y response, e.g. for landscape mounts.
  final bool swapAxes;

  // ---------------------------------------------------------------------------
  // Horizon / divider
  // ---------------------------------------------------------------------------

  /// Which Earth-stable reference style to draw (or [DividerStyle.none]).
  final DividerStyle dividerStyle;

  /// Colour of the divider line / edge.
  final Color dividerColor;

  /// Line thickness in logical pixels.
  final double dividerThickness;

  /// Constant opacity of the divider — independent of motion, so the horizon
  /// always stays visible as a stable reference.
  final double dividerOpacity;

  /// Fill colour used below the horizon for [DividerStyle.filledHorizon].
  final Color horizonFillColor;

  /// Wave height in logical pixels for [DividerStyle.wavy] / filled horizon.
  final double waveAmplitude;

  /// Wave length in logical pixels for [DividerStyle.wavy] / filled horizon.
  final double waveWavelength;

  /// Base wave-flow speed in cycles per second.
  final double waveSpeed;

  /// When `true`, the wave continuously flows (water-like). When `false`, it is
  /// drawn as a static, non-moving shape.
  final bool waveAnimated;

  /// When `true`, the wave's amplitude and sway increase with device motion, so
  /// it "dances" as the device flows; when `false`, the flow is constant.
  final bool waveReactsToMotion;

  /// Whether the divider counter-rotates with device roll to stay level with
  /// the real-world horizon (the medically-effective behaviour).
  final bool levelWithHorizon;

  /// How heavily the horizon's tilt is smoothed in `[0, 1)`. Higher values make
  /// the horizon ignore quick shakes and only follow sustained tilt. `0` = the
  /// raw (jittery) angle; `0.85` (default) is steady; `0.97` is very calm.
  final double horizonStabilization;

  // ---------------------------------------------------------------------------
  // Focus dot
  // ---------------------------------------------------------------------------

  /// Whether to draw the central fixation dot.
  final bool showFocusDot;

  /// Colour of the focus dot.
  final Color focusDotColor;

  /// Radius of the focus dot in logical pixels.
  final double focusDotRadius;

  /// Radius of the soft halo behind the focus dot. Set `<= focusDotRadius` to
  /// hide the halo.
  final double focusDotHaloRadius;

  /// Colour of the focus-dot halo.
  final Color focusDotHaloColor;

  // ---------------------------------------------------------------------------
  // Presets
  // ---------------------------------------------------------------------------

  /// Subtle cues for sensitive users: small, low-contrast edge dots and a faint
  /// level line. Minimal cognitive load.
  const MotionCueConfig.gentle()
    : this(
        dotRadius: 4.0,
        dotSpacing: 64.0,
        placement: CuePlacement.edges,
        dotBaseOpacity: 0.22,
        dotMaxOpacity: 0.6,
        gain: 12.0,
        maxTravel: 20.0,
        dividerStyle: DividerStyle.line,
        dividerOpacity: 0.35,
        horizonStabilization: 0.92,
      );

  /// Balanced defaults suitable for most riders.
  const MotionCueConfig.standard() : this();

  /// Strong, highly-visible cues for severe motion sickness: full-screen dots
  /// and a flowing filled horizon.
  const MotionCueConfig.intense()
    : this(
        placement: CuePlacement.fullScreen,
        dotSpacing: 48.0,
        dotBaseOpacity: 0.45,
        dotMaxOpacity: 1.0,
        dotGlow: true,
        gain: 22.0,
        maxTravel: 36.0,
        dividerStyle: DividerStyle.filledHorizon,
        dividerOpacity: 0.7,
      );

  /// No dots — just the calming "light-blue horizon" fill that flows and tilts
  /// with the device. Good as an ambient, low-distraction background.
  const MotionCueConfig.calmHorizon()
    : this(
        showDots: false,
        dividerStyle: DividerStyle.filledHorizon,
        dividerOpacity: 0.85,
      );

  MotionCueConfig copyWith({
    bool? showDots,
    Color? dotColor,
    double? dotRadius,
    double? dotSpacing,
    CuePlacement? placement,
    DotShape? dotShape,
    double? dotBaseOpacity,
    double? dotMaxOpacity,
    bool? dotReactToMotionOpacity,
    double? dotSizeJitter,
    bool? dotGlow,
    double? gain,
    double? maxTravel,
    double? activationThreshold,
    double? maxIntensity,
    bool? invertX,
    bool? invertY,
    bool? swapAxes,
    DividerStyle? dividerStyle,
    Color? dividerColor,
    double? dividerThickness,
    double? dividerOpacity,
    Color? horizonFillColor,
    double? waveAmplitude,
    double? waveWavelength,
    double? waveSpeed,
    bool? waveAnimated,
    bool? waveReactsToMotion,
    bool? levelWithHorizon,
    double? horizonStabilization,
    bool? showFocusDot,
    Color? focusDotColor,
    double? focusDotRadius,
    double? focusDotHaloRadius,
    Color? focusDotHaloColor,
  }) {
    return MotionCueConfig(
      showDots: showDots ?? this.showDots,
      dotColor: dotColor ?? this.dotColor,
      dotRadius: dotRadius ?? this.dotRadius,
      dotSpacing: dotSpacing ?? this.dotSpacing,
      placement: placement ?? this.placement,
      dotShape: dotShape ?? this.dotShape,
      dotBaseOpacity: dotBaseOpacity ?? this.dotBaseOpacity,
      dotMaxOpacity: dotMaxOpacity ?? this.dotMaxOpacity,
      dotReactToMotionOpacity:
          dotReactToMotionOpacity ?? this.dotReactToMotionOpacity,
      dotSizeJitter: dotSizeJitter ?? this.dotSizeJitter,
      dotGlow: dotGlow ?? this.dotGlow,
      gain: gain ?? this.gain,
      maxTravel: maxTravel ?? this.maxTravel,
      activationThreshold: activationThreshold ?? this.activationThreshold,
      maxIntensity: maxIntensity ?? this.maxIntensity,
      invertX: invertX ?? this.invertX,
      invertY: invertY ?? this.invertY,
      swapAxes: swapAxes ?? this.swapAxes,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      dividerOpacity: dividerOpacity ?? this.dividerOpacity,
      horizonFillColor: horizonFillColor ?? this.horizonFillColor,
      waveAmplitude: waveAmplitude ?? this.waveAmplitude,
      waveWavelength: waveWavelength ?? this.waveWavelength,
      waveSpeed: waveSpeed ?? this.waveSpeed,
      waveAnimated: waveAnimated ?? this.waveAnimated,
      waveReactsToMotion: waveReactsToMotion ?? this.waveReactsToMotion,
      levelWithHorizon: levelWithHorizon ?? this.levelWithHorizon,
      horizonStabilization: horizonStabilization ?? this.horizonStabilization,
      showFocusDot: showFocusDot ?? this.showFocusDot,
      focusDotColor: focusDotColor ?? this.focusDotColor,
      focusDotRadius: focusDotRadius ?? this.focusDotRadius,
      focusDotHaloRadius: focusDotHaloRadius ?? this.focusDotHaloRadius,
      focusDotHaloColor: focusDotHaloColor ?? this.focusDotHaloColor,
    );
  }

  /// Serialises the config for the native method channel. Colours are sent as
  /// 32-bit ARGB ints; enums as their index.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'showDots': showDots,
    'dotColor': _argb(dotColor),
    'dotRadius': dotRadius,
    'dotSpacing': dotSpacing,
    'placement': placement.index,
    'dotShape': dotShape.index,
    'dotBaseOpacity': dotBaseOpacity,
    'dotMaxOpacity': dotMaxOpacity,
    'dotReactToMotionOpacity': dotReactToMotionOpacity,
    'dotSizeJitter': dotSizeJitter,
    'dotGlow': dotGlow,
    'gain': gain,
    'maxTravel': maxTravel,
    'activationThreshold': activationThreshold,
    'maxIntensity': maxIntensity,
    'invertX': invertX,
    'invertY': invertY,
    'swapAxes': swapAxes,
    'dividerStyle': dividerStyle.index,
    'dividerColor': _argb(dividerColor),
    'dividerThickness': dividerThickness,
    'dividerOpacity': dividerOpacity,
    'horizonFillColor': _argb(horizonFillColor),
    'waveAmplitude': waveAmplitude,
    'waveWavelength': waveWavelength,
    'waveSpeed': waveSpeed,
    'waveAnimated': waveAnimated,
    'waveReactsToMotion': waveReactsToMotion,
    'levelWithHorizon': levelWithHorizon,
    'horizonStabilization': horizonStabilization,
    'showFocusDot': showFocusDot,
    'focusDotColor': _argb(focusDotColor),
    'focusDotRadius': focusDotRadius,
    'focusDotHaloRadius': focusDotHaloRadius,
    'focusDotHaloColor': _argb(focusDotHaloColor),
  };

  static MotionCueConfig fromMap(Map<String, dynamic> map) {
    double d(String k, double def) => (map[k] as num?)?.toDouble() ?? def;
    int i(String k, int def) => (map[k] as num?)?.toInt() ?? def;
    bool b(String k, bool def) => (map[k] as bool?) ?? def;
    return MotionCueConfig(
      showDots: b('showDots', true),
      dotColor: Color(i('dotColor', 0xFFFFFFFF)),
      dotRadius: d('dotRadius', 5.0),
      dotSpacing: d('dotSpacing', 56.0),
      placement: CuePlacement.values[i('placement', 0)],
      dotShape: DotShape.values[i('dotShape', 0)],
      dotBaseOpacity: d('dotBaseOpacity', 0.32),
      dotMaxOpacity: d('dotMaxOpacity', 0.9),
      dotReactToMotionOpacity: b('dotReactToMotionOpacity', true),
      dotSizeJitter: d('dotSizeJitter', 0.0),
      dotGlow: b('dotGlow', false),
      gain: d('gain', 16.0),
      maxTravel: d('maxTravel', 28.0),
      activationThreshold: d('activationThreshold', 0.25),
      maxIntensity: d('maxIntensity', 4.0),
      invertX: b('invertX', false),
      invertY: b('invertY', false),
      swapAxes: b('swapAxes', false),
      dividerStyle: DividerStyle.values[i('dividerStyle', 1)],
      dividerColor: Color(i('dividerColor', 0xFFFFFFFF)),
      dividerThickness: d('dividerThickness', 2.5),
      dividerOpacity: d('dividerOpacity', 0.5),
      horizonFillColor: Color(i('horizonFillColor', 0x3340C4FF)),
      waveAmplitude: d('waveAmplitude', 8.0),
      waveWavelength: d('waveWavelength', 140.0),
      waveSpeed: d('waveSpeed', 0.35),
      waveAnimated: b('waveAnimated', true),
      waveReactsToMotion: b('waveReactsToMotion', true),
      levelWithHorizon: b('levelWithHorizon', true),
      horizonStabilization: d('horizonStabilization', 0.85),
      showFocusDot: b('showFocusDot', false),
      focusDotColor: Color(i('focusDotColor', 0xFFFFFFFF)),
      focusDotRadius: d('focusDotRadius', 6.0),
      focusDotHaloRadius: d('focusDotHaloRadius', 18.0),
      focusDotHaloColor: Color(i('focusDotHaloColor', 0x33FFFFFF)),
    );
  }

  // ignore: deprecated_member_use
  static int _argb(Color c) => c.value;
}
