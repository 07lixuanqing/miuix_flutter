# Release artifacts

Current complete Release cycle: 1.2.1+30586000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30586000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45154393 bytes
- SHA-256: C4A261052B23B9B7CA19BD2EA9A121E404905C29BADAB6A9264682F4ADB605D2
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30586000.zip
- Architecture: Windows x64 Release
- Size: 39062619 bytes; 60 ZIP entries
- SHA-256: EA6698D0B6C27A90944D2661192953447EDBB69A100DDD82879131A269E14526

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1619092 bytes; 270 entries; SHA-256 E62563A7E785A0E724DEDB1A9F94B54BA18DC3ADEA0097F7DF8D498ED41BFAD8
- Windows: flutter_miuix-1.2.1-windows.zip; 1616770 bytes; 270 entries; SHA-256 1F58C4CD5E53A2AEAD5556AD21651504A4445604AF2AD8E4CE64DB3D9B89E7AE
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30586000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30586000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.