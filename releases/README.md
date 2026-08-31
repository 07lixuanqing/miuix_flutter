# Release artifacts

Current complete Release cycle: 1.2.1+30578000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30578000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45153085 bytes
- SHA-256: 2934274F1D350A7D7502100E7579BF87EFBFFFFB4212679131061C702D511E00
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30578000.zip
- Architecture: Windows x64 Release
- Size: 39061147 bytes; 60 ZIP entries
- SHA-256: 27659530C652A34A8C41602F5F963F941BE467BF26FD899DE7C428969716B6EE

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1615515 bytes; 270 entries; SHA-256 1D74B1A1FEA4AED598D245554D6F679890BC2421C14C2AC8392CE289DC9E8098
- Windows: flutter_miuix-1.2.1-windows.zip; 1613193 bytes; 270 entries; SHA-256 531A65DBFE57DB679E7559F20F6028B961E1BC81894F28AA8F56F81A3B465D3F
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30578000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30578000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.