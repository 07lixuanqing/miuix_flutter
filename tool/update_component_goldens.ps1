$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$flutter = if (Test-Path "C:\Code\_tools\flutter\bin\flutter.bat") {
  "C:\Code\_tools\flutter\bin\flutter.bat"
} else {
  "flutter"
}

Push-Location $root
try {
  & $flutter test .\test\component_golden_test.dart --update-goldens
  if ($LASTEXITCODE -ne 0) {
    throw "Component golden update failed with exit code $LASTEXITCODE"
  }
} finally {
  Pop-Location
}
