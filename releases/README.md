# Release artifacts

Current complete Release cycle: 1.2.1+30584000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30584000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45154397 bytes
- SHA-256: CB757516EB9BD5170FF9267946E4EE84B782308735C422E5458E580822FD3D6B
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30584000.zip
- Architecture: Windows x64 Release
- Size: 39063575 bytes; 60 ZIP entries
- SHA-256: D1E60A10EC4C364ED6B09FCD3770042E8EE25B1E18B52C4EDDE4A4955BE4A7BB

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1618525 bytes; 270 entries; SHA-256 18CF2B8B7DFD1A38088C8D40B96E573E608A4363949308FE0A569F068DD01FF7
- Windows: flutter_miuix-1.2.1-windows.zip; 1616203 bytes; 270 entries; SHA-256 A71D9583F00EBA8106AD88104B5E98C8725D0AADCB0F934D6DDCF585FE02FE42
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30584000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30584000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.