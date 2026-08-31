param(
  [string]$Version = "1.2.0",
  [string]$BuildNumber,
  [string]$Destination
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = Join-Path $root "example\build\windows\x64\runner\Release"

# The Android release builder writes the final split versionCode back to the
# example manifest. Reusing that value gives both platform archives one stable
# checkpoint identifier without requiring a second manually maintained number.
if ([string]::IsNullOrWhiteSpace($BuildNumber)) {
  $manifest = Get-Content -LiteralPath (Join-Path $root "example\pubspec.yaml")
  $versionLine = $manifest | Where-Object { $_ -match "^version:\s*" } |
    Select-Object -First 1
  if ($versionLine -notmatch "\+(\d+)\s*$") {
    throw "Could not read the example build number from pubspec.yaml."
  }
  $BuildNumber = $Matches[1]
}

if ([string]::IsNullOrWhiteSpace($Destination)) {
  $Destination = Join-Path $root "releases"
}
if (-not (Test-Path -LiteralPath $source -PathType Container)) {
  throw "Windows release output is missing: $source"
}

$destinationPath = [System.IO.Path]::GetFullPath($Destination)
New-Item -ItemType Directory -Force -Path $destinationPath | Out-Null
$destinationPath = (Resolve-Path $destinationPath).Path
$stableArchive = Join-Path $destinationPath (
  "flutter_miuix_example-v$Version-windows-x64-release.zip"
)
$checkpointArchive = Join-Path $destinationPath (
  "flutter_miuix_example-v$Version-windows-x64-release-$BuildNumber.zip"
)

# ZipArchive is used explicitly because Compress-Archive can emit Windows
# backslashes. A distributable ZIP must use forward-slash paths on every host.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Remove-Item -LiteralPath $stableArchive -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $checkpointArchive -Force -ErrorAction SilentlyContinue

$sourcePath = (Resolve-Path $source).Path.TrimEnd('\', '/')
$prefix = $sourcePath + [System.IO.Path]::DirectorySeparatorChar
$stream = [System.IO.File]::Open(
  $stableArchive,
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
    # Preserve explicit directory entries as well as files. This matches the
    # portable release layout users get after extracting on Windows or Linux.
    foreach ($directory in Get-ChildItem -LiteralPath $sourcePath -Directory -Recurse |
      Sort-Object FullName) {
      $name = $directory.FullName.Substring($prefix.Length).Replace('\', '/') + "/"
      $entry = $zip.CreateEntry($name)
      $entry.LastWriteTime = $directory.LastWriteTime
    }
    foreach ($file in Get-ChildItem -LiteralPath $sourcePath -File -Recurse |
      Sort-Object FullName) {
      $name = $file.FullName.Substring($prefix.Length).Replace('\', '/')
      $entry = $zip.CreateEntry(
        $name,
        [System.IO.Compression.CompressionLevel]::Optimal
      )
      $entry.LastWriteTime = $file.LastWriteTime
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

# The checkpoint copy is byte-identical to the stable developer-facing name.
Copy-Item -LiteralPath $stableArchive -Destination $checkpointArchive

# Refuse to hand off an incomplete or platform-specific archive layout.
$readStream = [System.IO.File]::OpenRead($stableArchive)
try {
  $readZip = [System.IO.Compression.ZipArchive]::new(
    $readStream,
    [System.IO.Compression.ZipArchiveMode]::Read,
    $false
  )
  try {
    $entries = @($readZip.Entries)
    if ($entries.FullName -match "\\") {
      throw "Windows archive contains a non-portable backslash path."
    }
    $executables = @(
      $entries | Where-Object { $_.FullName -eq "miuix_flutter_example.exe" }
    )
    if ($executables.Count -ne 1) {
      throw "Windows archive must contain exactly one example executable."
    }
  }
  finally {
    $readZip.Dispose()
  }
}
finally {
  $readStream.Dispose()
}

foreach ($archive in @($stableArchive, $checkpointArchive)) {
  $item = Get-Item -LiteralPath $archive
  $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
  [pscustomobject]@{
    Path = $item.FullName
    Bytes = $item.Length
    Entries = $entries.Count
    SHA256 = $hash
  }
}
