/// Motion-sickness mitigation toolkit for Flutter.
///
/// Two layers, one shared [MotionCueConfig]:
///
/// * **In-app cues** — drop [MotionStabilizer] around your app (or compose
///   [MotionOverlay], [MotionDivider] and [FocusDot] yourself) to render
///   sensor-driven "vehicle motion cues" over your own UI.
/// * **System overlay** — [BackgroundOverlayService] floats the same cues over
///   *other* apps on Android via a foreground service and the draw-over-apps
///   permission ("background accessibility").
library;

export 'src/controllers/motion_controller.dart';
export 'src/models/motion_cue_config.dart';
export 'src/models/motion_data.dart';
export 'src/painters/divider_painter.dart';
export 'src/painters/dots_painter.dart';
export 'src/services/background_service.dart';
export 'src/services/sensor_service.dart';
export 'src/utils/math_utils.dart' show Vector3, kStandardGravity;
export 'src/widgets/focus_dot.dart';
export 'src/widgets/motion_divider.dart';
export 'src/widgets/motion_overlay.dart';
