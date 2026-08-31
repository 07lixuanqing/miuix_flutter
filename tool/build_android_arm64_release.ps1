param(
    # Override only when a CI pipeline owns Android versionCode allocation.
    [Nullable[int]]$BuildNumber = $null,
    # Install the finished APK on a connected device without removing app data.
    [switch]$Install,
    # Optional adb serial when more than one Android target is connected.
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$example = Join-Path $root "example"
$outputDir = Join-Path $example "build\app\outputs\flutter-apk"
$sourceApk = Join-Path $outputDir "app-arm64-v8a-release.apk"
$targetApk = Join-Path $outputDir "MIUIX-Flutter-Lab-arm64-v8a-release.apk"
$pubspecPath = Join-Path $example "pubspec.yaml"
$localPropertiesPath = Join-Path $example "android\local.properties"
$pubspecVersion = Select-String `
    -LiteralPath $pubspecPath `
    -Pattern "^version:\s*([^+]+)(?:\+(\d+))?"
if ($null -eq $pubspecVersion) {
    throw "The example version could not be read from pubspec.yaml"
}
$versionName = $pubspecVersion.Matches[0].Groups[1].Value.Trim()
$fallbackBuildNumber = 0
if ($pubspecVersion.Matches[0].Groups[2].Success) {
    $fallbackBuildNumber = [int]$pubspecVersion.Matches[0].Groups[2].Value
}
$releaseName = "flutter_miuix_example-$versionName-android-arm64-v8a-release.apk"
$releaseApk = Join-Path $root "releases\$releaseName"
$sourceSha = "$sourceApk.sha1"
$targetSha = "$targetApk.sha1"
$packageName = "com.xinxin.miuix_flutter"

# Resolve adb before allocating a build number. An install build must compare
# against the actual target device, because Flutter assigns different version
# code offsets to ABI splits. A previously installed x86_64 diagnostic build
# can therefore be newer than the next arm64 build even when both were made
# from the same pubspec version.
$sdkRoot = $env:ANDROID_SDK_ROOT
if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
    $sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
}
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"
$installDeviceArgs = @()
if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $installDeviceArgs += @("-s", $DeviceId)
}

# Start from both the clock and the last finished APK. Flutter adds the arm64
# split offset later. Keeping the finished code as the next base means a later
# scripted build can also replace an APK made by a direct Flutter invocation.
if ($null -eq $BuildNumber) {
    $clockBuildNumber = [int][Math]::Floor(
        [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() / 60
    )
    $BuildNumber = [Math]::Max($clockBuildNumber, $fallbackBuildNumber)
}

# `adb install -r` rejects every version-code downgrade. When installation was
# requested, make the base itself newer than the installed split rather than
# guessing Flutter's ABI-specific offset. The produced arm64 split then stays
# newer even if the target currently contains an x86_64 build with a larger
# offset. This also honors explicit CI build numbers unless they are unsafe for
# the requested in-place replacement.
$installedVersionCode = $null
if ($Install -and (Test-Path -LiteralPath $adb)) {
    $installedPackage = & $adb @installDeviceArgs shell dumpsys package $packageName 2>$null
    $installedVersionMatch = [regex]::Match(
        ($installedPackage -join "`n"),
        "(?m)\bversionCode=(\d+)"
    )
    if ($installedVersionMatch.Success) {
        $installedVersionCode = [int]$installedVersionMatch.Groups[1].Value
        $BuildNumber = [Math]::Max($BuildNumber, $installedVersionCode + 1)
    }
}

$flutter = $env:FLUTTER_BIN
if ([string]::IsNullOrWhiteSpace($flutter)) {
    $flutter = "C:\Code\_tools\flutter\bin\flutter.bat"
}
if (-not (Test-Path -LiteralPath $flutter)) {
    $flutter = "flutter"
}

Push-Location $example
try {
    & $flutter build apk `
        --release `
        --target-platform android-arm64 `
        --split-per-abi `
        --build-number $BuildNumber
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $sourceApk)) {
    throw "Expected arm64-v8a release APK was not produced: $sourceApk"
}

# Keep Flutter's conventional output and make stable convenience copies.
Copy-Item -LiteralPath $sourceApk -Destination $targetApk -Force
New-Item -ItemType Directory -Path (Split-Path $releaseApk) -Force | Out-Null
Copy-Item -LiteralPath $sourceApk -Destination $releaseApk -Force
if (Test-Path -LiteralPath $sourceSha) {
    Remove-Item -LiteralPath $sourceSha -Force
}

$hash = (Get-FileHash -LiteralPath $targetApk -Algorithm SHA1).Hash.ToLowerInvariant()
Set-Content -LiteralPath $targetSha -Value $hash -Encoding ASCII

Get-ChildItem -LiteralPath $outputDir -Filter "app-debug.apk" -ErrorAction SilentlyContinue |
    Remove-Item -Force

