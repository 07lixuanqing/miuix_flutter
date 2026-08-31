import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _ChannelBuilder = Widget Function(ValueChanged<double>? onChanged);

class _ChannelCase {
  const _ChannelCase(this.name, this.minimum, this.maximum, this.builder);

  final String name;
  final double minimum;
  final double maximum;
  final _ChannelBuilder builder;
}

List<_ChannelCase> _channelCases({double value = 0}) => <_ChannelCase>[
  _ChannelCase(
    'HSV hue',
    0,
    360,
    (changed) => MiuixHsvHueSlider(value: value, onChanged: changed),
  ),
  _ChannelCase(
    'HSV saturation',
    0,
    1,
    (changed) => MiuixHsvSaturationSlider(
      value: value,
      currentHue: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'HSV value',
    0,
    1,
    (changed) => MiuixHsvValueSlider(
      value: value,
      currentHue: double.nan,
      currentSaturation: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'HSV alpha',
    0,
    1,
    (changed) => MiuixHsvAlphaSlider(
      value: value,
      currentHue: double.nan,
      currentSaturation: double.nan,
      currentValue: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKHSV hue',
    0,
    1,
    (changed) => MiuixOkHsvHueSlider(value: value, onChanged: changed),
  ),
  _ChannelCase(
    'OKHSV saturation',
    0,
    1,
    (changed) => MiuixOkHsvSaturationSlider(
      value: value,
      hue: double.nan,
      brightness: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKHSV value',
    0,
    1,
    (changed) => MiuixOkHsvValueSlider(
      value: value,
      hue: double.nan,
      saturation: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKHSV alpha',
    0,
    1,
    (changed) => MiuixOkHsvAlphaSlider(
      value: value,
      hue: double.nan,
      saturation: double.nan,
      brightness: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKLab lightness',
    0,
    1,
    (changed) => MiuixOkLabLightnessSlider(
      value: value,
      a: double.nan,
      b: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKLab A',
    -.3,
    .3,
    (changed) => MiuixOkLabAChannelSlider(
      value: value,
      lightness: double.nan,
      b: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKLab B',
    -.3,
    .3,
    (changed) => MiuixOkLabBChannelSlider(
      value: value,
      lightness: double.nan,
      a: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKLab alpha',
    0,
    1,
    (changed) => MiuixOkLabAlphaSlider(
      value: value,
      lightness: double.nan,
      a: double.nan,
      b: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKLCH lightness',
    0,
    1,
    (changed) => MiuixOkLchLightnessSlider(
      value: value,
      chroma: double.nan,
      hue: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKLCH chroma',
    0,
    1,
    (changed) => MiuixOkLchChromaSlider(
      value: value,
      lightness: double.nan,
      hue: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKLCH hue',
    0,
    1,
    (changed) => MiuixOkLchHueSlider(
      value: value,
      lightness: double.nan,
      chroma: double.nan,
      onChanged: changed,
    ),
  ),
  _ChannelCase(
    'OKLCH alpha',
    0,
    1,
    (changed) => MiuixOkLchAlphaSlider(
      value: value,
      lightness: double.nan,
      chroma: double.nan,
      hue: double.nan,
      onChanged: changed,
    ),
  ),
];

Future<void> _pumpChannel(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MiuixTheme(
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Center(child: SizedBox(width: 240, child: child)),
          ),
        ),
      ),
    ),
  );
}

Finder _channelTrack() {
  final ordinary = find.byKey(const ValueKey('miuix-color-channel-slider'));
  return ordinary.evaluate().isNotEmpty
      ? ordinary
      : find.byKey(const ValueKey('miuix-hsv-alpha-slider'));
}

void main() {
  testWidgets(
    'every public color channel maps physical endpoints by direction',
    (tester) async {
      for (final channel in _channelCases()) {
        for (final direction in TextDirection.values) {
          double? changed;
          await _pumpChannel(
            tester,
            channel.builder((value) => changed = value),
            direction: direction,
          );
          final track = _channelTrack();
          final rect = tester.getRect(track);
          final gesture = await tester.startGesture(rect.center);
          await gesture.moveTo(Offset(rect.right + 30, rect.center.dy));
          await gesture.up();
          await tester.pump();

          final expected = direction == TextDirection.ltr
              ? channel.maximum
              : channel.minimum;
          expect(
            changed,
            closeTo(expected, .000001),
            reason:
                '${channel.name} must map the physical right edge in $direction',
          );
          expect(tester.takeException(), isNull, reason: channel.name);
        }
      }
    },
  );

  testWidgets(
    'all public color channels sanitize inputs and expose 48dp targets',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channels = _channelCases(value: double.nan);
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                children: <Widget>[
                  for (final channel in channels)
                    SizedBox(
                      height: 52,
                      child: Center(child: channel.builder(null)),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final targets = find.byKey(
        const ValueKey('miuix-color-slider-touch-target'),
      );
      expect(targets, findsNWidgets(channels.length));
      for (final element in targets.evaluate()) {
        expect(tester.getRect(find.byWidget(element.widget)).height, 48);
        final semantics = element.widget as Semantics;
        expect(semantics.properties.enabled, isFalse);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('enabled public color channels own a parent pager drag', (
    tester,
  ) async {
    for (final channel in _channelCases()) {
      final pageController = PageController();
      double? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: PageView(
                key: ValueKey<String>('enabled-${channel.name}'),
                controller: pageController,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 300,
                      child: channel.builder((value) => changed = value),
                    ),
                  ),
                  const Center(child: Text('next page')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.drag(_channelTrack(), const Offset(-240, 0));
      await tester.pumpAndSettle();

      expect(changed, isNotNull, reason: channel.name);
      expect(pageController.page, closeTo(0, .001), reason: channel.name);
      pageController.dispose();
      expect(tester.takeException(), isNull, reason: channel.name);
    }
  });

  testWidgets('disabled public color channels yield horizontal drag to pager', (
    tester,
  ) async {
    for (final channel in _channelCases()) {
      final pageController = PageController();
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: PageView(
                key: ValueKey<String>('disabled-${channel.name}'),
                controller: pageController,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: 300, child: channel.builder(null)),
                  ),
                  const Center(child: Text('next page')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.fling(_channelTrack(), const Offset(-600, 0), 1200);
      await tester.pumpAndSettle();

      expect(pageController.page, closeTo(1, .001), reason: channel.name);
      pageController.dispose();
      expect(tester.takeException(), isNull, reason: channel.name);
    }
  });
}
