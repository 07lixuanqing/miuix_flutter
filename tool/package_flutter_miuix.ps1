param(
  [string]$Version = "1.2.0",
  [string]$BuildNumber,
  [string]$Destination
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($Destination)) {
  $Destination = Join-Path $root "releases"
}

$destinationPath = [System.IO.Path]::GetFullPath($Destination)
New-Item -ItemType Directory -Force -Path $destinationPath | Out-Null
$destinationPath = (Resolve-Path $destinationPath).Path
$stageBase = Join-Path $destinationPath (".flutter_miuix_pack_" + [guid]::NewGuid().ToString("N"))
$stageBaseFull = [System.IO.Path]::GetFullPath($stageBase)
if (-not $stageBaseFull.StartsWith($destinationPath, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Unsafe staging path: $stageBaseFull"
}

$metadataFiles = @(
  ".pubignore",
  "analysis_options.yaml",
  "CHANGELOG.md",
  "LICENSE",
  "pubspec.yaml",
  "README.md"
)
$packageDirectories = @("android", "assets", "doc", "lib", "shaders")
$outputs = @()

# A full release cycle passes the Android-verified build number explicitly. A
# direct packaging invocation falls back to the same value in the example
# manifest so library checkpoint names remain aligned with application builds.
if ([string]::IsNullOrWhiteSpace($BuildNumber)) {
  $versionLine = Get-Content -LiteralPath (Join-Path $root "example\pubspec.yaml") |
    Where-Object { $_ -match '^version:\s*' } |
    Select-Object -First 1
  if ($versionLine -notmatch '\+(\d+)\s*$') {
    throw "Could not read the library checkpoint build number."
  }
  $BuildNumber = $Matches[1]
}

# Compress-Archive writes backslashes into entry names on some Windows
# PowerShell versions. ZIP paths are portable only when they use forward
# slashes, so create entries explicitly instead of relying on shell defaults.
function New-PortableZipArchive {
  param(
    [Parameter(Mandatory = $true)][string]$SourceRoot,
    [Parameter(Mandatory = $true)][string]$Archive
  )

  # Windows PowerShell 5.1 keeps ZipArchive and ZipFile in separate assemblies.
  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $sourcePath = (Resolve-Path $SourceRoot).Path.TrimEnd('\', '/')
  $prefix = $sourcePath + [System.IO.Path]::DirectorySeparatorChar
  $stream = [System.IO.File]::Open(
    $Archive,
    [System.IO.FileMode]::CreateNew,
    [System.IO.FileAccess]::ReadWrite,
    [System.IO.FileShare]::None
  )
  try {
    $zip = [System.IO.Compression.ZipArchive]::new(
      $stream,
      [System.IO.Compression.ZipArchiveMode]::Create,
      $false
    )
    try {
      foreach ($file in Get-ChildItem -LiteralPath $sourcePath -File -Recurse) {
        $entryName = $file.FullName.Substring($prefix.Length).Replace('\', '/')
        $entry = $zip.CreateEntry(
          $entryName,
          [System.IO.Compression.CompressionLevel]::Optimal
        )
        $entryStream = $entry.Open()
        $fileStream = $file.OpenRead()
        try {
          $fileStream.CopyTo($entryStream)
        }
        finally {
          $fileStream.Dispose()
          $entryStream.Dispose()
        }
      }
    }
    finally {
      $zip.Dispose()
    }
  }
  finally {
    $stream.Dispose()
  }
}

function New-PlatformArchive {
  param(
    [Parameter(Mandatory = $true)][string]$Platform,
    [Parameter(Mandatory = $true)][string]$PlatformGuide
  )

  $platformStage = Join-Path $stageBaseFull $Platform
  $packageRoot = Join-Path $platformStage "flutter_miuix"
  New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

  foreach ($file in $metadataFiles) {
    Copy-Item -LiteralPath (Join-Path $root $file) -Destination $packageRoot
  }
  foreach ($directory in $packageDirectories) {
    Copy-Item -LiteralPath (Join-Path $root $directory) -Destination $packageRoot -Recurse
  }
  Copy-Item -LiteralPath (Join-Path $root $PlatformGuide) -Destination (Join-Path $packageRoot "PLATFORM.md")

  $archive = Join-Path $destinationPath "flutter_miuix-$Version-$Platform.zip"
  if (Test-Path -LiteralPath $archive) {
    Remove-Item -LiteralPath $archive -Force
  }
  New-PortableZipArchive -SourceRoot $platformStage -Archive $archive
  $script:outputs += $archive
}

try {
  New-PlatformArchive -Platform "android" -PlatformGuide "doc\ANDROID.md"
  New-PlatformArchive -Platform "windows" -PlatformGuide "doc\WINDOWS.md"

  $hashFile = Join-Path $destinationPath "flutter_miuix-$Version-SHA256SUMS.txt"
  $hashLines = foreach ($archive in $outputs) {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash
    "$hash  $([System.IO.Path]::GetFileName($archive))"
  }
  [System.IO.File]::WriteAllLines(
    $hashFile,
    $hashLines,
    [System.Text.UTF8Encoding]::new($false)
  )

  # Stable package names are convenient dependency downloads; numbered copies
  # provide three-cycle rollback points and are pruned only after the complete
  # Android/Windows release workflow has succeeded.
  $checkpointOutputs = @()
  foreach ($archive in @($outputs)) {
    $leaf = [System.IO.Path]::GetFileName($archive)
    if ($leaf -notmatch '-(android|windows)\.zip$') {
      throw "Unexpected library archive name: $leaf"
    }
    $platform = $Matches[1]
    $checkpoint = Join-Path $destinationPath (
      "flutter_miuix-$Version-$platform-$BuildNumber.zip"
    )
    Copy-Item -LiteralPath $archive -Destination $checkpoint -Force
    $checkpointOutputs += $checkpoint
  }
  $outputs += $hashFile
  $outputs += $checkpointOutputs

  foreach ($output in $outputs) {
    Get-Item -LiteralPath $output
  }
}
finally {
  if (Test-Path -LiteralPath $stageBaseFull) {
    $resolvedStage = (Resolve-Path $stageBaseFull).Path
    if (-not $resolvedStage.StartsWith($destinationPath, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove unsafe staging path: $resolvedStage"
    }
    Remove-Item -LiteralPath $resolvedStage -Recurse -Force
  }
}
