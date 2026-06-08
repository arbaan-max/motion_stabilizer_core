## 0.3.0

More customization + fixes.

* **Fixed:** the horizon no longer spins on a quick shake — tilt is now heavily
  smoothed via `horizonStabilization` (0 = raw, 0.85 default, ~0.97 very calm).
  Uses the device gravity vector, so only sustained tilt rotates it.
* **New bubbles options:** `dotShape` (circle/ring/square/diamond),
  `dotSizeJitter` (organic per-bubble sizes), `dotGlow`, a
  `dotReactToMotionOpacity` toggle for the brighten-on-motion behaviour, and a
  `center` placement so bubbles can fill the middle.
* **Water-flow wave:** `wavy`/`filledHorizon` now use a multi-harmonic
  travelling wave that flows like water and, with `waveReactsToMotion`,
  "dances" with device motion. `waveAnimated` toggles static vs flowing.
* The native Android overlay mirrors every new option; both layers verified.
* Example app exposes all new controls.

## 0.2.0

Customization overhaul + visibility fixes.

* **Fixed:** cues no longer vanish at rest or in the background — base visibility
  is decoupled from motion. Bubbles ramp from `dotBaseOpacity` to
  `dotMaxOpacity`; the horizon uses a constant `dividerOpacity`.
* **New:** independent `showDots` / `showFocusDot` toggles, and a `dividerStyle`
  with six designs — `line`, `wavy` (animated), `dashed`, `dualRail`,
  `filledHorizon` (light-blue split), `gradientBand` — plus `none`.
* **New:** full styling control (colours, sizes, opacities, wave params) and
  medically-informed presets `gentle()`, `standard()`, `intense()`,
  `calmHorizon()`.
* The native Android overlay mirrors every new style and animates continuously.
* **Breaking:** removed `showHorizon`/`horizonColor`/`minOpacity`/`maxOpacity`
  and the `HorizonLine` widget. Use `dividerStyle`/`dividerColor`,
  `dotBaseOpacity`/`dotMaxOpacity` and `MotionDivider` instead.

## 0.1.0

Initial release.

* In-app motion cues: `MotionStabilizer`, `MotionOverlay`, `HorizonLine` and
  `FocusDot`, driven by a reactive `MotionController`.
* Sensor fusion via `SensorService` + `MotionFilter` (low-pass gravity removal
  and smoothing) over `sensors_plus`.
* Android system overlay (`BackgroundOverlayService`): a foreground service that
  floats the cues over other apps using `SYSTEM_ALERT_WINDOW`, with the same
  motion maths implemented natively in Kotlin.
* Optional Android accessibility-service toggle.
* Shared, serialisable `MotionCueConfig` for colour, layout, gain and axis
  handling.
* Example app demonstrating both layers.
