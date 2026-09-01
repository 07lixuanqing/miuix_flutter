# Release artifacts

Current complete Release cycle: 1.2.1+30590000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30590000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45154393 bytes
- SHA-256: 9689A7E7B073A29EDDC16FFC10E3E5CFC837FC8D3D0D9EA48B02DB71E94BF999
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30590000.zip
- Architecture: Windows x64 Release
- Size: 39063271 bytes; 60 ZIP entries
- SHA-256: 1702929FDAAA755C41D3D5D77016A6FB48489E8D9137111C75617053D10F27D0

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1630601 bytes; 271 entries; SHA-256 3A005018A7EAB8EF042E018ECB503539521BBA7122AC2A2FBC42DA91ED8A79B8
- Windows: flutter_miuix-1.2.1-windows.zip; 1628279 bytes; 271 entries; SHA-256 2D69A0990738BC0468C0DF5FB11841D938BDA73166A49ED5952661E9444D79E1
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30590000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30590000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.