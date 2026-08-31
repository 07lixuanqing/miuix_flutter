"""Generate Flutter icon fonts from the authoritative Compose MIUIX vectors.

The upstream icon package stores one Kotlin file per icon and three vector
weights per file.  Keeping those thousands of path nodes as Dart source would
make the Flutter package difficult to review, so this tool converts them to
standard TrueType glyphs and emits a small, documented Dart catalogue.

Run from the repository root after installing ``fonttools``::

    python tool/generate_miuix_icon_fonts.py C:\\Code\\miuix-src-current

Generated fonts and Dart files are committed so normal Flutter builds do not
depend on Python, fonttools, or the sibling Compose repository.
"""

from __future__ import annotations

import re
import sys
import math
from dataclasses import dataclass
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.recordingPen import RecordingPen, replayRecording
from fontTools.pens.reverseContourPen import reversedContour
from fontTools.pens.ttGlyphPen import TTGlyphPen


# Current MIUIX publishes an independent source vector for every optical
# weight. Keep the public Flutter names in exactly the same order.
WEIGHTS = ("Light", "Normal", "Regular", "Medium", "Demibold")
SOURCE_WEIGHTS = WEIGHTS
SOURCE_WEIGHT_FOR_PUBLIC = {weight: weight for weight in WEIGHTS}
ARITY = {
    "MoveTo": 2,
    "LineTo": 2,
    "HorizontalTo": 1,
    "VerticalTo": 1,
    "CurveTo": 6,
    "QuadTo": 4,
    "Close": 0,
}
NUMBER = re.compile(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?f?")
NODE = re.compile(r"PathNode\.(\w+)(?:\((.*?)\))?", re.DOTALL)
DSL_NODE = re.compile(
    r"\b(moveTo|lineTo|curveTo|close)\s*\((.*?)\)",
    re.DOTALL,
)


@dataclass(frozen=True)
class Vector:
    """One weight of an upstream icon."""

    viewport_width: float
    viewport_height: float
    scale_x: float
    scale_y: float
    translation_x: float
    translation_y: float
    commands: tuple[tuple[str, tuple[float, ...]], ...]


def parse_vector(block: str, source: Path, weight: str) -> Vector:
    """Parse the deliberately small PathNode subset used by current MIUIX."""

    width_match = re.search(r"viewportWidth\s*=\s*([^,]+)", block)
    height_match = re.search(r"viewportHeight\s*=\s*([^,]+)", block)
    if width_match is None or height_match is None:
        raise ValueError(f"Missing viewport in {source.name} ({weight})")

    width = float(NUMBER.search(width_match.group(1)).group().rstrip("f"))
    height = float(NUMBER.search(height_match.group(1)).group().rstrip("f"))
    # Most authoritative vectors retain the transformation used when the
    # original Android path was converted to Compose. In particular, their raw
    # nodes use a Y-up coordinate system and the group changes it to Compose's
    # Y-down viewport. Ignoring this group made directional glyphs such as
    # Download and UploadCloud appear vertically inverted in the generated TTF.
    group_match = re.search(r"group\((.*?)\)\s*\{", block, re.DOTALL)
    group_values = {
        name: float(NUMBER.search(value).group().rstrip("f"))
        for name, value in re.findall(
            r"(scaleX|scaleY|translationX|translationY)\s*=\s*([^,\)]+)",
            group_match.group(1) if group_match else "",
        )
    }
    commands: list[tuple[str, tuple[float, ...]]] = []

    for match in NODE.finditer(block):
        kind = match.group(1)
        if kind not in ARITY:
            raise ValueError(f"Unsupported {kind} in {source.name} ({weight})")
        values = tuple(
            float(value.rstrip("f"))
            for value in NUMBER.findall(match.group(2) or "")
        )
        if len(values) != ARITY[kind]:
            raise ValueError(
                f"{kind} has {len(values)} values in {source.name} ({weight})"
            )
        commands.append((kind, values))

    if not commands:
        raise ValueError(f"No path nodes in {source.name} ({weight})")
    return Vector(
        width,
        height,
        group_values.get("scaleX", 1.0),
        group_values.get("scaleY", 1.0),
        group_values.get("translationX", 0.0),
        group_values.get("translationY", 0.0),
        tuple(commands),
    )


def parse_icon(source: Path) -> dict[str, Vector]:
    """Extract current MIUIX's five authoritative vectors."""

    text = source.read_text(encoding="utf-8")
    starts: list[tuple[int, str]] = []
    for weight in SOURCE_WEIGHTS:
        marker = re.search(
            rf"val\s+MiuixIcons\.{weight}\.{re.escape(source.stem)}\s*:", text
        )
        if marker is None:
            raise ValueError(f"Missing {weight} getter in {source.name}")
        starts.append((marker.start(), weight))
    starts.sort()

    source_vectors: dict[str, Vector] = {}
    for index, (start, weight) in enumerate(starts):
        end = starts[index + 1][0] if index + 1 < len(starts) else len(text)
        source_vectors[weight] = parse_vector(text[start:end], source, weight)
    return {
        public_weight: source_vectors[source_weight]
        for public_weight, source_weight in SOURCE_WEIGHT_FOR_PUBLIC.items()
    }


def parse_basic_icon(source: Path) -> Vector:
    """Extract one current `MiuixIcons.Basic` vector.

    Basic icons predate the generated five-weight catalogue and use either the
    concise Compose path DSL or the same PathNode list as extended icons. The
    two forms are normalized into the shared Vector model so their orientation
    and viewport handling cannot drift from the extended-font pipeline.
    """

    text = source.read_text(encoding="utf-8")
    if "PathNode." in text:
        return parse_vector(text, source, "Basic")

    builder = re.search(
        rf"ImageVector\.Builder\(\s*\"[^\"]+\"\s*,[^,]+,[^,]+,"
        rf"\s*({NUMBER.pattern})\s*,\s*({NUMBER.pattern})\s*\)",
        text,
        re.DOTALL,
    )
    if builder is None:
        raise ValueError(f"Missing positional viewport in {source.name}")
    width = float(builder.group(1).rstrip("f"))
    height = float(builder.group(2).rstrip("f"))
    kind_map = {
        "moveTo": "MoveTo",
        "lineTo": "LineTo",
        "curveTo": "CurveTo",
        "close": "Close",
    }
    commands: list[tuple[str, tuple[float, ...]]] = []
    for match in DSL_NODE.finditer(text):
        kind = kind_map[match.group(1)]
        values = tuple(
            float(value.rstrip("f"))
            for value in NUMBER.findall(match.group(2) or "")
        )
        if len(values) != ARITY[kind]:
            raise ValueError(
                f"{kind} has {len(values)} values in {source.name} (Basic)"
            )
        commands.append((kind, values))
    if not commands:
        raise ValueError(f"No basic path commands in {source.name}")
    return Vector(width, height, 1.0, 1.0, 0.0, 0.0, tuple(commands))


def draw_vector(vector: Vector):
    """Create one square TrueType glyph while preserving the vector viewport."""

    recording = RecordingPen()
    curve_pen = Cu2QuPen(recording, max_err=1.0, reverse_direction=False)
    scale = min(1000.0 / vector.viewport_width, 1000.0 / vector.viewport_height)
    x_offset = (1000.0 - vector.viewport_width * scale) / 2.0
    y_offset = (1000.0 - vector.viewport_height * scale) / 2.0
    current_x = 0.0
    current_y = 0.0

    def point(x: float, y: float) -> tuple[float, float]:
        # Apply the source group first, then convert Compose's downward viewport
        # to the upward TrueType coordinate system exactly once.
        transformed_x = x * vector.scale_x + vector.translation_x
        transformed_y = y * vector.scale_y + vector.translation_y
        return (
            x_offset + transformed_x * scale,
            1000.0 - y_offset - transformed_y * scale,
        )

    for kind, values in vector.commands:
        if kind == "MoveTo":
            current_x, current_y = values
            curve_pen.moveTo(point(current_x, current_y))
        elif kind == "LineTo":
            current_x, current_y = values
            curve_pen.lineTo(point(current_x, current_y))
        elif kind == "HorizontalTo":
            current_x = values[0]
            curve_pen.lineTo(point(current_x, current_y))
        elif kind == "VerticalTo":
            current_y = values[0]
            curve_pen.lineTo(point(current_x, current_y))
        elif kind == "CurveTo":
            x1, y1, x2, y2, current_x, current_y = values
            curve_pen.curveTo(
                point(x1, y1),
                point(x2, y2),
                point(current_x, current_y),
            )
        elif kind == "QuadTo":
            x1, y1, current_x, current_y = values
            curve_pen.qCurveTo(point(x1, y1), point(current_x, current_y))
        elif kind == "Close":
            curve_pen.closePath()
    pen = TTGlyphPen(None)
    replayRecording(_normalized_contours(recording.value), pen)
    return pen.glyph()


def _normalized_contours(recording):
    """Alternate nested contour winding so TrueType preserves source holes.

    Compose paths reliably render nested cut-outs even when generated source
    nodes retain the same winding. TrueType uses contour direction to identify
    those holes. Normalizing only strict bbox nesting preserves independent or
    overlapping shapes while keeping search rings and similar cut-outs open.
    """

    contours = []
    current = []
    for command in recording:
        current.append(command)
        if command[0] in ("closePath", "endPath"):
            contours.append(current)
            current = []
    if current:
        contours.append(current)

    def points(contour):
        return [
            point
            for _, operands in contour
            for point in operands
            if point is not None
        ]

    def bounds(contour):
        values = points(contour)
        return (
            min(point[0] for point in values),
            min(point[1] for point in values),
            max(point[0] for point in values),
            max(point[1] for point in values),
        )

    def box_area(box):
        return (box[2] - box[0]) * (box[3] - box[1])

    def contains(outer, inner):
        return (
            outer[0] <= inner[0]
            and outer[1] <= inner[1]
            and outer[2] >= inner[2]
            and outer[3] >= inner[3]
            and outer != inner
        )

    def signed_area(contour):
        on_curve = []
        for operator, operands in contour:
            if operator == "moveTo" or operator in (
                "lineTo",
                "curveTo",
                "qCurveTo",
            ):
                if operands and operands[-1] is not None:
                    on_curve.append(operands[-1])
        if len(on_curve) < 3:
            return 0.0
        return sum(
            on_curve[index][0] * on_curve[(index + 1) % len(on_curve)][1]
            - on_curve[(index + 1) % len(on_curve)][0] * on_curve[index][1]
            for index in range(len(on_curve))
        ) / 2.0

    entries = [
        {
            "contour": contour,
            "bounds": bounds(contour),
            "sign": 1 if signed_area(contour) >= 0 else -1,
            "index": index,
        }
        for index, contour in enumerate(contours)
    ]
    processed = []
    for entry in sorted(entries, key=lambda item: box_area(item["bounds"]), reverse=True):
        parents = [
            parent
            for parent in processed
            if contains(parent["bounds"], entry["bounds"])
        ]
        if parents:
            parent = min(parents, key=lambda item: box_area(item["bounds"]))
            target_sign = -parent["sign"]
            if entry["sign"] != target_sign:
                entry["contour"] = list(reversedContour(list(entry["contour"])))
                entry["sign"] = target_sign
        processed.append(entry)

    normalized = []
    for entry in sorted(entries, key=lambda item: item["index"]):
        normalized.extend(entry["contour"])
    return normalized


def draw_basic_close(vector: Vector):
    """Expand the source's two round 2.2dp strokes into font outlines."""

    recording = RecordingPen()
    curve_pen = Cu2QuPen(recording, max_err=1.0, reverse_direction=False)
    scale = min(1000.0 / vector.viewport_width, 1000.0 / vector.viewport_height)
    x_offset = (1000.0 - vector.viewport_width * scale) / 2.0
    y_offset = (1000.0 - vector.viewport_height * scale) / 2.0
    radius = 1.1 * scale
    kappa = 0.5522847498307936

    def point(x: float, y: float) -> tuple[float, float]:
        return (x_offset + x * scale, 1000.0 - y_offset - y * scale)

    segments = (((6.0, 6.0), (18.0, 18.0)), ((18.0, 6.0), (6.0, 18.0)))
    for raw_start, raw_end in segments:
        start = point(*raw_start)
        end = point(*raw_end)
        dx = end[0] - start[0]
        dy = end[1] - start[1]
        length = math.hypot(dx, dy)
        direction = (dx / length, dy / length)
        normal = (-direction[1], direction[0])

        def offset(
            center: tuple[float, float],
            vector: tuple[float, float],
            amount: float,
        ) -> tuple[float, float]:
            return (
                center[0] + vector[0] * amount,
                center[1] + vector[1] * amount,
            )

        start_top = offset(start, normal, radius)
        end_top = offset(end, normal, radius)
        end_front = offset(end, direction, radius)
        end_bottom = offset(end, normal, -radius)
        start_bottom = offset(start, normal, -radius)
        start_back = offset(start, direction, -radius)
        curve_pen.moveTo(start_top)
        curve_pen.lineTo(end_top)
        curve_pen.curveTo(
            offset(end_top, direction, kappa * radius),
            offset(end_front, normal, kappa * radius),
            end_front,
        )
        curve_pen.curveTo(
            offset(end_front, normal, -kappa * radius),
            offset(end_bottom, direction, kappa * radius),
            end_bottom,
        )
        curve_pen.lineTo(start_bottom)
        curve_pen.curveTo(
            offset(start_bottom, direction, -kappa * radius),
            offset(start_back, normal, -kappa * radius),
            start_back,
        )
        curve_pen.curveTo(
            offset(start_back, normal, kappa * radius),
            offset(start_top, direction, -kappa * radius),
            start_top,
        )
        curve_pen.closePath()
    pen = TTGlyphPen(None)
    replayRecording(_normalized_contours(recording.value), pen)
    return pen.glyph()


def build_basic_font(output: Path, icons: list[tuple[str, Vector]]) -> None:
    """Build the exact single-weight current MIUIX Basic icon font."""

    family = "MiuixIconsBasic"
    glyph_order = [".notdef", *(name for name, _ in icons)]
    glyphs = {".notdef": TTGlyphPen(None).glyph()}
    glyphs.update(
        {
            name: draw_basic_close(vector)
            if name == "Close"
            else draw_vector(vector)
            for name, vector in icons
        }
    )
    metrics = {
        name: (
            1000,
            min((point[0] for point in glyph.coordinates), default=0),
        )
        for name, glyph in glyphs.items()
    }
    character_map = {0xE000 + index: name for index, (name, _) in enumerate(icons)}
    builder = FontBuilder(1000, isTTF=True)
    builder.setupGlyphOrder(glyph_order)
    builder.setupCharacterMap(character_map)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics(metrics)
    builder.setupHorizontalHeader(ascent=1000, descent=0)
    builder.setupNameTable(
        {
            "familyName": family,
            "styleName": "Regular",
            "uniqueFontIdentifier": "MIUIX-current-MiuixIconsBasic",
            "fullName": family,
            "psName": family,
            "version": "Version 1.0",
        }
    )
    builder.setupOS2(
        sTypoAscender=1000,
        sTypoDescender=0,
        usWinAscent=1000,
        usWinDescent=0,
    )
    builder.setupPost()
    builder.setupMaxp()
    output.parent.mkdir(parents=True, exist_ok=True)
    builder.save(output)


def write_basic_catalogue(output: Path, icons: list[tuple[str, Vector]]) -> None:
    """Emit stable IconData constants for the exact basic font outlines."""

    fields = "\n".join(
        (
            f"  /// Exact current MIUIX Basic.{name} vector.\n"
            f"  static const {name[0].lower() + name[1:]} = IconData("
            f"0x{0xE000 + index:X}, fontFamily: 'MiuixIconsBasic', "
            "fontPackage: 'flutter_miuix');"
        )
        for index, (name, _) in enumerate(icons)
    )
    output.write_text(
        f"""// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: current Compose MIUIX Basic ImageVector paths.

import 'package:flutter/widgets.dart';

/// Exact font-backed subset of the current MIUIX Basic vector catalogue.
///
/// SearchCleanup intentionally remains a layered painter because its three
/// source paths use different alpha channels that one IconData cannot retain.
abstract final class MiuixBasicIconCatalog {{
{fields}
}}
""",
        encoding="utf-8",
    )


def build_font(
    output: Path,
    weight: str,
    icons: list[tuple[str, dict[str, Vector]]],
) -> None:
    """Build a deterministic private-use icon font for one MIUIX weight."""

    family = f"MiuixIcons{weight}"
    glyph_order = [".notdef", *(name for name, _ in icons)]
    glyphs = {".notdef": TTGlyphPen(None).glyph()}
    glyphs.update({name: draw_vector(vectors[weight]) for name, vectors in icons})

    # TrueType stores the left side bearing independently from the outline's
    # xMin. Using zero here makes the rasterizer translate every non-zero-xMin
    # outline left, even though the generated coordinates are already centered
    # in the square viewport. Preserve xMin as the bearing so an Icon's ink and
    # its 24 dp layout box share the same horizontal center as Compose.
    metrics = {
        name: (
            1000,
            min((point[0] for point in glyph.coordinates), default=0),
        )
        for name, glyph in glyphs.items()
    }
    character_map = {0xE000 + index: name for index, (name, _) in enumerate(icons)}

    builder = FontBuilder(1000, isTTF=True)
    builder.setupGlyphOrder(glyph_order)
    builder.setupCharacterMap(character_map)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics(metrics)
    builder.setupHorizontalHeader(ascent=1000, descent=0)
    builder.setupNameTable(
        {
            "familyName": family,
            "styleName": "Regular",
            "uniqueFontIdentifier": f"MIUIX-current-{family}",
            "fullName": family,
            "psName": family,
            "version": "Version 1.1",
        }
    )
    builder.setupOS2(
        sTypoAscender=1000,
        sTypoDescender=0,
        usWinAscent=1000,
        usWinDescent=0,
    )
    builder.setupPost()
    builder.setupMaxp()
    output.parent.mkdir(parents=True, exist_ok=True)
    builder.save(output)


def dart_entry(name: str, codepoint: int) -> str:
    """Return one documented catalogue entry with all five exact glyphs."""

    glyphs = ", ".join(
        f"{weight.lower()}: IconData(0x{codepoint:X}, "
        f"fontFamily: 'MiuixIcons{weight}', fontPackage: 'flutter_miuix')"
        for weight in WEIGHTS
    )
    return (
        f"  /// Exact current MIUIX vector glyphs for {name}.\n"
        "  /// Preserves Light, Normal, Regular, Medium, and Demibold outlines.\n"
        "  /// Every weight is generated from its authoritative source vector.\n"
        f"  MiuixExtendedIconData(name: '{name}', {glyphs}),"
    )


def write_dart_catalogue(
    output_dir: Path,
    icons: list[tuple[str, dict[str, Vector]]],
) -> None:
    """Emit a small public model and four reviewable generated catalogue parts."""

    output_dir.mkdir(parents=True, exist_ok=True)
    chunk_size = 40
    chunks = [icons[index : index + chunk_size] for index in range(0, len(icons), chunk_size)]
    part_names = [f"miuix_extended_icons_{index + 1}.g.dart" for index in range(len(chunks))]
    parts = "\n".join(f"part '{name}';" for name in part_names)
    lists = ",\n    ".join(f"..._miuixExtendedIcons{index + 1}" for index in range(len(chunks)))
    main = f"""// Copyright 2026, flutter_miuix contributors
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/widgets.dart';

{parts}

/// The five optical weights shipped by the original MIUIX icon package.
enum MiuixIconWeight {{ light, normal, regular, medium, demibold }}

/// One MIUIX icon exposed through the package's five compatible weight names.
@immutable
class MiuixExtendedIconData {{
  /// Creates a complete, immutable icon weight family.
  const MiuixExtendedIconData({{
    required this.name,
    required this.light,
    required this.normal,
    required this.regular,
    required this.medium,
    required this.demibold,
  }});

  /// Original English glyph name used by Compose MIUIX.
  final String name;

  /// Light optical weight.
  final IconData light;

  /// Normal optical weight.
  final IconData normal;

  /// Regular optical weight.
  final IconData regular;

  /// Medium optical weight.
  final IconData medium;

  /// Demibold optical weight.
  final IconData demibold;

  /// Resolves a glyph without callers having to switch on the weight.
  IconData resolve(MiuixIconWeight weight) => switch (weight) {{
        MiuixIconWeight.light => light,
        MiuixIconWeight.normal => normal,
        MiuixIconWeight.regular => regular,
        MiuixIconWeight.medium => medium,
        MiuixIconWeight.demibold => demibold,
      }};
}}

/// Complete current MIUIX extended icon catalogue in source-name order.
abstract final class MiuixExtendedIconCatalog {{
  /// All 156 extended icons from the authoritative current catalogue.
  static const all = <MiuixExtendedIconData>[
    {lists},
  ];

  /// Finds a glyph family by its exact original name.
  static MiuixExtendedIconData? find(String name) {{
    for (final icon in all) {{
      if (icon.name == name) return icon;
    }}
    return null;
  }}
}}
"""
    (output_dir / "miuix_extended_icons.dart").write_text(main, encoding="utf-8")

    for chunk_index, chunk in enumerate(chunks):
        entries = "\n".join(
            dart_entry(name, 0xE000 + chunk_index * chunk_size + index)
            for index, (name, _) in enumerate(chunk)
        )
        content = f"""// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: current Compose MIUIX extended ImageVector paths.

part of 'miuix_extended_icons.dart';

// dart format off
const _miuixExtendedIcons{chunk_index + 1} = <MiuixExtendedIconData>[
{entries}
];
// dart format on
"""
        (output_dir / part_names[chunk_index]).write_text(content, encoding="utf-8")


def main() -> None:
    """Generate committed Flutter assets from an explicit upstream checkout."""

    if len(sys.argv) != 2:
        raise SystemExit("Usage: generate_miuix_icon_fonts.py <miuix-root>")
    repository = Path(__file__).resolve().parents[1]
    upstream = Path(sys.argv[1]).resolve()
    source_dir = (
        upstream
        / "miuix-icons/src/commonMain/kotlin/top/yukonga/miuix/kmp/icon/extended"
    )
    sources = sorted(source_dir.glob("*.kt"), key=lambda path: path.name.lower())
    if len(sources) != 156:
        raise ValueError(f"Expected 156 icons, found {len(sources)} in {source_dir}")

    icons = [(source.stem, parse_icon(source)) for source in sources]
    font_dir = repository / "assets/fonts"
    for weight in WEIGHTS:
        build_font(font_dir / f"MiuixIcons-{weight}.ttf", weight, icons)
    write_dart_catalogue(repository / "lib/src/icons", icons)

    basic_source_dir = (
        upstream
        / "miuix-ui/src/commonMain/kotlin/top/yukonga/miuix/kmp/icon/basic"
    )
    # SearchCleanup has three independent alpha channels. A one-color font
    # cannot preserve them, so it remains handled by the layered UI painter.
    basic_sources = [
        source
        for source in sorted(basic_source_dir.glob("*.kt"), key=lambda path: path.name.lower())
        if source.stem != "SearchCleanup"
    ]
    if len(basic_sources) != 6:
        raise ValueError(
            f"Expected 6 font-safe basic icons, found {len(basic_sources)} "
            f"in {basic_source_dir}"
        )
    basic_icons = [(source.stem, parse_basic_icon(source)) for source in basic_sources]
    build_basic_font(font_dir / "MiuixIcons-Basic.ttf", basic_icons)
    write_basic_catalogue(
        repository / "lib/src/icons/miuix_basic_icons.g.dart",
        basic_icons,
    )
    print(
        f"Generated {len(icons)} icons x {len(WEIGHTS)} weights "
        f"and {len(basic_icons)} basic icons"
    )


if __name__ == "__main__":
    main()
