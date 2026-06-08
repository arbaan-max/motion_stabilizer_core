# motion_stabilizer_core

**Motion-sickness mitigation toolkit for Flutter, focused on Android.**

When you read or watch something on a phone in a moving vehicle, your eyes see a
still screen while your inner ear feels the acceleration. That **sensory
conflict** is what causes motion sickness — the nausea and headaches. This
package reduces it by drawing **animated visual cues** that drift *opposite* to
the vehicle's real-world acceleration — the same principle behind Apple's
"Vehicle Motion Cues" — giving your eyes a motion signal that matches what your
inner ear already feels.

> Built because there was **no motion-sickness package on pub.dev**. Free, open
> source, and made for the community.
> ⭐ **GitHub:** https://github.com/Arbaan-KaizenQue/motion_stabilizer_core

It ships **two layers** that share one configuration object:

| Layer | What it does | Where |
|-------|--------------|-------|
| **In-app cues** | Sensor-driven bubbles, horizon and focus dot rendered over *your* UI | Any platform with an accelerometer |
| **System overlay** | A foreground service floats the same cues over **other apps** | Android (`SYSTEM_ALERT_WINDOW`) |

---

## ✨ Features

- 🎯 **Vehicle motion cues** — a field of animated "bubbles" that react to real
  acceleration. Placement: edges / sides / full-screen / center. Shapes:
  circle / ring / square / diamond. Optional size jitter and glow.
- 🌊 **Earth-stable horizon — 7 styles** — `none`, `line`, `wavy` (multi-harmonic
  water flow), `dashed`, `dualRail` (road), `filledHorizon` (the calming
  light-blue split) and `gradientBand`. Stays level with the real horizon and
  **ignores shakes** (configurable stabilization).
- ⚪ **Focus dot** — an optional central fixation point that counter-moves
  against motion.
- 📱 **Android system overlay** — float the cues over *any* app via a foreground
  service ("background accessibility"). The native overlay renders the exact
  same styles and animations.
- ♿ **Accessibility-service toggle** — optionally turn cues on from the system
  Accessibility menu, no host app needed.
- 🎛️ **Everything is a parameter** — enable/disable each element and control
  every colour, size, opacity, shape and animation from one `MotionCueConfig`.
- 🩺 **Presets** — `gentle()`, `standard()`, `intense()`, `calmHorizon()`.
- 🧮 **Built-in sensor fusion** — low-pass gravity removal + smoothing. Cues stay
  visible at rest and *move* with motion rather than only appearing when shaken.

---

## 📦 Installation

```yaml
dependencies:
  motion_stabilizer_core: ^0.3.0
```

```bash
flutter pub get
```

```dart
import 'package:motion_stabilizer_core/motion_stabilizer_core.dart';
```

---

## 🤖 Android setup

The plugin declares everything it needs and it is **merged into your app
automatically** — you do **not** have to touch your `AndroidManifest.xml`.

**Requirements**

- `minSdkVersion` **23+**
- `compileSdk` / `targetSdk` **34+**

In `android/app/build.gradle`:

```gradle
android {
    compileSdk = 34
    defaultConfig {
        minSdk = 23
        targetSdk = 34
    }
}
```

**Permissions merged by the plugin** (no action needed):

| Permission | Why |
|------------|-----|
| `SYSTEM_ALERT_WINDOW` | Draw the cues over other apps |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_SPECIAL_USE` | Keep the overlay alive in the background |
| `POST_NOTIFICATIONS` | Show the persistent "cues active" notification (Android 13+) |

> The in-app layer (bubbles/horizon over **your own** UI) needs **no permissions
> at all** — only the system overlay does.

---

## 🔐 Permissions — asking the user

The system overlay needs the user to grant **"Display over other apps"**. This
is a special permission that can't be granted with a normal runtime dialog — you
send the user to the system settings page and re-check when they come back.

```dart
final overlay = BackgroundOverlayService();

// 1. Is the feature available at all? (false on iOS / web)
if (!overlay.isSupported) return;

