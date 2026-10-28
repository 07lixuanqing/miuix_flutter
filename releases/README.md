# Release artifacts

Current complete Release cycle: 1.2.1+30702000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30702000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381313 bytes
- SHA-256: 4A989C812BB3CF554DA3D54EEC097DB480237D2A08BC3C26A0B4846E5448867C
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30702000.zip
- Architecture: Windows x64 Release
- Size: 38141138 bytes; 60 ZIP entries
- SHA-256: 77A6DFBC82C6CE86021F10E4F2F4D7892439E451B305308980F3EE139706BE93

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1715423 bytes; 291 entries; SHA-256 20DA531FEDAFC1CE2DB54E8F985766ADF3821AB7622413E11357FF413DAD0261
- Windows: flutter_miuix-1.2.1-windows.zip; 1713197 bytes; 291 entries; SHA-256 FE2E6F402613A600D307DDA13BDE647FAB5961A8B705A7A091DD767EFB24C9B6
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30702000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30702000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.