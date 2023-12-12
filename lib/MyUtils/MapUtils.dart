import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapUtils {
  MapType switchMapType(mapType) {
    return mapType == MapType.hybrid ? MapType.normal : MapType.hybrid;
  }

  Future<BitmapDescriptor> createCustomMarkerBitmap(
      int markerNumber4Poly) async {
    PictureRecorder recorder = new PictureRecorder();
    Canvas c = new Canvas(recorder);

    /* Do your painting of the custom icon here, including drawing text, shapes, etc. */

    Paint _paint = Paint()
      ..color = Color.fromARGB(255, 255, 0, 0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;
    c.drawCircle(Offset(35.0, 55.0), 20.0, _paint);

    TextSpan span = new TextSpan(
        style: new TextStyle(
            color: Colors.white,
            fontSize: 35.0,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                  // bottomLeft
                  offset: Offset(-3.0, -3.0),
                  color: Colors.black),
              Shadow(
                  // bottomRight
                  offset: Offset(3.0, -3.0),
                  color: Colors.black),
              Shadow(
                  // topRight
                  offset: Offset(3.0, 3.0),
                  color: Colors.black),
              Shadow(
                  // topLeft
                  offset: Offset(-3.0, 3.0),
                  color: Colors.black),
            ]),
        text: markerNumber4Poly.toString());

    TextPainter tp = new TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(c, new Offset(3.0, 0.0));

    Picture p = recorder.endRecording();
    ByteData? pngBytes =
        await (await p.toImage(65, 75)).toByteData(format: ImageByteFormat.png);

    Uint8List data = Uint8List.view(pngBytes!.buffer);

    return BitmapDescriptor.fromBytes(data);
  }
}
