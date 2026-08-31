# Release artifacts

Current complete Release cycle: 1.2.0+30572000.

Android test application:

- Stable file: flutter_miuix_example-1.2.0-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.0-android-arm64-v8a-release-30572000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45153089 bytes
- SHA-256: B7DDF5AA6BFBE7E3456C18D65C06683EA3541DFA73E5BF2E258E7C4B2DB8A00F
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.0-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.0-windows-x64-release-30572000.zip
- Architecture: Windows x64 Release
- Size: 39062614 bytes; 60 ZIP entries
- SHA-256: BC82807835A7AF5B52FC7BBD999710EFBB59233BFD4A891A187EF58C1DFE7962

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.0-android.zip; 1613224 bytes; 270 entries; SHA-256 2752FE1A6DB5F293F21269FC73A26096E68A7A57840A22BB86C2655E61BBE3E6
- Windows: flutter_miuix-1.2.0-windows.zip; 1611631 bytes; 270 entries; SHA-256 658B3D5185871EBC2D479B70DCCE98A25B9576FED42634C1F4EC27EBA3ADB763
- Hash manifest: flutter_miuix-1.2.0-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.0-android-30572000.zip
- Windows checkpoint: flutter_miuix-1.2.0-windows-30572000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.