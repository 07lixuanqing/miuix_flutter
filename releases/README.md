# Release artifacts

Current complete Release cycle: 1.2.1+30688000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30688000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381309 bytes
- SHA-256: 85897EC17353109F8280AA1F723B2D9CEAC0E7633CE128A2F89CA5E078E9C2F3
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30688000.zip
- Architecture: Windows x64 Release
- Size: 38137875 bytes; 60 ZIP entries
- SHA-256: 7E45E1B1EB32FD4882C9587067A2D522840261C31A00B988A047339A80ECE81E

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1704525 bytes; 288 entries; SHA-256 C3518043FD43319F84074DBF9826FA6EF6030E0940B233EF1411431DB3FE9DFB
- Windows: flutter_miuix-1.2.1-windows.zip; 1702299 bytes; 288 entries; SHA-256 4D2B269CB9A40B13FBAB9DF1F1D17092A0414B077DEFE9B04D91F055EFF2B730
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30688000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30688000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.