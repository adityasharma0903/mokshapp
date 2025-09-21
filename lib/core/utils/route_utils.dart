import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteUtils {
  static const String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static Future<List<Map<String, dynamic>>> getRoutes(
    LatLng origin,
    LatLng destination, {
    bool alternatives = true,
  }) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'alternatives=$alternatives&'
          'traffic_model=best_guess&'
          'departure_time=now&'
          'key=$_googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          List<Map<String, dynamic>> routes = [];

          for (int i = 0; i < data['routes'].length; i++) {
            final route = data['routes'][i];
            final polylinePoints = decodePolyline(
              route['overview_polyline']['points'],
            );
            final leg = route['legs'][0];

            routes.add({
              'points': polylinePoints,
              'duration': leg['duration']['text'],
              'durationValue': leg['duration']['value'],
              'distance': leg['distance']['text'],
              'distanceValue': leg['distance']['value'],
              'summary': route['summary'] ?? 'Route ${i + 1}',
              'trafficDuration': leg['duration_in_traffic']?['text'],
            });
          }

          return routes;
        }
      }
    } catch (e) {
      print('Error fetching routes: $e');
    }

    return [];
  }

  static List<LatLng> decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final deltaLng = (end.longitude - start.longitude) * pi / 180;

    final y = sin(deltaLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  static double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final lat1Rad = start.latitude * pi / 180;
    final lat2Rad = end.latitude * pi / 180;
    final deltaLatRad = (end.latitude - start.latitude) * pi / 180;
    final deltaLngRad = (end.longitude - start.longitude) * pi / 180;

    final a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
