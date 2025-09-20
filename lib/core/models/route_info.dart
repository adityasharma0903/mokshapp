import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final int distanceValue; // in meters
  final int durationValue; // in seconds
  final String startAddress;
  final String endAddress;
  final List<LatLng> waypoints;
  final LatLng? lastCalculatedFrom;
  final List<String> instructions;

  RouteInfo({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
    required this.startAddress,
    required this.endAddress,
    required this.waypoints,
    this.lastCalculatedFrom,
    required this.instructions,
  });

  double get distanceInKm => distanceValue / 1000.0;
  double get durationInMinutes => durationValue / 60.0;

  @override
  String toString() {
    return 'RouteInfo(distance: $distance, duration: $duration, points: ${polylinePoints.length})';
  }
}
