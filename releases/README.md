# Release artifacts

Current complete Release cycle: 1.2.1+30728000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30728000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381437 bytes
- SHA-256: 60CA9AD37AEA4C57F4A8E7154AEE71A72757495FA53852E86DA39DD87E309331
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30728000.zip
- Architecture: Windows x64 Release
- Size: 38142777 bytes; 60 ZIP entries
- SHA-256: 4437FD51A310270E9F47094F3474A98A4C109988BAC26F0B8C44BE734FBBAE8F

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1738068 bytes; 295 entries; SHA-256 840D33BBF2774B6C2A6FE43C583460AC8CB245937EF0433AE82E1AA06AB91F79
- Windows: flutter_miuix-1.2.1-windows.zip; 1735842 bytes; 295 entries; SHA-256 599230C32E512D8B5015240662D6640AF5FAAB0C8AC47C13ED566F14A9716E16
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30728000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30728000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.