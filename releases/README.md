# Release artifacts

Current complete Release cycle: 1.2.1+30580000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30580000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45154393 bytes
- SHA-256: DB08D9006F357FC3E21A667C9A1AA61DA1525105FA0EF5B12DB7DBAAC6F98FF1
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30580000.zip
- Architecture: Windows x64 Release
- Size: 39062548 bytes; 60 ZIP entries
- SHA-256: E94CFDB28FAACA0F3B1722F7750923417E43D0D8223A2DCFD54D66DC96DA9D44

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1616845 bytes; 270 entries; SHA-256 FECA2AD7B0AA748EE04A9F7BB0E643F23246CBF030373B3A8B2297C58BEC1ED4
- Windows: flutter_miuix-1.2.1-windows.zip; 1614523 bytes; 270 entries; SHA-256 DDDB8B42563F24E32DD17A9EF6665A7FB8848D26C450B51EC0AE9F1EFC60789A
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30580000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30580000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.