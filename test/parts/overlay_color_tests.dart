part of '../miuix_flutter_test.dart';

void _ignoreString(String _) {}

void _ignoreDropdownIndex(int _) {}

Future<Object?> _sendMiuixPredictiveBack(
  WidgetTester tester,
  String method, [
  Map<String, Object?>? arguments,
]) async {
  final message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );
  Object? response;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    message,
    (data) {
      response = data == null
          ? null
          : const StandardMethodCodec().decodeEnvelope(data);
    },
  );
  return response;
}

double _miuixBottomSheetSourceResponse(double seconds) {
  const dampingRatio = .9;
  const responseSeconds = .38;
  const naturalFrequency = 2 * math.pi / responseSeconds;
  final dampedFactor = math.sqrt(1 - dampingRatio * dampingRatio);
  final dampedFrequency = naturalFrequency * dampedFactor;
  final envelope = math.exp(-dampingRatio * naturalFrequency * seconds);
  return 1 -
      envelope *
          (math.cos(dampedFrequency * seconds) +
              dampingRatio /
                  dampedFactor *
                  math.sin(dampedFrequency * seconds));
}

// 四组按原顺序注册，共用同一测试库中的私有夹具与辅助函数。
// 拆分只改变文件组织，不更换用例、断言或平台输入。
void _registerOverlayColorTests() {
  _registerOverlayWindowLifecycleTests();
  _registerOverlayFeedbackPickerTests();
  _registerOverlayHostSheetTests();
  _registerOverlayDropdownRoutesTests();
}
