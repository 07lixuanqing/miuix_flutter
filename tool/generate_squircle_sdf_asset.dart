// Generates the lossless PNG consumed by MiuixSquircleSurface.
//
// The input is compose-miuix's generated BakedSquircleSdf.kt. Reading its
// Base64 chunks instead of recomputing the Bezier sweep guarantees byte-for-
// byte identity with the exact upstream commit used for parity work.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart tool/generate_squircle_sdf_asset.dart '
      '<BakedSquircleSdf.kt> <output.png>',
    );
    exitCode = 64;
    return;
  }
  final source = File(arguments[0]).readAsStringSync();
  final chunks = RegExp(
    r'^\s*"([A-Za-z0-9+/=]+)",\s*$',
    multiLine: true,
  ).allMatches(source).map((match) => match.group(1)!).join();
  final alpha = base64Decode(chunks);
  const size = 512;
  if (alpha.length != size * size) {
    throw StateError('Expected ${size * size} SDF bytes, got ${alpha.length}.');
  }
  var alphaFingerprint = 0x811c9dc5;
  for (final value in alpha) {
    alphaFingerprint = ((alphaFingerprint ^ value) * 0x01000193) & 0xffffffff;
  }

  // PNG scanlines use filter type zero followed by RGBA pixels. RGB stays
  // zero because the runtime shader reads only alpha, matching Alpha8 source.
  final scanlines = Uint8List(size * (1 + size * 4));
  var output = 0;
  var input = 0;
  for (var y = 0; y < size; y++) {
    scanlines[output++] = 0;
    for (var x = 0; x < size; x++) {
      scanlines[output++] = 0;
      scanlines[output++] = 0;
      scanlines[output++] = 0;
      scanlines[output++] = alpha[input++];
    }
  }

  final png = BytesBuilder(copy: false)
    ..add(const <int>[137, 80, 78, 71, 13, 10, 26, 10])
    ..add(_chunk('IHDR', _ihdr(size, size)))
    ..add(_chunk('IDAT', ZLibEncoder().convert(scanlines)))
    ..add(_chunk('IEND', const <int>[]));
  final target = File(arguments[1]);
  target.parent.createSync(recursive: true);
  target.writeAsBytesSync(png.takeBytes(), flush: true);
  stdout.writeln(
    'Wrote ${target.path} from ${alpha.length} exact SDF bytes '
    '(FNV-1a32 0x${alphaFingerprint.toRadixString(16).padLeft(8, '0')}).',
  );
}

Uint8List _ihdr(int width, int height) {
  final data = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 6)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  return data.buffer.asUint8List();
}

Uint8List _chunk(String name, List<int> payload) {
  final type = ascii.encode(name);
  final data = ByteData(4)..setUint32(0, payload.length);
  final crcInput = Uint8List.fromList(<int>[...type, ...payload]);
  final crc = ByteData(4)..setUint32(0, _crc32(crcInput));
  return Uint8List.fromList(<int>[
    ...data.buffer.asUint8List(),
    ...type,
    ...payload,
    ...crc.buffer.asUint8List(),
  ]);
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >>> 1) : crc >>> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
