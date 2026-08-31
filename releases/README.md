# Release artifacts

Current complete Release cycle: 1.2.1+30576000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30576000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45153085 bytes
- SHA-256: AEE70F5D9E0D6E6D9C807F1785E945DD8908DF1BB9D0BFFB9F257A189C6DC963
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30576000.zip
- Architecture: Windows x64 Release
- Size: 39063260 bytes; 60 ZIP entries
- SHA-256: FF262CF6C5E7AA403CF9134D0C1E9D87AD18D26D75E43877B43314DF87BBC9F4

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1615303 bytes; 270 entries; SHA-256 2E350667547CEE192F9A60668B0D2F1F71C2D544E0E06185ABCAECE3470E735E
- Windows: flutter_miuix-1.2.1-windows.zip; 1612981 bytes; 270 entries; SHA-256 6B1EF6ACD99529C69897DE1DB40F18AF71AFB19F06C4D3C6282D51AE73455178
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30576000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30576000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.