part of '../miuix_widgets.dart';

/// Exact public constants exposed by the upstream `TextFieldDefaults` object.
///
/// Compose names these values `CornerRadius` and `InsideMargin`. Dart style
/// uses lower camel case while retaining the same logical dimensions.
abstract final class MiuixTextFieldDefaults {
  /// Default G2 or ordinary rounded-corner radius.
  static const double cornerRadius = 16;

  /// Default horizontal and vertical content inset.
  static const EdgeInsets insideMargin = EdgeInsets.all(16);
}

/// Immutable snapshot reported by [MiuixTextField.onTextLayout].
///
/// Compose exposes `TextLayoutResult`; Flutter does not expose the private
/// `RenderEditable` paragraph result as a stable public object. This adapter
/// records the source-observable parts without leaking a disposable painter.
@immutable
class MiuixTextFieldLayoutResult {
  /// Creates an immutable editable-text layout snapshot.
  const MiuixTextFieldLayoutResult({
    required this.size,
    required this.lineCount,
    required this.didExceedMaxLines,
    required this.text,
  });

  /// Painted paragraph size before the surrounding inside margin is added.
  final Size size;

  /// Number of laid-out visual lines after wrapping.
  final int lineCount;

  /// Whether the configured maximum line count clipped additional text.
  final bool didExceedMaxLines;

  /// Plain controller text used for this layout pass.
  final String text;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MiuixTextFieldLayoutResult &&
            other.size == size &&
            other.lineCount == lineCount &&
            other.didExceedMaxLines == didExceedMaxLines &&
            other.text == text;
  }

  @override
  int get hashCode => Object.hash(size, lineCount, didExceedMaxLines, text);
}
