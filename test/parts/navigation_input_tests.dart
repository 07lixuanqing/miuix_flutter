part of '../miuix_flutter_test.dart';

final class _TestNavKey implements MiuixNavKey {
  const _TestNavKey(this.name);

  final String name;

  @override
  bool operator ==(Object other) => other is _TestNavKey && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class _NavCounterPage extends StatefulWidget {
  const _NavCounterPage({required this.label});

  final String label;

  @override
  State<_NavCounterPage> createState() => _NavCounterPageState();
}

class _NavCounterPageState extends State<_NavCounterPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: widget.label == 'root' ? Colors.white : Colors.blue,
    child: Center(
      child: TextButton(
        onPressed: () => setState(() => count += 1),
        child: Text('${widget.label}:$count'),
      ),
    ),
  );
}

// 保留原注册入口，完整套件继续按原顺序执行。
void _registerNavigationInputTests() {
  _registerNavigationStackTests();
  _registerNavigationSurfaceTests();
  _registerNavigationRailTests();
  _registerNavigationSearchTests();
}
