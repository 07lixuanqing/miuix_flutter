# Release artifacts

Current complete Release cycle: 1.2.1+30672000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30672000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381313 bytes
- SHA-256: 19F8057DA74FBEC8E45ABB5733D6734565C40B72870CB232FB7E76084E3EA12F
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30672000.zip
- Architecture: Windows x64 Release
- Size: 38138692 bytes; 60 ZIP entries
- SHA-256: 9B11CAB859E7F4ECF8D3E81AA78BB958148A8EDC4C85054E4852895D5776C672

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1698731 bytes; 286 entries; SHA-256 58DD26C1CEB02BC631716BAC79688D22DB17667B71EE7E6BD36527F967EDAE49
- Windows: flutter_miuix-1.2.1-windows.zip; 1696505 bytes; 286 entries; SHA-256 3213D249A9B563A2A6A97B772EFC0DC249E797BC6DC91C492A045F48DFCA6636
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30672000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30672000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.