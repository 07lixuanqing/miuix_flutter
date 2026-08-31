param(
    [string]$DeviceId = "",
    [string]$PackageName = "com.xinxin.miuix_flutter",
    [ValidateRange(10, 10000)][int]$MinimumFrames = 60,
    [ValidateRange(0, 100)][double]$MaximumJankyPercent = 5,
    [ValidateRange(1, 1000)][int]$MaximumP95Milliseconds = 24,
    [ValidateRange(4, 100)][int]$InteractionCount = 24,
    [switch]$AllowArm64EmulatorDiagnostic
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sdkRoot = $env:ANDROID_SDK_ROOT
if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
    $sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
}
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"
if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) {
    throw "adb was not found: $adb"
}
$adbArgs = @()
if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $adbArgs += @("-s", $DeviceId)
}
$stateOutput = @(& $adb @adbArgs get-state 2>$null)
$state = if ($stateOutput.Count -gt 0) {
    ([string]$stateOutput[0]).Trim()
}
else {
    "unavailable"
}
if ($state -ne "device") {
    throw "An online Android target is required. adb state: $state"
}
$abi = (& $adb @adbArgs shell getprop ro.product.cpu.abi).Trim()
if ($abi -notmatch '^arm64') {
    throw "Performance evidence requires an ARM64 target; connected ABI is $abi."
}
$isEmulator = ((& $adb @adbArgs shell getprop ro.kernel.qemu).Trim() -eq "1")
if ($isEmulator -and -not $AllowArm64EmulatorDiagnostic) {
    throw "Performance evidence requires an ARM64 physical device, not an emulator."
}

$packageDump = & $adb @adbArgs shell dumpsys package $PackageName 2>$null
if (($packageDump -join "`n") -notmatch "Package \[$([regex]::Escape($PackageName))\]") {
    throw "Package is not installed on the selected target: $PackageName"
}
& $adb @adbArgs shell dumpsys gfxinfo $PackageName reset | Out-Null
& $adb @adbArgs shell am force-stop $PackageName | Out-Null
& $adb @adbArgs shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep -Seconds 3

$sizeText = (& $adb @adbArgs shell wm size | Select-Object -First 1).Trim()
$sizeMatch = [regex]::Match($sizeText, '(\d+)x(\d+)')
if (-not $sizeMatch.Success) {
    throw "Could not read Android display size: $sizeText"
}
$width = [int]$sizeMatch.Groups[1].Value
$height = [int]$sizeMatch.Groups[2].Value
$tabY = [int]($height * 0.94)
$tabXs = @(0.14, 0.38, 0.62, 0.86) | ForEach-Object { [int]($width * $_) }
for ($index = 0; $index -lt $InteractionCount; $index++) {
    $x = $tabXs[$index % $tabXs.Count]
    & $adb @adbArgs shell input tap $x $tabY | Out-Null
    Start-Sleep -Milliseconds 120
}

$gfx = @(& $adb @adbArgs shell dumpsys gfxinfo $PackageName)
$gfxText = $gfx -join "`n"
$framesMatch = [regex]::Match($gfxText, '(?im)^\s*Total frames rendered:\s*(\d+)')
$jankyMatch = [regex]::Match($gfxText, '(?im)^\s*Janky frames:\s*\d+\s*\(([\d.]+)%\)')
$p95Match = [regex]::Match($gfxText, '(?im)^\s*95th percentile:\s*(\d+)ms')
if (-not ($framesMatch.Success -and $jankyMatch.Success -and $p95Match.Success)) {
    throw "Android gfxinfo did not expose the required frame summary."
}
$frames = [int]$framesMatch.Groups[1].Value
$jankyPercent = [double]::Parse(
    $jankyMatch.Groups[1].Value,
    [Globalization.CultureInfo]::InvariantCulture
)
$p95 = [int]$p95Match.Groups[1].Value

$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$evidenceDirectory = Join-Path $root "artifacts\parity\performance_$stamp"
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null
$evidence = Join-Path $evidenceDirectory "gfxinfo.txt"
[IO.File]::WriteAllLines($evidence, $gfx, [Text.UTF8Encoding]::new($false))

if ($frames -lt $MinimumFrames) {
    throw "Only $frames frames were measured; at least $MinimumFrames are required. Evidence: $evidence"
}
if ($jankyPercent -gt $MaximumJankyPercent) {
    throw "Janky frames $jankyPercent% exceed $MaximumJankyPercent%. Evidence: $evidence"
}
if ($p95 -gt $MaximumP95Milliseconds) {
    throw "95th percentile ${p95}ms exceeds ${MaximumP95Milliseconds}ms. Evidence: $evidence"
}

Write-Host "Android frame gate passed: ABI=$abi emulator=$isEmulator frames=$frames janky=$jankyPercent% p95=${p95}ms"
Write-Host "Evidence: $evidence"
