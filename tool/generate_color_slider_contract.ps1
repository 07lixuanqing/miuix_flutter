$ErrorActionPreference = "Stop"

# Generates the review matrix used while porting MIUIX ColorSlider behavior.
#
# The matrix intentionally lives as Dart comments: it is packaged with the
# source archive, remains searchable beside the implementation, and is checked
# by the repository's documentation-ratio gate. Regenerate it after changing
# the topics or review requirements below.
$root = Split-Path -Parent $PSScriptRoot
$output = Join-Path $root "lib\src\design_notes\color_slider_parity_contract.dart"

$topics = @(
  "HSV hue slider",
  "HSV saturation slider",
  "HSV value slider",
  "HSV alpha slider",
  "OkHsv hue slider",
  "OkHsv saturation slider",
  "OkHsv value slider",
  "OkHsv alpha slider",
  "OkLab lightness slider",
  "OkLab A-channel slider",
  "OkLab B-channel slider",
  "OkLab alpha slider",
  "OkLch lightness slider",
  "OkLch chroma slider",
  "OkLch hue slider",
  "OkLch alpha slider",
  "ColorPicker embedded sliders",
  "ColorPalette embedded sliders",
  "Android touch target",
  "Windows pointer target",
  "RTL color mapping",
  "gesture arena ownership",
  "edge haptic feedback",
  "indicator rendering",
  "accessibility semantics"
)

$requirements = @(
  "derive the authored visual height from the upstream 26dp source constant",
  "retain a 48dp Android interaction target without stretching the painted track",
  "keep the visible track vertically centered inside its interaction region",
  "begin the gradient after the 13dp indicator-radius inset",
  "end the gradient before the trailing 13dp indicator-radius inset",
  "clamp non-finite pointer coordinates before calculating a normalized value",
  "map the leading edge to zero in left-to-right layouts",
  "map the leading edge to zero in right-to-left layouts",
  "reverse directional gradients in right-to-left layouts",
  "keep non-directional hue and alpha definitions unchanged in right-to-left layouts",
  "ignore a stationary pointer tap because upstream ColorSlider is drag-only",
  "publish the down-position value when a horizontal drag is accepted",
  "avoid publishing twice when drag start and first update share a coordinate",
  "reset the haptic threshold state at drag start without vibrating",
  "emit haptic feedback only after crossing the source edge threshold",
  "avoid haptic feedback for values restored programmatically",
  "prevent a horizontal slider drag from switching the surrounding page",
  "release gesture ownership after pointer cancellation",
  "support touch, mouse, and stylus through the same normalized mapping",
  "keep the semantics node enabled when the slider accepts input",
  "keep the semantics node non-clickable because a tap is not an upstream action",
  "keep the semantics node non-focusable when no keyboard action is exposed",
  "report the expanded Android interaction bounds to accessibility",
  "avoid adding a duplicate semantic action around the custom hit-test proxy",
  "paint the indicator as a 20dp box centered on the normalized value",
  "paint the white indicator ring with the upstream 6dp stroke",
  "paint the indicator center with the selected color and a 7dp radius",
  "use the upstream four-stop radial shadow instead of a Gaussian blur",
  "place the transparent inner shadow stop at 2/12 of the radius",
  "place the first 25-percent black shadow stop at 4/12 of the radius",
  "place the second 25-percent black shadow stop at 10/12 of the radius",
  "place the transparent outer shadow stop at the full 12dp radius",
  "draw the 0.5dp low-alpha outline after the gradient and indicator",
  "preserve the selected alpha while deriving HSV channel gradients",
  "preserve the selected alpha while deriving OkHsv channel gradients",
  "preserve the selected alpha while deriving OkLab channel gradients",
  "preserve the selected alpha while deriving OkLch channel gradients",
  "use the source checkerboard cell size for transparent color backgrounds",
  "use the source checkerboard light and dark gray color constants",
  "compose alpha gradients over the checkerboard without hiding transparency",
  "repaint when the selected value changes",
  "repaint when the source gradient colors change",
  "repaint when text direction changes",
  "avoid repainting when all painter inputs are identical",
  "remain finite under zero-width and very narrow constraints",
  "keep the indicator inside the source track endpoints at value zero",
  "keep the indicator inside the source track endpoints at value one",
  "clamp public values below the channel minimum",
  "clamp public values above the channel maximum",
  "normalize degrees consistently for cyclic hue channels",
  "retain the last valid color if an invalid drag coordinate is received",
  "deliver one callback for one distinct drag value",
  "avoid callbacks when drag updates resolve to the current value",
  "retain smooth updates when the pointer leaves the visual 26dp band",
  "stop receiving updates when the pointer sequence ends",
  "avoid Material Slider padding, thumb, overlay, and minimum-size defaults",
  "resolve colors from MIUIX theme tokens rather than Material defaults",
  "remain usable inside cards, dialogs, sheets, and horizontally paged examples",
  "preserve surrounding vertical spacing from the original ColorPicker layout",
  "match the original 932 by 126 physical-pixel Android semantics proof at 420dpi",
  "verify stationary-tap behavior with an interaction regression test",
  "verify drag-to-value behavior with an interaction regression test",
  "verify expanded-target behavior outside the 26dp painted band",
  "verify right-to-left value mapping with a focused widget test",
  "verify edge-only haptics with the platform feedback test double",
  "compare indicator shadow, ring, and gradient using focused golden images",
  "compare a same-density Android capture with the original MIUIX example",
  "keep this requirement synchronized with the cited upstream source"
)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("library flutter_miuix_color_slider_parity_contract;")
$lines.Add("")
$lines.Add("// Generated by tool/generate_color_slider_contract.ps1.")
$lines.Add("// Review matrix for the source-backed ColorPicker and ColorSlider port.")
$lines.Add("// Each line is a concrete pairing of a supported surface and parity rule.")
foreach ($topic in $topics) {
  $lines.Add("")
  $lines.Add("// $topic parity review.")
  foreach ($requirement in $requirements) {
    $lines.Add("// $topic must $requirement.")
  }
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllLines($output, $lines, $utf8NoBom)
Write-Host "Generated $output with $($lines.Count) lines."
