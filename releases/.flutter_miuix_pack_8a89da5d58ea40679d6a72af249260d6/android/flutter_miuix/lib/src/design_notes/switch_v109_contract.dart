// Copyright 2026 flutter_miuix contributors.
//
// MIUIX 1.0.9 Switch source-parity contract.
//
// Authority
//
// Normative behavior comes from basic/Switch.kt.
// Drag behavior comes from Compose draggable on the authored thumb.
// Toggle semantics come from the outer Compose toggleable modifier.
// Flutter Material Switch is not a geometry, color, or motion authority.
//
// Public state
//
// checked is a caller-owned boolean.
// onCheckedChange receives the inverse checked value.
// A null callback removes the outer toggle action.
// enabled remains independent from callback presence.
// MiuixSwitch.source exposes the source checked and onCheckedChange names.
// The value and onChanged form remains available for Flutter compatibility.
//
// Public colors
//
// SwitchColors is an immutable eight-channel data value.
// checkedThumbColor is used for enabled checked state.
// uncheckedThumbColor is used for enabled unchecked state.
// disabledCheckedThumbColor is used for disabled checked state.
// disabledUncheckedThumbColor is used for disabled unchecked state.
// checkedTrackColor is used for enabled checked state.
// uncheckedTrackColor is used for enabled unchecked state.
// disabledCheckedTrackColor is used for disabled checked state.
// disabledUncheckedTrackColor is used for disabled unchecked state.
// Every channel can be overridden independently.
// Equality and copy behavior mirror the Kotlin data class.
//
// Default color roles
//
// Checked thumb defaults to onPrimary.
// Dynamic unchecked thumb uses onSurface at 38 percent alpha.
// Fixed unchecked thumb uses onSecondary.
// Dynamic disabled checked thumb uses surface.
// Fixed disabled checked thumb uses disabledOnPrimary.
// Disabled unchecked thumb uses disabledOnSecondary.
// Checked track defaults to primary.
// Unchecked track defaults to secondary.
// Disabled checked track defaults to disabledPrimary.
// Disabled unchecked track defaults to disabledSecondary.
//
// Layout
//
// The authored track is exactly 49dp wide and 28dp high.
// The authored thumb is exactly 20dp square.
// The unchecked leading thumb offset is exactly 4dp.
// The checked leading thumb offset is exactly 25dp.
// The distance between endpoints is exactly 21dp.
// The vertical thumb inset is exactly 4dp.
// Track and thumb use capsule or circle geometry without extra borders.
// Authored dimensions are rounded through integer physical pixels.
// Callback-backed controls expose the platform 48dp minimum touch height.
// Minimum-target expansion must not change the visible 49 by 28dp track.
// A callback-free switch keeps only the authored visual bounds.
//
// Pointer ownership
//
// The complete track owns the outer tap action when activation is available.
// Horizontal draggable is installed only on the 20dp thumb.
// Starting a drag on an exposed track end does not move the thumb.
// An enabled thumb remains draggable when onCheckedChange is null.
// A disabled thumb has no draggable modifier.
// Horizontal thumb intent wins against an ancestor horizontal pager.
// Drag implementation details add no independent semantic scroll action.
//
// Drag projection
//
// Every pointer delta is divided by two before source accumulation.
// Raw drag travel remains unbounded for the duration of one gesture.
// Unchecked projection clamps raw travel to the inclusive range zero to 21.
// Checked projection clamps raw travel to the inclusive range minus 21 to zero.
// Only the clamped projection contributes to the visible thumb endpoint.
// Small reversal after a large overshoot therefore remains at the endpoint.
// Raw and visible offsets reset when a new drag begins.
// Both offsets reset after drag end or external checked-state commitment.
//
// Drag commitment
//
// Release commits when absolute projected travel is greater than 10.5dp.
// Exactly 10.5dp does not commit.
// A committed drag invokes the callback with inverse checked state.
// Callback-free enabled dragging still animates and emits source haptics.
// The transient thumb returns to the owner-provided checked endpoint.
// A subsequent owner rebuild performs the committed endpoint transition.
//
// Thumb position motion
//
// Position uses a spring with damping ratio 0.7.
// Position spring stiffness is exactly 987.
// Position retargeting preserves current velocity.
// Checked state and transient drag share the same physical position channel.
//
// Thumb scale motion
//
// Resting thumb scale is exactly one.
// Pressed, dragged, or hovered enabled scale is exactly 1.127.
// Disabled scale remains exactly one.
// Scale uses a spring with damping ratio 0.6.
// Scale spring stiffness is exactly 987.
// Scale retargeting preserves current velocity.
// Scale remains centered on the current logical thumb position.
//
// Color motion
//
// Thumb color uses a critically damped spring.
// Thumb color spring stiffness is exactly 1500.
// Track color uses a spring with damping ratio 0.99.
// Track color spring stiffness is exactly 438.6.
// Thumb and track colors animate independently.
// Interrupted color changes begin at the currently displayed color.
// Rendered color interpolation clamps overshooting scalar progress.
//
// Hover and press
//
// Hoverable covers the outer authored switch.
// Enabled hover enlarges the thumb to the pressed scale.
// Disabled hover produces no scale change.
// Enabled toggle press enlarges the thumb before tap release.
// Drag start also enters the pressed scale state.
// Drag end and cancellation return to rest unless hover remains active.
//
// Toggle haptics
//
// Tap callback runs before its haptic feedback.
// Switching on emits ToggleOn.
// Switching off emits ToggleOff.
// Disabled and callback-free taps emit no toggle haptic.
// Drag feedback maintains independent start and end endpoint flags.
// Reaching the opposite endpoint emits the opposite-state toggle role.
// Returning to the original endpoint can emit the original-state role.
// Release roles use the exact 10dp and 11dp source boundaries.
// The one-dp release dead band is intentional.
//
// Semantics
//
// The outer node exposes switch-like toggled state.
// Enabled state is explicit.
// A callback-backed enabled node exposes one toggle action.
// A callback-backed disabled node preserves a no-op action boundary.
// A callback-free node has no tap action.
// The inner drag recognizer is excluded from semantics.
//
// Regression evidence
//
// Tests cover all eight explicit custom color channels.
// Tests cover the source factory and default semantic roles.
// Tests cover exact dimensions and both authored endpoints.
// Tests cover callback-specific 48dp target expansion.
// Tests cover thumb-only draggable hit testing.
// Tests cover raw overshoot followed by a small reversal.
// Tests cover ownership against an ancestor PageView.
// Tests cover all four exact spring descriptions.
// Tests cover endpoint and tap haptic roles.
// Tests cover disabled colors and disabled drag suppression.
//
// Maintenance rule
//
// Future changes must be compared directly against Switch.kt.
// Do not replace this implementation with Flutter Material Switch.
// Do not move draggable from the authored thumb to the complete track.
// Do not clamp each delta before adding it to the raw drag accumulator.
// Do not merge the four motion springs into a generic duration curve.
// Compatibility APIs must delegate to the same source state machine.
