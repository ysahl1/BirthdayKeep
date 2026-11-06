// Zeichnet das App-Icon aus einfachen Formen. Danach die Launcher-Icons erzeugen:
//   dart run tool/generate_icon.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

const int _workSize = 2048;
const int _background = 0xFF5E17EB;

typedef _Paint = void Function(_Canvas canvas);

class _Canvas {
  final img.Image image;
  final bool mask;
  final bool notification;
  _Canvas(this.image, {this.mask = false, this.notification = false});

  // Alle Koordinaten beziehen sich auf eine Fläche von 1000 x 1000
  int _s(num v) => (v * image.width / 1000).round();

  img.Color _color(int argb) => mask
      ? img.ColorRgba8(255, 255, 255, 255)
      : img.ColorRgba8(
          (argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF, 255);

  void rect(num x, num y, num w, num h, num r, int color) {
    img.fillRect(image,
        x1: _s(x),
        y1: _s(y),
        x2: _s(x + w),
        y2: _s(y + h),
        radius: _s(r),
        color: _color(color));
  }

  void circle(num x, num y, num r, int color) {
    img.fillCircle(image,
        x: _s(x), y: _s(y), radius: _s(r), color: _color(color));
  }

  void flame(num x, num y, int color) {
    final points = <img.Point>[];
    for (var i = 0; i < 40; i++) {
      final t = i / 40 * 2 * pi;
      // Tropfenform: unten rund, oben spitz
      final rx = 22 * sin(t) * pow(sin(t / 2), 1.1);
      final ry = -44 * cos(t);
      points.add(img.Point(_s(x + rx), _s(y + ry)));
    }
    img.fillPolygon(image, vertices: points, color: _color(color));
  }

  // Trennlinien, damit die kleine Benachrichtigungs-Silhouette lesbar bleibt
  void gap(num x, num y, num w, num h) {
    if (!notification) return;
    img.fillRect(image,
        x1: _s(x),
        y1: _s(y),
        x2: _s(x + w),
        y2: _s(y + h),
        color: img.ColorRgba8(0, 0, 0, 255));
  }
}

void _cake(_Canvas c) {
  const cream = 0xFFFFE6B0;
  const creamDark = 0xFFF8C77E;
  const creamLight = 0xFFFFF3D6;
  const mint = 0xFFA5E8D5;
  const white = 0xFFFFFFFF;
  const pink = 0xFFFF8FAB;
  const yellow = 0xFFFFD166;
  const plate = 0xFFE4E0FF;

  // Teller
  c.rect(120, 835, 760, 45, 22, plate);
  c.gap(120, 822, 760, 18);

  // Untere Etage mit Füllung und Zuckerguss
  c.rect(190, 550, 620, 285, 28, cream);
  c.rect(190, 725, 620, 34, 0, creamDark);
  c.rect(172, 530, 656, 80, 40, mint);
  for (final drip in const [
    [215, 95],
    [305, 135],
    [395, 80],
    [485, 150],
    [575, 90],
    [665, 125],
    [745, 85],
  ]) {
    c.rect(drip[0], 575, 56, drip[1], 28, mint);
  }

  // Obere Etage mit Streuseln und Sahne
  c.rect(285, 330, 430, 215, 24, creamLight);
  for (final dot in const [
    [345, 460],
    [430, 495],
    [500, 445],
    [570, 495],
    [655, 460],
  ]) {
    c.circle(dot[0], dot[1], 16, pink);
  }
  c.rect(268, 305, 464, 75, 37, white);
  c.gap(268, 512, 464, 22);

  // Kerzen
  for (final x in const [370, 500, 630]) {
    c.rect(x - 17, 170, 34, 140, 10, white);
    c.rect(x - 17, 200, 34, 24, 0, pink);
    c.rect(x - 17, 252, 34, 24, 0, pink);
    c.flame(x, 110, yellow);
  }
}

img.Image _render(_Paint paint, {required bool mask, bool notification = false}) {
  final canvas = img.Image(width: _workSize, height: _workSize, numChannels: 4);
  img.fill(canvas,
      color: mask
          ? img.ColorRgba8(0, 0, 0, 255)
          : img.ColorRgba8((_background >> 16) & 0xFF,
              (_background >> 8) & 0xFF, _background & 0xFF, 255));
  paint(_Canvas(canvas, mask: mask, notification: notification));
  return canvas;
}

// Legt die Torte verkleinert in die Mitte einer leeren Fläche
img.Image _scaled(img.Image source, int size, double fill, {required int base}) {
  final inner = (size * fill).round();
  final small = img.copyResize(source,
      width: inner, height: inner, interpolation: img.Interpolation.average);
  final out = img.Image(width: size, height: size, numChannels: 4);
  img.fill(out,
      color: img.ColorRgba8(
          (base >> 16) & 0xFF, (base >> 8) & 0xFF, base & 0xFF, 255));
  img.compositeImage(out, small,
      dstX: (size - inner) ~/ 2, dstY: (size - inner) ~/ 2);
  return out;
}

void _write(String path, img.Image image) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image));
}

void main() {
  final color = _render(_cake, mask: false);
  final mask = _render(_cake, mask: true);
  final notificationMask = _render(_cake, mask: true, notification: true);

  // Vollständiges Icon (auch für iOS und den F-Droid-Eintrag)
  final full = _scaled(color, 1024, 0.84, base: _background);
  _write('assets/icon/BDMIcon.png', full);
  for (final lang in const ['en-US', 'de-DE']) {
    _write(
      'fastlane/metadata/android/$lang/images/icon.png',
      img.copyResize(full,
          width: 512, height: 512, interpolation: img.Interpolation.average),
    );
  }

  // Vordergrund für adaptive Icons: nur die inneren 61 % sind immer sichtbar
  final foreground = _scaled(color, 1024, 0.60, base: _background);
  final foregroundMask = _scaled(mask, 1024, 0.60, base: 0xFF000000);
  for (final p in foreground) {
    p.a = foregroundMask.getPixel(p.x, p.y).r;
  }
  _write('assets/icon/icon_adaptive_foreground.png', foreground);

  // Benachrichtigung: weiße Silhouette, nur der Alphakanal zählt
  const sizes = {'mdpi': 24, 'hdpi': 36, 'xhdpi': 48, 'xxhdpi': 72, 'xxxhdpi': 96};
  sizes.forEach((density, size) {
    final icon = _scaled(notificationMask, size, 0.96, base: 0xFF000000);
    for (final p in icon) {
      final alpha = p.r;
      p
        ..r = 255
        ..g = 255
        ..b = 255
        ..a = alpha;
    }
    _write(
        'android/app/src/main/res/drawable-$density/ic_notification.png', icon);
  });
}
