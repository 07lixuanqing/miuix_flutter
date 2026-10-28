# Release artifacts

Current complete Release cycle: 1.2.1+30690000.

Android test application:

- Stable file: flutter_miuix_example-1.2.1-android-arm64-v8a-release.apk
- Checkpoint: flutter_miuix_example-1.2.1-android-arm64-v8a-release-30690000.apk
- ABI: arm64-v8a only
- Package: com.xinxin.miuix_flutter
- Size: 45381313 bytes
- SHA-256: EB6B66CE1C02C886A87AAD62563ED9FDA1BABF32F6A66F4BABAEB66C1BED2D48
- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only

Windows test application:

- Stable file: flutter_miuix_example-v1.2.1-windows-x64-release.zip
- Checkpoint: flutter_miuix_example-v1.2.1-windows-x64-release-30690000.zip
- Architecture: Windows x64 Release
- Size: 38138128 bytes; 60 ZIP entries
- SHA-256: A5E8B3A1A85F0F0E164D7EAE43BF4FAE42BE07736B4571D599543921C339F759

Reusable flutter_miuix libraries:

- Android: flutter_miuix-1.2.1-android.zip; 1705401 bytes; 288 entries; SHA-256 610FB84C9872D43FCC6B70F933EAFC86A4A7FA26D4FD757AB7DD2CB056542B92
- Windows: flutter_miuix-1.2.1-windows.zip; 1703175 bytes; 288 entries; SHA-256 79A43BFA1FCBC2690EB6DC189B08D81443D82F1DE609913A68018D2D81B645B7
- Hash manifest: flutter_miuix-1.2.1-SHA256SUMS.txt
- Android checkpoint: flutter_miuix-1.2.1-android-30690000.zip
- Windows checkpoint: flutter_miuix-1.2.1-windows-30690000.zip

Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.

Run this command after each completed modification phase:

.\tool\build_release_cycle.ps1

Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds.