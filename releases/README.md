# Release artifacts

Current complete Release cycle: 1.2.1+30674000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30674000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381313 bytes
- SHA-256: 4CCE90C1055A99AD6CB8145652F199AF625047109C1EE8BEE6EB7CD32A9EC9F6
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30674000.zip
- Architecture: Windows x64 Release
- Size: 38487802 bytes; 60 ZIP entries
- SHA-256: A8EBDA040047CF99790495AA6F8F41D3FF7F1C744DDC63B562E9208A0566AB3E

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1704758 bytes; 286 entries; SHA-256 F7B0BC1FB82C265F663B5D9388F4E6E21A747330B99C3D2BB93091414210405B
- Windows: flutter_miuix-1.2.1-windows.zip; 1702436 bytes; 286 entries; SHA-256 710CE73AB9465348579FC1033DD667995FF2C5F12E5A6126D54F8382773B0ACB
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30674000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30674000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.