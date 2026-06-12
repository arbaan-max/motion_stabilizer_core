# Contributing to motion_sickness_stabilizer

Thanks for helping make screens easier on the stomach! Issues, ideas and pull
requests are all welcome.

## Reporting bugs & requesting features

Open an issue at
https://github.com/arbaan-max/motion_sickness_stabilizer/issues with:

- What you expected and what actually happened
- Your Flutter version (`flutter --version`), device and Android version
- A minimal code snippet or steps to reproduce (the [example app](example/) is a
  great starting point)

## Submitting changes

Direct pushes to `main` are not allowed — all changes go through a pull
request:

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b fix/my-fix
   ```
2. Make your changes. Keep the style of the surrounding code, and update the
   README / dartdoc if you change public API.
3. Make sure everything passes locally:
   ```bash
   dart format lib test
   flutter analyze
   flutter test
   ```
4. If your change affects the visual cues, please test it in the
   [example app](example/) on a real Android device.
5. Add an entry to `CHANGELOG.md` under an "Unreleased" heading.
6. Open a pull request against `main`. CI must pass and the maintainer will
   review before merging.

## Notes

- Versioning and publishing to [pub.dev](https://pub.dev/packages/motion_sickness_stabilizer)
  is handled by the maintainer — don't bump `version:` in `pubspec.yaml`.
- The native Android overlay (Kotlin) mirrors the Dart maths in
  `MotionController`/`MotionFilter`. If you change one side, change the other to
  keep the in-app and system overlays identical.
- By contributing, you agree your contributions are licensed under the
  [MIT License](LICENSE).
