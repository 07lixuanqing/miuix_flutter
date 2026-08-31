param(
    [ValidateRange(0, 20)][int]$Keep = 1,
    [ValidateRange(0, 8760)][int]$MinimumAgeHours = 0,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$build = Join-Path $root "build"
if (-not (Test-Path -LiteralPath $build -PathType Container)) {
    Write-Host "Build cache directory does not exist: $build"
    exit 0
}
$build = (Resolve-Path -LiteralPath $build).Path.TrimEnd('\', '/')
$families = @(
    [pscustomobject]@{ Name = "windows_artifact_smoke"; Pattern = '^windows_artifact_smoke(?:_|$)' },
    [pscustomobject]@{ Name = "package_verify"; Pattern = '^(?:final_)?package_verify(?:_|$)' },
    [pscustomobject]@{ Name = "library_package_verify"; Pattern = '^library_package_verify(?:_|$)' },
    [pscustomobject]@{ Name = "library_consumers"; Pattern = '^library_consumers(?:_|$)' }
)
$now = [DateTime]::UtcNow
$selected = @()

function Assert-SafeBuildCacheDirectory {
    param(
        [Parameter(Mandatory = $true)][System.IO.DirectoryInfo]$Directory,
        [Parameter(Mandatory = $true)][string]$Pattern
    )

    if (($Directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing to remove a reparse point: $($Directory.FullName)"
    }
    $resolved = (Resolve-Path -LiteralPath $Directory.FullName).Path.TrimEnd('\', '/')
    $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
    if (-not $parent.Equals($build, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a directory outside build: $resolved"
    }
    if ($Directory.Name -notmatch $Pattern) {
        throw "Refusing to remove an unexpected build directory: $resolved"
    }
    return $resolved
}

foreach ($family in $families) {
    $matches = @(
        Get-ChildItem -LiteralPath $build -Directory |
            Where-Object { $_.Name -match $family.Pattern } |
            Sort-Object LastWriteTimeUtc, Name -Descending
    )
    foreach ($directory in @($matches | Select-Object -Skip $Keep)) {
        $ageHours = ($now - $directory.LastWriteTimeUtc).TotalHours
        if ($ageHours -lt $MinimumAgeHours) {
            continue
        }
        $resolved = Assert-SafeBuildCacheDirectory `
            -Directory $directory `
            -Pattern $family.Pattern
        $measure = Get-ChildItem -LiteralPath $resolved -Recurse -File -ErrorAction Stop |
            Measure-Object -Property Length -Sum
        $selected += [pscustomobject]@{
            Family = $family.Name
            Path = $resolved
            Files = $measure.Count
            Bytes = [long]$measure.Sum
            LastWriteTimeUtc = $directory.LastWriteTimeUtc
        }
    }
}

foreach ($entry in $selected) {
    if ($Apply) {
        # The resolved direct-child path was checked immediately above. These
        # directories contain reproducible compiler/package verification output.
        Remove-Item -LiteralPath $entry.Path -Recurse -Force
        Write-Host "Removed build verification cache: $($entry.Path)"
    }
    else {
        Write-Host "Would remove build verification cache: $($entry.Path)"
    }
}

$totalBytes = [long](($selected | Measure-Object -Property Bytes -Sum).Sum)
Write-Host (
    "Build cache retention selected {0} directories ({1} bytes); mode={2}." -f
    $selected.Count,
    $totalBytes,
    $(if ($Apply) { "apply" } else { "preview" })
)
