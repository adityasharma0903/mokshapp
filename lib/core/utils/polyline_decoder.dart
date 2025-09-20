import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineDecoder {
  static List<LatLng> decode(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylineCoordinates;
  }

  static String encode(List<LatLng> polylineCoordinates) {
    if (polylineCoordinates.isEmpty) return '';

    StringBuffer encodedString = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (LatLng coordinate in polylineCoordinates) {
      int lat = (coordinate.latitude * 1E5).round();
      int lng = (coordinate.longitude * 1E5).round();

      int dLat = lat - prevLat;
      int dLng = lng - prevLng;

      encodedString.write(_encodeValue(dLat));
      encodedString.write(_encodeValue(dLng));

      prevLat = lat;
      prevLng = lng;
    }

    return encodedString.toString();
  }

  static String _encodeValue(int value) {
    value = value < 0 ? ~(value << 1) : value << 1;
    StringBuffer encoded = StringBuffer();

    while (value >= 0x20) {
      encoded.writeCharCode((0x20 | (value & 0x1f)) + 63);
      value >>= 5;
    }

    encoded.writeCharCode(value + 63);
    return encoded.toString();
  }
}
