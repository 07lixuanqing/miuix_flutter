# Release artifacts

Current complete Release cycle: 1.2.1+30694000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30694000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381313 bytes
- SHA-256: D1CD4F4F40F7F4FAACFBAACC5C9EBE22738B3407407DF82BCBDADFFCA1DABF00
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30694000.zip
- Architecture: Windows x64 Release
- Size: 38490211 bytes; 60 ZIP entries
- SHA-256: B197537EAD84C50901249D5C17CB9E1C162558E14559ED24026EFC1EF12B3FFF

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1711870 bytes; 288 entries; SHA-256 AF474147EBBC45FC5BE28F3853020A915F7FC11A997DED99BDF9F1276DDD9808
- Windows: flutter_miuix-1.2.1-windows.zip; 1709548 bytes; 288 entries; SHA-256 156C4C3E7C942A36ECFD66C81EF0870DE6977BDE6483E27164721EF1B6A7ACE4
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30694000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30694000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.