// 2. Already granted?
if (!await overlay.hasOverlayPermission()) {
  // 3. Opens the system "Display over other apps" settings page.
  await overlay.requestOverlayPermission();
  // The call returns immediately — the user grants it in Settings.
}
```

Re-check when your app resumes (the user just came back from Settings):

```dart
class _MyState extends State<MyWidget> with WidgetsBindingObserver {
  final _overlay = BackgroundOverlayService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final granted = await _overlay.hasOverlayPermission();
      setState(() => /* update your UI */);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

> On **Android 13+**, also request `POST_NOTIFICATIONS` (e.g. via
> [`permission_handler`](https://pub.dev/packages/permission_handler)) so the
> foreground-service notification is visible. The overlay still runs without it.

---

## 🚀 Usage

### 1. In-app cues — wrap your app

```dart
MotionStabilizer(
  enabled: ridingInVehicle,           // toggle on/off; releases sensors when off
  config: const MotionCueConfig.standard().copyWith(
    placement: CuePlacement.edges,
    dotColor: Color(0xFF80D8FF),
    dividerStyle: DividerStyle.wavy,
    showFocusDot: true,
  ),
  child: MyApp(),
);
```

### 2. System overlay — cues over other apps (Android)

```dart
final overlay = BackgroundOverlayService();

// (after the permission is granted — see above)
await overlay.start(const MotionCueConfig.intense());

// Change the look live, without restarting:
await overlay.updateConfig(const MotionCueConfig(gain: 22));

// Is it running?
final running = await overlay.isRunning();

// Stop it:
await overlay.stop();
```

A persistent notification shows while the overlay is active. The overlay window
is **non-touchable**, so taps pass straight through to the app underneath.

### 3. Optional — Accessibility toggle

Enabling **"Motion Stabilizer Cues"** in *Settings → Accessibility* turns the
overlay on automatically and keeps it available across every app, even when your
Flutter app is closed. (The draw-over-apps permission is still required.)

### 4. Compose it yourself (advanced)

```dart
final controller = MotionController(config: const MotionCueConfig())..start();

Stack(
  children: [
    myContent,
    MotionDivider(controller: controller),   // animated horizon
    MotionOverlay(controller: controller),   // bubbles + focus dot per config
  ],
);
// controller.dispose() when done.
```

---

## 🎚️ Presets

Start from a preset, then `.copyWith(...)` to fine-tune:

```dart
const MotionCueConfig.gentle();      // subtle, low-distraction (sensitive users)
const MotionCueConfig.standard();    // balanced defaults
const MotionCueConfig.intense();     // strong cues for severe motion sickness
const MotionCueConfig.calmHorizon(); // no bubbles, just the calming horizon fill
```

---

## 🎨 Horizon / divider styles

Set with `dividerStyle`:

| Style | Look |
|-------|------|
| `none` | No horizon |
| `line` | Clean straight line with a soft glow |
| `wavy` | Flowing multi-harmonic **water** wave (animated) |
| `dashed` | Dashed straight line |
| `dualRail` | Two converging rails (road / track feel) |
| `filledHorizon` | Fills below a flowing edge with `horizonFillColor` (light-blue split) |
| `gradientBand` | Soft gradient band fading above and below |

---

## ⚙️ Full customization reference

Every option lives on
[`MotionCueConfig`](lib/src/models/motion_cue_config.dart).

### Bubbles (dots)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `showDots` | `bool` | `true` | Draw the bubble field |
| `dotColor` | `Color` | white | Bubble colour |
| `dotRadius` | `double` | `5.0` | Bubble size (logical px) |
| `dotSpacing` | `double` | `56.0` | Gap between bubbles (logical px) |
| `placement` | `CuePlacement` | `edges` | `edges` / `sides` / `fullScreen` / `center` |
| `dotShape` | `DotShape` | `circle` | `circle` / `ring` / `square` / `diamond` |
| `dotBaseOpacity` | `double` | `0.32` | Opacity at rest (keep > 0 so cues stay visible) |
| `dotMaxOpacity` | `double` | `0.9` | Opacity at full motion |
| `dotReactToMotionOpacity` | `bool` | `true` | Brighten on motion (`false` = constant `dotBaseOpacity`) |
| `dotSizeJitter` | `double` | `0.0` | Per-bubble random size variation `[0,1]` (organic look) |
| `dotGlow` | `bool` | `false` | Soft glow around each bubble |

### Motion response

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `gain` | `double` | `16.0` | Pixels of bubble travel per m/s² of acceleration (sensitivity) |
| `maxTravel` | `double` | `28.0` | Max bubble displacement (logical px) |
| `activationThreshold` | `double` | `0.25` | Acceleration (m/s²) below which motion is ignored (jitter guard) |
| `maxIntensity` | `double` | `4.0` | Acceleration (m/s²) at which the opacity ramp maxes out |
| `invertX` | `bool` | `false` | Flip horizontal response (reverse-mounted device) |
| `invertY` | `bool` | `false` | Flip vertical response |
| `swapAxes` | `bool` | `false` | Swap X/Y response (landscape mount) |

### Horizon / divider

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `dividerStyle` | `DividerStyle` | `line` | See styles table above |
| `dividerColor` | `Color` | white | Line / edge colour |
| `dividerThickness` | `double` | `2.5` | Line thickness (logical px) |
| `dividerOpacity` | `double` | `0.5` | Constant opacity (independent of motion, always visible) |
| `horizonFillColor` | `Color` | light blue | Fill below the line for `filledHorizon` |
| `waveAmplitude` | `double` | `8.0` | Wave height (logical px) |
| `waveWavelength` | `double` | `140.0` | Wave length (logical px) |
| `waveSpeed` | `double` | `0.35` | Flow speed (cycles per second) |
| `waveAnimated` | `bool` | `true` | `true` = flowing water, `false` = static shape |
| `waveReactsToMotion` | `bool` | `true` | Wave swells & sways ("dances") with device motion |
| `levelWithHorizon` | `bool` | `true` | Counter-rotate with tilt to stay level with the real horizon |
| `horizonStabilization` | `double` | `0.85` | How heavily tilt is smoothed `[0,1)` — higher ignores shakes, only follows sustained tilt |

### Focus dot

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `showFocusDot` | `bool` | `false` | Draw the central fixation dot |
| `focusDotColor` | `Color` | white | Dot colour |
| `focusDotRadius` | `double` | `6.0` | Dot radius (logical px) |
| `focusDotHaloRadius` | `double` | `18.0` | Halo radius (set ≤ `focusDotRadius` to hide) |
| `focusDotHaloColor` | `Color` | translucent white | Halo colour |

Update at runtime with `copyWith` (in-app rebuilds automatically; for the system
overlay call `overlay.updateConfig(newConfig)`):

```dart
config = config.copyWith(
  dotShape: DotShape.diamond,
  dotSizeJitter: 0.4,
  dotGlow: true,
  dividerStyle: DividerStyle.filledHorizon,
  horizonStabilization: 0.95, // very steady horizon
);
```

---

## 🧠 How it works

`SensorService` streams the accelerometer and gyroscope. A `MotionFilter`
estimates gravity with a low-pass filter and subtracts it to recover real linear
acceleration. `MotionController` turns that into a screen-space offset (opposite
the motion), a normalised intensity, and a heavily-smoothed horizon angle. The
native `MotionOverlayService` runs the **same maths in Kotlin**, so the system
overlay behaves identically to the in-app layer.

---

## 📱 Example — run the demo app

A full demo with live toggles, dropdowns and sliders for **every** option is in
[`example/`](example/lib/main.dart). Follow these steps to run it:

**1. Clone the repository**

```bash
git clone https://github.com/arbaan-max/Motion-Sickness
cd motion_stabilizer_core
```

**2. Go into the example app**

```bash
cd example
```

**3. Fetch dependencies**

```bash
flutter pub get
```

**4. Connect a device** (motion cues need real accelerometer data, so prefer a
**physical Android phone**; an emulator works but you must feed it virtual
sensor values). Check it's detected:

```bash
flutter devices
```

**5. Run the app**

```bash
flutter run
```

Or build an installable APK:

```bash
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

**6. Try it out**

- Toggle **Cues enabled**, **Bubbles**, **Focus dot**, pick a **Horizon style**,
  and move the phone — the bubbles drift and the horizon flows.
- Tap a **preset** chip (Gentle / Standard / Intense / Calm horizon).
- For the **system overlay**: flip **"Float cues over other apps"**, tap
  **Grant** to allow *Display over other apps*, return to the app, enable it
  again, then go to your home screen — the cues now float over everything.

> **Tip:** the cues react to real acceleration. For the strongest effect, mount
> the phone in a moving vehicle. Shaking it by hand only triggers the
> motion-driven brightness/movement, not a sustained horizon tilt (that's
> intentional — see `horizonStabilization`).

---

## 🌍 Platform support

| Platform | In-app cues | System overlay |
|----------|:-----------:|:--------------:|
| Android  | ✅ | ✅ |
| iOS      | ✅ | ❌ (use the in-app layer) |
| Other    | ✅ (with sensors) | ❌ |

`BackgroundOverlayService` is a safe no-op on non-Android platforms, so the same
code runs everywhere.

---

## 🤝 Contributing

Issues, ideas and PRs are very welcome — this is built for the community. If it
saves you a headache on the road, a ⭐ on
[GitHub](https://github.com/Arbaan-KaizenQue/motion_stabilizer_core) means a lot.

---

## ⚠️ Disclaimer

This package implements well-established visual techniques (peripheral motion
cues + an Earth-stable horizon) to help *reduce* motion-sickness discomfort. It
is **not a medical device** and makes no clinical guarantees; effectiveness
varies by person. Never use the phone in a way that distracts a driver.
