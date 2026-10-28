# Release artifacts

Current complete Release cycle: 1.2.1+30696000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30696000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381313 bytes
- SHA-256: 984636D60CFDE483A70B699B66B97CBFB4BA4271A6F61F3881C7F29CE5B6C916
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30696000.zip
- Architecture: Windows x64 Release
- Size: 38141779 bytes; 60 ZIP entries
- SHA-256: A272A13ED8CF624EAA056CE7F7E9091E8953C7DA412CC3945A6A5370170715A5

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1707510 bytes; 289 entries; SHA-256 1EECFBDBD28C8BAF32E5A777FF901B7AE3ACE4591C3B427F8173781331BCBB25
- Windows: flutter_miuix-1.2.1-windows.zip; 1705284 bytes; 289 entries; SHA-256 C84C8D0972F5C0360447A0F468A7C587254E8D0B9810DBE93FAAA92119DFB7AE
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30696000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30696000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.