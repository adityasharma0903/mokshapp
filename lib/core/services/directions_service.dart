import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/models/route_info.dart';
import 'package:my_app/core/utils/polyline_decoder.dart';

enum TravelMode { driving, walking, bicycling, transit }

class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String _apiKey =
      'AIzaSyDLNz0G34OLxEQTqnDTG1_GurQImTxHs6U'; // Replace with your API key

  Future<RouteInfo?> getDirections({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
    List<LatLng>? waypoints,
    bool optimizeWaypoints = false,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
  }) async {
    try {
      final url = _buildDirectionsUrl(
        origin: origin,
        destination: destination,
        travelMode: travelMode,
        waypoints: waypoints,
        optimizeWaypoints: optimizeWaypoints,
        avoidTolls: avoidTolls,
        avoidHighways: avoidHighways,
        avoidFerries: avoidFerries,
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return _parseRouteFromResponse(data, origin);
        } else {
          print('Directions API error: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }
          return null;
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  String _buildDirectionsUrl({
    required LatLng origin,
    required LatLng destination,
    required TravelMode travelMode,
    List<LatLng>? waypoints,
    bool optimizeWaypoints = false,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
  }) {
    final params = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': _getTravelModeString(travelMode),
      'key': _apiKey,
    };

    if (waypoints != null && waypoints.isNotEmpty) {
      final waypointString = waypoints
          .map((wp) => '${wp.latitude},${wp.longitude}')
          .join('|');
      params['waypoints'] = optimizeWaypoints
          ? 'optimize:true|$waypointString'
          : waypointString;
    }

    final avoidances = <String>[];
    if (avoidTolls) avoidances.add('tolls');
    if (avoidHighways) avoidances.add('highways');
    if (avoidFerries) avoidances.add('ferries');

    if (avoidances.isNotEmpty) {
      params['avoid'] = avoidances.join('|');
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
    return uri.toString();
  }

  String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.transit:
        return 'transit';
    }
  }

  RouteInfo _parseRouteFromResponse(Map<String, dynamic> data, LatLng origin) {
    final route = data['routes'][0];
    final leg = route['legs'][0];

    // Decode polyline points
    final encodedPolyline = route['overview_polyline']['points'];
    final polylinePoints = PolylineDecoder.decode(encodedPolyline);

    // Extract waypoints from steps
    final steps = leg['steps'] as List;
    final waypoints = <LatLng>[];

    for (final step in steps) {
      final startLocation = step['start_location'];
      waypoints.add(
        LatLng(
          startLocation['lat'].toDouble(),
          startLocation['lng'].toDouble(),
        ),
      );
    }

    return RouteInfo(
      polylinePoints: polylinePoints,
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      distanceValue: leg['distance']['value'],
      durationValue: leg['duration']['value'],
      startAddress: leg['start_address'],
      endAddress: leg['end_address'],
      waypoints: waypoints,
      lastCalculatedFrom: origin,
      instructions: _extractInstructions(steps),
    );
  }

  List<String> _extractInstructions(List steps) {
    return steps.map<String>((step) {
      final instruction = step['html_instructions'] as String;
      // Remove HTML tags for clean text
      return instruction.replaceAll(RegExp(r'<[^>]*>'), '');
    }).toList();
  }

  Future<List<RouteInfo>> getAlternativeRoutes({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    try {
      final url =
          _buildDirectionsUrl(
            origin: origin,
            destination: destination,
            travelMode: travelMode,
          ) +
          '&alternatives=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final routes = <RouteInfo>[];

          for (final routeData in data['routes']) {
            final modifiedData = {
              'routes': [routeData],
              'status': 'OK',
            };
            final route = _parseRouteFromResponse(modifiedData, origin);
            routes.add(route);
          }

          return routes;
        }
      }

      return [];
    } catch (e) {
      print('Error getting alternative routes: $e');
      return [];
    }
  }
}
