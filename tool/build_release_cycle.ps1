param(
  [string]$Version = "1.2.1",
  [ValidateRange(1, 20)][int]$Keep = 3,
  [ValidateRange(0, 20)][int]$BuildCacheKeep = 1
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$example = Join-Path $root "example"
$flutter = $env:FLUTTER_BIN
if ([string]::IsNullOrWhiteSpace($flutter)) {
  $flutter = "C:\Code\_tools\flutter\bin\flutter.bat"
}
if (-not (Test-Path -LiteralPath $flutter)) {
  $flutter = "flutter"
}

# A Release cycle must prove the reusable package and its reference app before
# allocating a new Android versionCode or replacing any stable artifact. This
# keeps a failed analysis/test run from producing a newer-looking half release.
Push-Location $root
try {
  & $flutter analyze lib test
  if ($LASTEXITCODE -ne 0) {
    throw "Library analysis failed with exit code $LASTEXITCODE."
  }
  & $flutter test
  if ($LASTEXITCODE -ne 0) {
    throw "Library tests failed with exit code $LASTEXITCODE."
  }
}
finally {
  Pop-Location
}

Push-Location $example
try {
  & $flutter analyze
  if ($LASTEXITCODE -ne 0) {
    throw "Example analysis failed with exit code $LASTEXITCODE."
  }
  & $flutter test
  if ($LASTEXITCODE -ne 0) {
    throw "Example tests failed with exit code $LASTEXITCODE."
  }
}
finally {
  Pop-Location
}

# Android allocates and verifies the cycle's monotonic build number first. The
# verified final split versionCode is then shared by every checkpoint filename.
& (Join-Path $PSScriptRoot "build_android_arm64_release.ps1")
if ($LASTEXITCODE -ne 0) {
  throw "Android Release build failed with exit code $LASTEXITCODE."
}
$versionLine = Get-Content -LiteralPath (Join-Path $example "pubspec.yaml") |
  Where-Object { $_ -match '^version:\s*' } |
  Select-Object -First 1
if ($versionLine -notmatch '^version:\s*([^+]+)\+(\d+)\s*$') {
  throw "Could not read the verified Release version from example/pubspec.yaml."
}
$actualVersion = $Matches[1].Trim()
$buildNumber = $Matches[2]
if ($actualVersion -ne $Version) {
  throw "Requested version $Version does not match example version $actualVersion."
}

Push-Location $example
try {
  & $flutter build windows --release
  if ($LASTEXITCODE -ne 0) {
    throw "Windows Release build failed with exit code $LASTEXITCODE."
  }
}
finally {
  Pop-Location
}

# A successful compiler exit is followed by a real process smoke check. Hidden
# launch avoids opening a stray desktop window during an automated release.
$windowsExe = Join-Path $example "build\windows\x64\runner\Release\miuix_flutter_example.exe"
$process = Start-Process `
  -FilePath $windowsExe `
  -WorkingDirectory (Split-Path $windowsExe) `
  -WindowStyle Hidden `
  -PassThru
try {
  Start-Sleep -Seconds 5
  $process.Refresh()
  if ($process.HasExited -or -not $process.Responding) {
    throw "Windows Release smoke process exited or stopped responding."
  }
}
finally {
  if (-not $process.HasExited) {
    Stop-Process -Id $process.Id -Force
  }
}

& (Join-Path $PSScriptRoot "package_windows_example.ps1") `
  -Version $Version `
  -BuildNumber $buildNumber
& (Join-Path $PSScriptRoot "package_flutter_miuix.ps1") `
  -Version $Version `
  -BuildNumber $buildNumber

# The developer-facing release manifest is generated from the artifacts that
# have just passed this cycle. Keeping these values here avoids a stale manual
# README claiming that an older checkpoint is still the latest download.
Add-Type -AssemblyName System.IO.Compression
$releaseDirectory = Join-Path $root "releases"
$androidApk = Join-Path $releaseDirectory (
  "flutter_miuix_example-$Version-android-arm64-v8a-release.apk"
)
$windowsArchive = Join-Path $releaseDirectory (
  "flutter_miuix_example-v$Version-windows-x64-release.zip"
)
$androidLibrary = Join-Path $releaseDirectory "flutter_miuix-$Version-android.zip"
$windowsLibrary = Join-Path $releaseDirectory "flutter_miuix-$Version-windows.zip"

function Get-ReleaseArchiveEntryCount {
  param([Parameter(Mandatory = $true)][string]$Archive)

  $stream = [System.IO.File]::OpenRead($Archive)
  try {
    $zip = [System.IO.Compression.ZipArchive]::new(
      $stream,
      [System.IO.Compression.ZipArchiveMode]::Read,
      $false
    )
    try {
      return $zip.Entries.Count
    }
    finally {
      $zip.Dispose()
    }
  }
  finally {
    $stream.Dispose()
  }
}

# Read every size and digest from the stable alias after packaging. Numbered
# checkpoints are byte-identical copies, so one digest documents both names.
$androidItem = Get-Item -LiteralPath $androidApk
$windowsItem = Get-Item -LiteralPath $windowsArchive
$androidLibraryItem = Get-Item -LiteralPath $androidLibrary
$windowsLibraryItem = Get-Item -LiteralPath $windowsLibrary
$androidHash = (Get-FileHash -LiteralPath $androidApk -Algorithm SHA256).Hash
$windowsHash = (Get-FileHash -LiteralPath $windowsArchive -Algorithm SHA256).Hash
$androidLibraryHash = (
  Get-FileHash -LiteralPath $androidLibrary -Algorithm SHA256
).Hash
$windowsLibraryHash = (
  Get-FileHash -LiteralPath $windowsLibrary -Algorithm SHA256
).Hash
$windowsEntries = Get-ReleaseArchiveEntryCount -Archive $windowsArchive
$androidLibraryEntries = Get-ReleaseArchiveEntryCount -Archive $androidLibrary
$windowsLibraryEntries = Get-ReleaseArchiveEntryCount -Archive $windowsLibrary
$releaseReadme = Join-Path $releaseDirectory "README.md"
$releaseManifest = @(
  "# Release artifacts",
  "",
  "Current complete Release cycle: $Version+$buildNumber.",
  "",
  "Android test application:",
  "",
  "- Stable file: flutter_miuix_example-$Version-android-arm64-v8a-release.apk",
  "- Checkpoint: flutter_miuix_example-$Version-android-arm64-v8a-release-$buildNumber.apk",
  "- ABI: arm64-v8a only",
  "- Package: com.xinxin.miuix_flutter",
  "- Size: $($androidItem.Length) bytes",
  "- SHA-256: $androidHash",
  "- Signature: APK Signature Scheme v2; local Android Debug certificate for test distribution only",
  "",
  "Windows test application:",
  "",
  "- Stable file: flutter_miuix_example-v$Version-windows-x64-release.zip",
  "- Checkpoint: flutter_miuix_example-v$Version-windows-x64-release-$buildNumber.zip",
  "- Architecture: Windows x64 Release",
  "- Size: $($windowsItem.Length) bytes; $windowsEntries ZIP entries",
  "- SHA-256: $windowsHash",
  "",
  "Reusable flutter_miuix libraries:",
  "",
  "- Android: flutter_miuix-$Version-android.zip; $($androidLibraryItem.Length) bytes; $androidLibraryEntries entries; SHA-256 $androidLibraryHash",
  "- Windows: flutter_miuix-$Version-windows.zip; $($windowsLibraryItem.Length) bytes; $windowsLibraryEntries entries; SHA-256 $windowsLibraryHash",
  "- Hash manifest: flutter_miuix-$Version-SHA256SUMS.txt",
  "- Android checkpoint: flutter_miuix-$Version-android-$buildNumber.zip",
  "- Windows checkpoint: flutter_miuix-$Version-windows-$buildNumber.zip",
  "",
  "Both library archives include README.md, PLATFORM.md, doc, lib, assets, and shaders. See doc/GETTING_STARTED_ZH.md for integration instructions.",
  "",
  "Run this command after each completed modification phase:",
  "",
  ".\tool\build_release_cycle.ps1",
  "",
  "Stable names always point to the latest artifacts and do not count as history. The Android app, Windows app, Android library, and Windows library each retain the newest three numbered checkpoints. Older checkpoints are pruned only after the complete cycle succeeds."
) -join [System.Environment]::NewLine
[System.IO.File]::WriteAllText(
  $releaseReadme,
  $releaseManifest,
  [System.Text.UTF8Encoding]::new($false)
)

# Retention is deliberately last: a failure above keeps all previously known
# good checkpoints. Only a fully assembled cycle is allowed to prune history.
& (Join-Path $PSScriptRoot "prune_release_checkpoints.ps1") -Keep $Keep
& (Join-Path $PSScriptRoot "prune_build_verification_cache.ps1") `
  -Keep $BuildCacheKeep `
  -Apply

Write-Host "Completed Release cycle $Version+$buildNumber."
