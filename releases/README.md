# Release artifacts

Current complete Release cycle: 1.2.1+30708000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30708000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381313 bytes
- SHA-256: 906ABFB9CF1754EB568558C1FB860185838030D1B67BEF4BDFCF6088DFE02E27
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30708000.zip
- Architecture: Windows x64 Release
- Size: 38489098 bytes; 60 ZIP entries
- SHA-256: D862B1C10389AB5FF68C7D86EF0F39FB4D2D87F280875F99C7C32F47E07585E4

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1723658 bytes; 291 entries; SHA-256 CF76097A72876AF1D1CC44995B91D31694AA9D1114215B061136EED6BEBB1F28
- Windows: flutter_miuix-1.2.1-windows.zip; 1721336 bytes; 291 entries; SHA-256 0AD286476989CCAA81966871525388F448882BF6CDFCBBE0579EC9EE3B4BE68D
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30708000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30708000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.