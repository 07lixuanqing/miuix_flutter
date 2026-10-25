import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'
    show
        CheckedState,
        ImageByteFormat,
        ImageFilter,
        SemanticsAction,
        SemanticsRole,
        Tristate;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, ValueNotifier, debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart'
    show RenderRepaintBoundary, SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

part 'parts/core_widget_tests.dart';
part 'parts/haptic_tests.dart';
part 'parts/navigation_input_tests.dart';
// 按职责拆分测试文件，注册顺序仍由 selection_progress 保持。
part 'parts/text_field_tests.dart';
part 'parts/selection_control_tests.dart';
part 'parts/selection_progress_tests.dart';
part 'parts/overlay_color_tests.dart';

/// Verifies that the public package can build representative widgets.
void main() {
  _registerCoreWidgetTests();
  _registerHapticTests();
  _registerNavigationInputTests();
  _registerSelectionProgressTests();
  _registerOverlayColorTests();
}

String _identityLabel(String value) => value;

void _ignoreStringSet(Set<String> value) {}

void _ignoreDouble(double value) {}
