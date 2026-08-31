param(
  [string]$Destination,
  [ValidateRange(1, 20)][int]$Keep = 3
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($Destination)) {
  $Destination = Join-Path $root "releases"
}

# Resolve the release directory once and permit deletion only for direct child
# files. This makes retention independent of the caller's current directory and
# prevents a malformed pattern from escaping the intended artifact directory.
$destinationPath = [System.IO.Path]::GetFullPath($Destination)
if (-not (Test-Path -LiteralPath $destinationPath -PathType Container)) {
  throw "Release directory does not exist: $destinationPath"
}
$destinationPath = (Resolve-Path -LiteralPath $destinationPath).Path.TrimEnd('\', '/')

function Assert-DirectReleaseFile {
  param([Parameter(Mandatory = $true)][System.IO.FileInfo]$File)

  $parent = [System.IO.Path]::GetDirectoryName($File.FullName).TrimEnd('\', '/')
  if (-not $parent.Equals($destinationPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove a file outside the release directory: $($File.FullName)"
  }
}

function Remove-ReleaseFile {
  param([Parameter(Mandatory = $true)][System.IO.FileInfo]$File)

  Assert-DirectReleaseFile -File $File
  Remove-Item -LiteralPath $File.FullName -Force

  # APK checkpoints may have an adjacent SHA-256 sidecar. Treat the pair as one
  # retained artifact so a deleted binary cannot leave a misleading checksum.
  $sidecarPath = "$($File.FullName).sha256"
  if (Test-Path -LiteralPath $sidecarPath -PathType Leaf) {
    $sidecar = Get-Item -LiteralPath $sidecarPath
    Assert-DirectReleaseFile -File $sidecar
    Remove-Item -LiteralPath $sidecar.FullName -Force
  }
  Write-Host "Removed old Release artifact: $($File.Name)"
}

function Keep-NewestMatchingFiles {
  param(
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][int]$Retain
  )

  # Last-write time represents successful package completion. The name is a
  # deterministic tie-breaker when several copies share a filesystem timestamp.
  $matches = @(
    Get-ChildItem -LiteralPath $destinationPath -File |
      Where-Object { $_.Name -match $Pattern } |
      Sort-Object LastWriteTimeUtc, Name -Descending
  )
  foreach ($file in @($matches | Select-Object -Skip $Retain)) {
    Remove-ReleaseFile -File $file
  }
}

# Numbered checkpoints retain the newest three independently for every target.
Keep-NewestMatchingFiles -Retain $Keep -Pattern '^flutter_miuix_example-.+-android-arm64-v8a-release-\d+\.apk$'
Keep-NewestMatchingFiles -Retain $Keep -Pattern '^flutter_miuix_example-v.+-windows-x64-release-\d+\.zip$'
Keep-NewestMatchingFiles -Retain $Keep -Pattern '^flutter_miuix-.+-android-\d+\.zip$'
Keep-NewestMatchingFiles -Retain $Keep -Pattern '^flutter_miuix-.+-windows-\d+\.zip$'

# Stable aliases are convenience download names, so only the newest semantic
# version remains. They are not counted among the three numbered checkpoints.
Keep-NewestMatchingFiles -Retain 1 -Pattern '^flutter_miuix_example-.+-android-arm64-v8a-release\.apk$'
Keep-NewestMatchingFiles -Retain 1 -Pattern '^flutter_miuix_example-v.+-windows-x64-release\.zip$'
Keep-NewestMatchingFiles -Retain 1 -Pattern '^flutter_miuix-.+-android\.zip$'
Keep-NewestMatchingFiles -Retain 1 -Pattern '^flutter_miuix-.+-windows\.zip$'
Keep-NewestMatchingFiles -Retain 1 -Pattern '^flutter_miuix-.+-SHA256SUMS\.txt$'

# These names predate the current verified artifact scheme and cannot serve as
# one of its traceable checkpoints. They are removed after a complete new cycle.
Keep-NewestMatchingFiles -Retain 0 -Pattern '^flutter_miuix_example-.+-android-release\.apk$'
Keep-NewestMatchingFiles -Retain 0 -Pattern '^flutter_miuix-example-.+-android-arm64-release\.apk$'
Keep-NewestMatchingFiles -Retain 0 -Pattern '^flutter_miuix_example-v.+-arm64-v8a-release\.apk$'

Write-Host "Release retention complete: newest $Keep numbered checkpoints per artifact family."
