# MIUIX component visual baselines

The visual regression suite covers all 54 entries currently listed by the MIUIX component
documentation (1 scaffold, 29 basic components, and 24 extended components).
Each component has six independent PNG baselines:

- `light`: enabled component in the light palette
- `dark`: enabled component in the dark palette
- `pressed`: pointer-down press feedback when the component is interactive
- `disabled`: the component's disabled configuration when it exposes one
- `expanded`: expanded, selected, wrapped, indeterminate, or open content where applicable
- `animationMidpoint`: the 90 ms midpoint of pointer-down feedback

Static components that do not expose one of these interaction states still retain that named
baseline. This makes theme, sizing, typography, and accidental animation regressions observable
without inventing a state that the original component does not support.

The harness loads Flutter's real Roboto and Material Icons font assets. It captures the complete
`RenderView`, rather than only the component's nearest repaint boundary, so composited Tooltip,
Overlay, and Navigator Window layers are part of the PNG. Expanded dropdown, dialog, bottom-sheet,
and tooltip baselines are opened through their public APIs; the test also asserts that the expected
popup surface exists before taking the screenshot. Snackbar post-frame entries, indeterminate
progress, pull-to-refresh movement, and press feedback are advanced with bounded frame durations so
their animation baselines cannot silently settle to an empty or final frame.

Disabled screenshots use the component's native `enabled`/nullable-callback API where that state is
defined. Pure display components such as Text, Icon, Divider, and SmallTitle deliberately retain a
same-state baseline because no disabled or expanded state exists in the source component contract.

Regenerate the checked-in PNG files from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\update_component_goldens.ps1
```

Verify them without updating:

```powershell
flutter test .\test\component_golden_test.dart
```

Behavioral tests separately verify queue timing, popup-host isolation, Overlay versus Window route
selection, anchor geometry, dismissal callbacks, wrap-around picking, and perceptual color-space
round trips. The golden suite is intentionally focused on rendered output.