# Resolve Android SDK verification tools without depending on PATH ordering.
$buildToolsRoot = Join-Path $sdkRoot "build-tools"
$buildTools = Get-ChildItem -LiteralPath $buildToolsRoot -Directory |
    Sort-Object { [version]$_.Name } -Descending |
    Select-Object -First 1
if ($null -eq $buildTools) {
    throw "Android build-tools were not found under $buildToolsRoot"
}

# Fail the build hand-off if the package metadata or signature is malformed.
$aapt = Join-Path $buildTools.FullName "aapt.exe"
$apksigner = Join-Path $buildTools.FullName "apksigner.bat"
$badging = (& $aapt dump badging $releaseApk | Select-Object -First 1)
if ($badging -notmatch "name='com\.xinxin\.miuix_flutter'") {
    throw "Unexpected Android package metadata: $badging"
}
if ($badging -notmatch "versionCode='(\d+)'") {
    throw "The final Android versionCode could not be read: $badging"
}
$finalVersionCode = [int]$Matches[1]
& $apksigner verify --verbose --print-certs $releaseApk
if ($LASTEXITCODE -ne 0) {
    throw "APK signature verification failed: $releaseApk"
}

# Keep the stable artifact and its checksum inseparable. A stale sidecar makes
# a valid newly built APK look corrupt to developers and automated download
# checks, so refresh it only after package metadata and signing both pass.
$releaseSha256 = (Get-FileHash -LiteralPath $releaseApk -Algorithm SHA256).Hash
$releaseSha256Path = "$releaseApk.sha256"
Set-Content -LiteralPath $releaseSha256Path -Encoding ASCII -Value (
    "$releaseSha256 *$([IO.Path]::GetFileName($releaseApk))"
)

# Keep a numbered checkpoint in addition to the stable latest-download name.
# The release-cycle retention step keeps only the newest three checkpoints, so
# this copy remains traceable without allowing the directory to grow forever.
$checkpointName = (
    "flutter_miuix_example-$versionName-android-arm64-v8a-release-" +
    "$finalVersionCode.apk"
)
$checkpointApk = Join-Path $root "releases\$checkpointName"
Copy-Item -LiteralPath $releaseApk -Destination $checkpointApk -Force
Set-Content -LiteralPath "$checkpointApk.sha256" -Encoding ASCII -Value (
    "$releaseSha256 *$checkpointName"
)

# Direct `flutter build` and `flutter run` read this fallback. Record the code
# of the verified split APK so those paths never fall behind the last release.
$pubspecText = [IO.File]::ReadAllText($pubspecPath)
$updatedPubspecText = [regex]::Replace(
    $pubspecText,
    "(?m)^version:\s*[^\r\n]+$",
    "version: $versionName+$finalVersionCode",
    1
)
if ($updatedPubspecText -eq $pubspecText -and
    $pubspecText -notmatch "(?m)^version:\s*$([regex]::Escape($versionName))\+$finalVersionCode$") {
    throw "The pubspec version fallback could not be updated."
}
[IO.File]::WriteAllText(
    $pubspecPath,
    $updatedPubspecText,
    [Text.UTF8Encoding]::new($false)
)

# A direct Gradle invocation reads Flutter's generated local.properties rather
# than pubspec.yaml. The split build above records its pre-offset base there, so
# leaving it untouched would make a later `gradlew assembleRelease` lower than
# the installed arm64 APK by exactly Flutter's 2000-point ABI offset.
if (Test-Path -LiteralPath $localPropertiesPath) {
    $localPropertiesText = [IO.File]::ReadAllText($localPropertiesPath)
    if ($localPropertiesText -match "(?m)^flutter\.versionCode=") {
        $updatedLocalPropertiesText = [regex]::Replace(
            $localPropertiesText,
            "(?m)^flutter\.versionCode=.*$",
            "flutter.versionCode=$finalVersionCode",
            1
        )
    }
    else {
        $lineBreak = if ($localPropertiesText.EndsWith("`n")) { "" } else { "`r`n" }
        $updatedLocalPropertiesText =
            "$localPropertiesText$lineBreak" +
            "flutter.versionCode=$finalVersionCode`r`n"
    }
    [IO.File]::WriteAllText(
        $localPropertiesPath,
        $updatedLocalPropertiesText,
        [Text.UTF8Encoding]::new($false)
    )
}

# `-r` requests a true in-place replacement and preserves application data.
if ($Install) {
    $adbArgs = @($installDeviceArgs) + @("install", "-r", $releaseApk)
    & $adb @adbArgs
    if ($LASTEXITCODE -ne 0) {
        throw "In-place Android installation failed. Check signer and versionCode above."
    }
}

Write-Host "Built $releaseApk"
Write-Host "Android checkpoint: $checkpointApk"
Write-Host "Android base versionCode: $BuildNumber (arm64 split adds its ABI offset)"
Write-Host "Android final versionCode: $finalVersionCode"
Write-Host "Android SHA-256: $releaseSha256"
if ($null -ne $installedVersionCode) {
    Write-Host "Previously installed versionCode: $installedVersionCode"
}
