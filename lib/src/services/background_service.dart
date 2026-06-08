import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/motion_cue_config.dart';

/// Bridge to the native Android system overlay.
///
/// This drives the "background accessibility" feature: a foreground service
/// that floats the motion cues over *other* apps using a `SYSTEM_ALERT_WINDOW`
/// overlay. All methods are no-ops (returning sensible defaults) on platforms
/// other than Android so callers do not need platform checks everywhere.
class BackgroundOverlayService {
  BackgroundOverlayService({@visibleForTesting MethodChannel? channel})
      : _channel = channel ?? _defaultChannel;

  static const MethodChannel _defaultChannel =
      MethodChannel('motion_stabilizer_core/overlay');

  final MethodChannel _channel;

  /// Whether the system-overlay feature is available on this platform.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Whether the user has granted the "draw over other apps" permission.
  Future<bool> hasOverlayPermission() async {
    if (!isSupported) return false;
    final granted = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return granted ?? false;
  }

  /// Opens the system settings page where the user grants the overlay
  /// permission. Returns immediately; re-check with [hasOverlayPermission] when
  /// the app resumes.
  Future<void> requestOverlayPermission() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('requestOverlayPermission');
  }

  /// Starts the foreground overlay service and shows the cues over other apps.
  ///
  /// Returns `true` if the overlay started. Returns `false` if the platform is
  /// unsupported or the overlay permission has not been granted.
  Future<bool> start(MotionCueConfig config) async {
    if (!isSupported) return false;
    if (!await hasOverlayPermission()) return false;
    final started =
        await _channel.invokeMethod<bool>('startOverlay', config.toMap());
    return started ?? false;
  }

  /// Pushes a new [config] to a running overlay without restarting it.
  Future<void> updateConfig(MotionCueConfig config) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('updateConfig', config.toMap());
  }

  /// Stops the overlay and tears down the foreground service.
  Future<void> stop() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('stopOverlay');
  }

  /// Whether the overlay service is currently running.
  Future<bool> isRunning() async {
    if (!isSupported) return false;
    final running = await _channel.invokeMethod<bool>('isOverlayRunning');
    return running ?? false;
  }
}
