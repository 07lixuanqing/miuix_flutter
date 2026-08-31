# Release artifacts

Current complete Release cycle: 1.2.1+30582000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30582000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45154393 bytes
- SHA-256: BB1A54E6F00DAE9C4AFFC8BE2E0C1C0127349513B89116B203ADB4907B3AD969
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30582000.zip
- Architecture: Windows x64 Release
- Size: 39062570 bytes; 60 ZIP entries
- SHA-256: CD686E4865D91413E65D47B5D6B26F7CA01F4ECE27DD7F4BB732739F32E5CADD

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1617314 bytes; 270 entries; SHA-256 6ADDAF892CDB41DA9686E8BF63E1386EBD95AD75036B3F34781155D46BC20544
- Windows: flutter_miuix-1.2.1-windows.zip; 1614992 bytes; 270 entries; SHA-256 8A10A7D1A595455517F10FDA480CFBB41594DE7553C77D8C0A94CBCE1FD32D76
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30582000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30582000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.