import 'package:flutter/material.dart';
import 'package:motion_stabilizer_core/motion_stabilizer_core.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motion Stabilizer Demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _overlayService = BackgroundOverlayService();

  // Live, fully-customisable config.
  MotionCueConfig _config = const MotionCueConfig.standard().copyWith(
    dotColor: const Color(0xFF80D8FF),
    dividerColor: const Color(0xFFB3E5FC),
    dividerStyle: DividerStyle.wavy,
  );
  bool _enabled = true;

  bool _systemSupported = false;
  bool _hasOverlayPermission = false;
  bool _systemRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _systemSupported = _overlayService.isSupported;
    _refreshOverlayState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshOverlayState();
  }

  Future<void> _refreshOverlayState() async {
    if (!_overlayService.isSupported) return;
    final granted = await _overlayService.hasOverlayPermission();
    final running = await _overlayService.isRunning();
    if (!mounted) return;
    setState(() {
      _hasOverlayPermission = granted;
      _systemRunning = running;
    });
  }

  void _update(MotionCueConfig next) {
    setState(() => _config = next);
    if (_systemRunning) _overlayService.updateConfig(next);
  }

  Future<void> _toggleSystemOverlay(bool on) async {
    if (on) {
      if (!_hasOverlayPermission) {
        await _overlayService.requestOverlayPermission();
        return;
      }
      await _overlayService.start(_config);
    } else {
      await _overlayService.stop();
    }
    await _refreshOverlayState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    return MotionStabilizer(
      enabled: _enabled,
      config: _config,
      child: Scaffold(
        appBar: AppBar(title: const Text('Motion Stabilizer')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Title('Presets'),
            Wrap(
              spacing: 8,
              children: [
                _preset('Gentle', const MotionCueConfig.gentle()),
                _preset('Standard', const MotionCueConfig.standard()),
                _preset('Intense', const MotionCueConfig.intense()),
                _preset('Calm horizon', const MotionCueConfig.calmHorizon()),
              ],
            ),
            const Divider(height: 32),
            const _Title('What to show'),
            SwitchListTile(
              title: const Text('Cues enabled'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            SwitchListTile(
              title: const Text('Bubbles (dots)'),
              value: c.showDots,
              onChanged: (v) => _update(c.copyWith(showDots: v)),
            ),
            SwitchListTile(
              title: const Text('Central focus dot'),
              value: c.showFocusDot,
              onChanged: (v) => _update(c.copyWith(showFocusDot: v)),
            ),
            const Divider(height: 32),
            const _Title('Bubbles'),
            _dropdown<CuePlacement>(
              'Placement',
              c.placement,
              const {
                CuePlacement.edges: 'Edges',
                CuePlacement.sides: 'Sides',
                CuePlacement.fullScreen: 'Full screen',
                CuePlacement.center: 'Center',
              },
              (v) => _update(c.copyWith(placement: v)),
            ),
            _dropdown<DotShape>(
              'Shape',
              c.dotShape,
              const {
                DotShape.circle: 'Circle',
                DotShape.ring: 'Ring',
                DotShape.square: 'Square',
                DotShape.diamond: 'Diamond',
              },
              (v) => _update(c.copyWith(dotShape: v)),
            ),
            _slider('Ball size', c.dotRadius, 2, 14,
                (v) => _update(c.copyWith(dotRadius: v))),
            _slider('Spacing', c.dotSpacing, 28, 100,
                (v) => _update(c.copyWith(dotSpacing: v))),
            _slider('Size variation', c.dotSizeJitter, 0, 1,
                (v) => _update(c.copyWith(dotSizeJitter: v))),
            _slider('Sensitivity (gain)', c.gain, 4, 30,
                (v) => _update(c.copyWith(gain: v))),
            _slider('Max travel', c.maxTravel, 8, 60,
                (v) => _update(c.copyWith(maxTravel: v))),
            _slider('Rest opacity', c.dotBaseOpacity, 0, 1,
                (v) => _update(c.copyWith(dotBaseOpacity: v))),
            _slider('Active opacity', c.dotMaxOpacity, 0, 1,
                (v) => _update(c.copyWith(dotMaxOpacity: v))),
            SwitchListTile(
              title: const Text('Brighten on motion'),
              subtitle: const Text('Opacity rises as the device moves'),
              value: c.dotReactToMotionOpacity,
              onChanged: (v) =>
                  _update(c.copyWith(dotReactToMotionOpacity: v)),
            ),
            SwitchListTile(
              title: const Text('Glow'),
              value: c.dotGlow,
              onChanged: (v) => _update(c.copyWith(dotGlow: v)),
            ),
            const Divider(height: 32),
            const _Title('Horizon / divider'),
            _dropdown<DividerStyle>(
              'Style',
              c.dividerStyle,
              const {
                DividerStyle.none: 'None',
                DividerStyle.line: 'Line',
                DividerStyle.wavy: 'Wavy (water)',
                DividerStyle.dashed: 'Dashed',
                DividerStyle.dualRail: 'Dual rail',
                DividerStyle.filledHorizon: 'Filled horizon',
                DividerStyle.gradientBand: 'Gradient band',
              },
              (v) => _update(c.copyWith(dividerStyle: v)),
            ),
            _slider('Thickness', c.dividerThickness, 1, 8,
                (v) => _update(c.copyWith(dividerThickness: v))),
            _slider('Opacity', c.dividerOpacity, 0, 1,
                (v) => _update(c.copyWith(dividerOpacity: v))),
            _slider('Wave height', c.waveAmplitude, 0, 30,
                (v) => _update(c.copyWith(waveAmplitude: v))),
            _slider('Wave length', c.waveWavelength, 40, 320,
                (v) => _update(c.copyWith(waveWavelength: v))),
            _slider('Flow speed', c.waveSpeed, 0, 1.5,
                (v) => _update(c.copyWith(waveSpeed: v))),
            SwitchListTile(
              title: const Text('Animate flow'),
              subtitle: const Text('Off = static shape'),
              value: c.waveAnimated,
              onChanged: (v) => _update(c.copyWith(waveAnimated: v)),
            ),
            SwitchListTile(
              title: const Text('Dance with device motion'),
              value: c.waveReactsToMotion,
              onChanged: (v) => _update(c.copyWith(waveReactsToMotion: v)),
            ),
            SwitchListTile(
              title: const Text('Stay level with real horizon'),
              value: c.levelWithHorizon,
              onChanged: (v) => _update(c.copyWith(levelWithHorizon: v)),
            ),
            _slider(
              'Horizon stability (ignore shake)',
              c.horizonStabilization,
              0,
              0.98,
              (v) => _update(c.copyWith(horizonStabilization: v)),
            ),
            const Divider(height: 32),
            const _Title('System overlay (Android)'),
            if (!_systemSupported)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('System overlay is Android-only.'),
              )
            else ...[
              ListTile(
                leading: Icon(
                  _hasOverlayPermission ? Icons.check_circle : Icons.warning,
                  color: _hasOverlayPermission ? Colors.green : Colors.orange,
                ),
                title: const Text('Draw over other apps'),
                subtitle:
                    Text(_hasOverlayPermission ? 'Granted' : 'Not granted'),
                trailing: _hasOverlayPermission
                    ? null
                    : TextButton(
                        onPressed: _overlayService.requestOverlayPermission,
                        child: const Text('Grant'),
                      ),
              ),
              SwitchListTile(
                title: const Text('Float cues over other apps'),
                subtitle: const Text('Go to the home screen to see it.'),
                value: _systemRunning,
                onChanged: _toggleSystemOverlay,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _preset(String label, MotionCueConfig preset) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _update(preset.copyWith(
        dotColor: const Color(0xFF80D8FF),
        dividerColor: const Color(0xFFB3E5FC),
      )),
    );
  }

  Widget _dropdown<T>(
    String label,
    T value,
    Map<T, String> options,
    ValueChanged<T> onChanged,
  ) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<T>(
        value: value,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        items: [
          for (final e in options.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return ListTile(
      title: Text('$label  (${value.toStringAsFixed(2)})'),
      subtitle: Slider(
        min: min,
        max: max,
        value: value.clamp(min, max),
        onChanged: onChanged,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
