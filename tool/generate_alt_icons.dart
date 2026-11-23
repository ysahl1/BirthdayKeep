// Zeichnet die zusätzlichen App-Icons (Ballons, Kalender, Cupcake):
//   dart run tool/generate_alt_icons.dart
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

const int _workSize = 2048;
const String _res = 'android/app/src/main/res';

// Alle Koordinaten beziehen sich auf eine Fläche von 1000 x 1000
class _Canvas {
  final img.Image image;
  final bool mask;
  double ox = 0, oy = 0, k = 1;
  _Canvas(this.image, {this.mask = false});

  int _s(num v) => (v * image.width / 1000).round();
  int _x(num x) => _s(ox + x * k);
  int _y(num y) => _s(oy + y * k);

  img.Color _color(int argb) =>
      mask
          ? img.ColorRgba8(255, 255, 255, 255)
          : img.ColorRgba8(
            (argb >> 16) & 0xFF,
            (argb >> 8) & 0xFF,
            argb & 0xFF,
            255,
          );

  void rect(num x, num y, num w, num h, num r, int color) => img.fillRect(
    image,
    x1: _x(x),
    y1: _y(y),
    x2: _x(x + w),
    y2: _y(y + h),
    radius: _s(r * k),
    color: _color(color),
  );

  void circle(num x, num y, num r, int color) => img.fillCircle(
    image,
    x: _x(x),
    y: _y(y),
    radius: _s(r * k),
    color: _color(color),
  );

  void polygon(List<List<num>> points, int color) => img.fillPolygon(
    image,
    vertices: [for (final p in points) img.Point(_x(p[0]), _y(p[1]))],
    color: _color(color),
  );

  void ellipse(num x, num y, num rx, num ry, int color) => polygon([
    for (var i = 0; i < 60; i++)
      [x + rx * cos(i / 60 * 2 * pi), y + ry * sin(i / 60 * 2 * pi)],
  ], color);

  void flame(num x, num y, int color, [num size = 1]) => polygon([
    for (var i = 0; i < 40; i++)
      [
        x + 22 * size * sin(i / 40 * 2 * pi) * pow(sin(i / 80 * 2 * pi), 1.1),
        y - 44 * size * cos(i / 40 * 2 * pi),
      ],
  ], color);
}

class _Icon {
  final String name;
  final int background;
  final void Function(_Canvas c) draw;
  const _Icon(this.name, this.background, this.draw);
}

void _miniCake(_Canvas c) {
  c.rect(120, 835, 760, 45, 22, 0xFFE4E0FF);
  c.rect(190, 550, 620, 285, 28, 0xFFFFE6B0);
  c.rect(190, 725, 620, 34, 0, 0xFFF8C77E);
  c.rect(172, 530, 656, 80, 40, 0xFFA5E8D5);
  for (final d in const [
    [215, 95],
    [305, 135],
    [395, 80],
    [485, 150],
    [575, 90],
    [665, 125],
    [745, 85],
  ]) {
    c.rect(d[0], 575, 56, d[1], 28, 0xFFA5E8D5);
  }
  c.rect(285, 330, 430, 215, 24, 0xFFFFF3D6);
  for (final d in const [
    [345, 460],
    [430, 495],
    [500, 445],
    [570, 495],
    [655, 460],
  ]) {
    c.circle(d[0], d[1], 16, 0xFFFF8FAB);
  }
  c.rect(268, 305, 464, 75, 37, 0xFFFFFFFF);
  for (final x in const [370, 500, 630]) {
    c.rect(x - 17, 170, 34, 140, 10, 0xFFFFFFFF);
    c.rect(x - 17, 200, 34, 24, 0, 0xFFFF8FAB);
    c.rect(x - 17, 252, 34, 24, 0, 0xFFFF8FAB);
    c.flame(x, 110, 0xFFFFD166);
  }
}

