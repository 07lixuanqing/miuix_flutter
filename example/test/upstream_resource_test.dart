import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('About and licenses bundle the exact upstream resources', () async {
    // The byte length protects against silently replacing the exact 720 px
    // upstream launcher artwork with another generated launcher variant.
    final icon = await rootBundle.load('assets/images/ic_launcher.png');
    expect(icon.lengthInBytes, 39870);

    // LicensePage.kt consumes the generated inventory in file order. Keep the
    // same 123 records and leading sequence in the localized port. Checking
    // more than the first row catches generated target-suffix and ordering
    // drift such as annotation-jvm moving behind annotation-experimental.
    final source = await rootBundle.loadString(
      'assets/data/aboutlibraries.json',
    );
    final document = jsonDecode(source) as Map<String, dynamic>;
    final libraries = document['libraries'] as List<dynamic>;
    expect(libraries, hasLength(123));
    expect(
      libraries.take(5).map((library) => library['uniqueId']),
      orderedEquals(const [
        'androidx.activity:activity',
        'androidx.activity:activity-compose',
        'androidx.activity:activity-ktx',
        'androidx.annotation:annotation-experimental',
        'androidx.annotation:annotation-jvm',
      ]),
    );
  });
}
