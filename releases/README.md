# Release artifacts

Current complete Release cycle: 1.2.1+30606000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30606000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381313 bytes
- SHA-256: 00FD5576FCE76F3A8414E1DDAE95B5D05FA1A51B53A28B974155A6B429C35E89
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30606000.zip
- Architecture: Windows x64 Release
- Size: 38119646 bytes; 60 ZIP entries
- SHA-256: 8194267E0005346A53EA30D20BE8F152CFE3AA8A534287858921365A2337E846

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1657389 bytes; 273 entries; SHA-256 4908CFB668D7E87618B959EB20A4BFE27F0AC7FB8A3917E55202EB4E2F9969FA
- Windows: flutter_miuix-1.2.1-windows.zip; 1655163 bytes; 273 entries; SHA-256 B035EFF440C00935295A268BD54C7CB3B798F58FC1EE3DE44B7AE1020F233B3F
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30606000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30606000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.