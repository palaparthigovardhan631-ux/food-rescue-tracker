import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/countdown_formatter.dart';

class UrgencyMapMarkerHelper {
  /// Converts an urgency level into a colored Google Map BitmapDescriptor pin.
  static Future<BitmapDescriptor> getUrgencyMarkerIcon(UrgencyLevel urgency) async {
    final color = CountdownFormatter.getUrgencyColor(urgency);
    return await _createCustomMarkerBitmap(color);
  }

  static Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(80, 100);

    final paintCircle = Paint()..color = color;
    final paintWhite = Paint()..color = Colors.white;

    // Draw Pin Head
    canvas.drawCircle(const Offset(40, 36), 32, paintCircle);
    canvas.drawCircle(const Offset(40, 36), 26, paintWhite);
    canvas.drawCircle(const Offset(40, 36), 18, paintCircle);

    // Draw Pin Point
    final path = Path();
    path.moveTo(24, 52);
    path.lineTo(40, 92);
    path.lineTo(56, 52);
    path.close();
    canvas.drawPath(path, paintCircle);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes == null) {
      // Fallback standard marker with hue
      double hue = BitmapDescriptor.hueGreen;
      if (color == AppColors.urgencyCritical) hue = BitmapDescriptor.hueRed;
      if (color == AppColors.urgencyWarning) hue = BitmapDescriptor.hueOrange;
      return BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }
}