final List<_Icon> _icons = [
  _Icon('balloons', 0xFF3D8BFD, (c) {
    void balloon(num x, num y, int color) {
      c.rect(x - 3, y + 150, 6, 330, 3, 0xFFE8EEFF);
      c.polygon([
        [x - 22, y + 165],
        [x + 22, y + 165],
        [x, y + 135],
      ], color);
      c.ellipse(x, y, 125, 155, color);
      c.ellipse(x - 45, y - 60, 22, 38, 0xFFFFFFFF);
    }

    balloon(330, 330, 0xFFFF6B8B);
    balloon(670, 300, 0xFFFFD166);
    balloon(500, 400, 0xFF7CE0C3);
  }),
  _Icon('calendar', 0xFF5E17EB, (c) {
    c.rect(180, 220, 640, 600, 60, 0xFFFFFFFF);
    c.rect(180, 220, 640, 170, 60, 0xFFFF5D8F);
    c.rect(180, 330, 640, 60, 0, 0xFFFF5D8F);
    c.rect(330, 170, 44, 120, 22, 0xFF2B2B40);
    c.rect(626, 170, 44, 120, 22, 0xFF2B2B40);
    final (ox, oy, k) = (c.ox, c.oy, c.k);
    c
      ..ox = ox + 290 * k
      ..oy = oy + 360 * k
      ..k = 0.42 * k;
    _miniCake(c);
    c
      ..ox = ox
      ..oy = oy
      ..k = k;
  }),
  _Icon('cupcake', 0xFFFF8FAB, (c) {
    c.polygon([
      [290, 560],
      [710, 560],
      [650, 840],
      [350, 840],
    ], 0xFFFFD39A);
    for (final x in const [360, 430, 500, 570, 640]) {
      c.rect(x - 8, 580, 16, 250, 8, 0xFFF3B76B);
    }
    c.circle(320, 540, 90, 0xFFFFFFFF);
    c.circle(680, 540, 90, 0xFFFFFFFF);
    c.circle(410, 450, 110, 0xFFFFFFFF);
    c.circle(590, 450, 110, 0xFFFFFFFF);
    c.circle(500, 400, 120, 0xFFFFFFFF);
    c.rect(480, 190, 40, 120, 12, 0xFF5E17EB);
    c.flame(500, 140, 0xFFFFB703, 1.2);
    for (final d in const [
      [420, 470],
      [560, 430],
      [480, 520],
      [620, 520],
      [370, 540],
    ]) {
      c.rect(d[0] - 16, d[1] - 6, 32, 12, 6, 0xFF5E17EB);
    }
  }),
];

img.Image _render(_Icon icon, {required bool mask, required double scale}) {
  final image = img.Image(width: _workSize, height: _workSize, numChannels: 4);
  img.fill(
    image,
    color:
        mask
            ? img.ColorRgba8(0, 0, 0, 255)
            : img.ColorRgba8(
              (icon.background >> 16) & 0xFF,
              (icon.background >> 8) & 0xFF,
              icon.background & 0xFF,
              255,
            ),
  );
  final c =
      _Canvas(image, mask: mask)
        ..k = scale
        ..ox = 500 * (1 - scale)
        ..oy = 500 * (1 - scale);
  icon.draw(c);
  return image;
}

img.Image _resize(img.Image source, int size) => img.copyResize(
  source,
  width: size,
  height: size,
  interpolation: img.Interpolation.average,
);

void _write(String path, img.Image image) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image));
}

void main() {
  const legacy = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  const foreground = {
    'mdpi': 108,
    'hdpi': 162,
    'xhdpi': 216,
    'xxhdpi': 324,
    'xxxhdpi': 432,
  };

  for (final icon in _icons) {
    final name = 'ic_launcher_${icon.name}';
    final full = _render(icon, mask: false, scale: 0.9);

    // Vorschau für die Auswahl in der App und Icon für ältere Android-Versionen
    _write('assets/icon/app_icon_${icon.name}.png', _resize(full, 256));
    legacy.forEach(
      (density, size) =>
          _write('$_res/mipmap-$density/$name.png', _resize(full, size)),
    );

    // Adaptives Icon: nur die inneren 61 % sind bei jeder Maske sichtbar
    final color = _render(icon, mask: false, scale: 0.62);
    final alpha = _render(icon, mask: true, scale: 0.62);
    foreground.forEach((density, size) {
      final fg = _resize(color, size);
      final fgMask = _resize(alpha, size);
      for (final p in fg) {
        p.a = fgMask.getPixel(p.x, p.y).r;
      }
      _write('$_res/drawable-$density/${name}_foreground.png', fg);
    });

    final hex = (icon.background & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    File('$_res/mipmap-anydpi-v26/$name.xml').writeAsStringSync(
      '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/${name}_background"/>
  <foreground android:drawable="@drawable/${name}_foreground"/>
</adaptive-icon>
''',
    );
    File('$_res/values/${name}_color.xml').writeAsStringSync(
      '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="${name}_background">#$hex</color>
</resources>
''',
    );
  }

  // Vorschau des Standard-Icons für die Auswahl in der App
  final standard =
      img.decodePng(File('assets/icon/BDMIcon.png').readAsBytesSync())!;
  _write('assets/icon/app_icon_cake.png', _resize(standard, 256));
}
