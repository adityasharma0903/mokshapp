import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data'; // For Uint8List and ByteData
import 'dart:ui' as ui; // For ui.instantiateImageCodec
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/services.dart'; // For rootBundle
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import '../../../../constants/app_constants.dart';
import '../../../../../core/services/data_service.dart';
import '../../../../../core/models/student.dart';

class TrackVehicleScreen extends StatefulWidget {
  final Student student;
  final String? vehicleIdFromParent;

  const TrackVehicleScreen({
    super.key,
    required this.student,
    this.vehicleIdFromParent,
  });

  @override
  State<TrackVehicleScreen> createState() => _TrackVehicleScreenState();
}

class _TrackVehicleScreenState extends State<TrackVehicleScreen>
    with TickerProviderStateMixin {
  IO.Socket? _socket;
  String? _vehicleId;
  final DataService _dataService = DataService();

  LatLng? _currentVehicleLocation;
  LatLng? _previousVehicleLocation;
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  List<LatLng> _currentRoute = [];
  List<Map<String, dynamic>> _alternativeRoutes = [];
  int _selectedRouteIndex = 0;

  // Animation for smooth vehicle movement
  AnimationController? _animationController;
  Animation<double>? _animation;
  Timer? _movementTimer;

  // Custom car marker
  BitmapDescriptor? _carIcon;
  double _vehicleBearing = 0.0;

  static const LatLng _defaultDestination = LatLng(30.5789, 76.8372);

  final String _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(30.5789, 76.8372),
    zoom: 14,
  );

  static String get SERVER_URL => AppConstants.socketUrl;

  bool _isInitialLoad = true;
  bool _isLoadingRoutes = false;
  Timer? _locationUpdateTimer;
  bool _isSocketConnected = false;
  int _locationUpdateCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _createCustomMarkers();
    _initTracking();
    _addInitialTestMarkers();
    _startPeriodicLocationUpdates();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _mapController?.dispose();
    _animationController?.dispose();
    _movementTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
  }

  Future<void> _createCustomMarkers() async {
    try {
      final Uint8List iconBytes = await getBytesFromAsset(
        'assets/images/img.png',
        100,
      ); // 100 is the new width
      _carIcon = BitmapDescriptor.fromBytes(iconBytes);
      print('[v0] Custom car icon loaded and resized successfully');
    } catch (e) {
      print(
        '[v0] Failed to load and resize custom car icon, using default: $e',
      );
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  // Future<void> _createCustomMarkers() async {
  //   try {
  //     _carIcon = await BitmapDescriptor.fromAssetImage(
  //       const ImageConfiguration(size: Size(16, 16)),
  //       'assets/images/car_marker.png',
  //     );
  //     print('[v0] Custom car icon loaded successfully');
  //   } catch (e) {
  //     print('[v0] Failed to load custom car icon, using default: $e');
  //     _carIcon =
  //         await BitmapDescriptor.fromAssetImage(
  //           const ImageConfiguration(size: Size(16, 16)),
  //           'assets/images/default_car.png',
  //         ).catchError(
  //           (_) =>
  //               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  //         );
  //   }
  // }

  void _addInitialTestMarkers() {
    print('[v0] Adding initial test markers');

    // Add hardcoded test markers to ensure something shows up
    final testVehicleLocation = const LatLng(30.5789, 76.8372);
    final testDestination = const LatLng(30.5889, 76.8472);

    final vehicleMarker = Marker(
      markerId: const MarkerId('test_vehicle'),
      position: testVehicleLocation,
      infoWindow: const InfoWindow(title: 'Test Vehicle Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    final destinationMarker = Marker(
      markerId: const MarkerId('test_destination'),
      position: testDestination,
      infoWindow: const InfoWindow(title: 'Test Destination'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers.clear();
      _markers.addAll([vehicleMarker, destinationMarker]);
    });

    print('[v0] Initial markers added: ${_markers.length}');
  }

  Future<void> _initTracking() async {
    print('[v0] Starting tracking initialization');
    await _fetchVehicleId();
    print('[v0] Vehicle ID: $_vehicleId');

    if (_vehicleId != null) {
      await _fetchLastKnownLocation();
      _connectSocketAndListen();
    } else {
      print('[v0] No vehicle ID found, keeping test markers');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No vehicle assigned. Showing test markers.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    setState(() => _isInitialLoad = false);
  }

  Future<void> _fetchVehicleId() async {
    try {
      if (widget.vehicleIdFromParent != null &&
          widget.vehicleIdFromParent!.isNotEmpty) {
        _vehicleId = widget.vehicleIdFromParent;
        return;
      }

      if (widget.student.vehicleId != null &&
          widget.student.vehicleId!.isNotEmpty) {
        _vehicleId = widget.student.vehicleId;
        return;
      }

      final response = await _dataService.get(
        'vehicles/by-student/${widget.student.id}',
      );

      if (response is Map && response['vehicle_id'] != null) {
        setState(() => _vehicleId = response['vehicle_id'].toString());
      } else {
        setState(() => _vehicleId = '7958def7-96b8-11f0-a51e-a2aa391e9aae');
      }
    } catch (e) {
      setState(() => _vehicleId = 'f2294eae-d884-4cbe-abf2-3ff5f4845883');
    }
  }

  Future<void> _fetchLastKnownLocation() async {
    if (_vehicleId == null) return;

    print('[v0] Fetching last known location for vehicle: $_vehicleId');
    try {
      final response = await _dataService.get('vehicles/$_vehicleId/location');
      print('[v0] Location response: $response');

      if (response is Map &&
          response['latitude'] != null &&
          response['longitude'] != null) {
        final lat = double.parse(response['latitude'].toString());
        final lng = double.parse(response['longitude'].toString());
        final lastLocation = LatLng(lat, lng);

        print('[v0] Got vehicle location: $lat, $lng');
        _currentVehicleLocation = lastLocation;
        _fetchAndDisplayRoute(lastLocation, _defaultDestination);
        _moveCameraToIncludeBoth(lastLocation, _defaultDestination);
      } else {
        print('[v0] Invalid location response, keeping test markers');
      }
    } catch (e) {
      print('[v0] Error fetching location: $e, keeping test markers');
    }
  }

  void _connectSocketAndListen() {
    if (_vehicleId == null) return;

    _socket = IO.io(
      SERVER_URL,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('[v0] Socket connected successfully');
      setState(() => _isSocketConnected = true);
      _socket!.emit('join_room', 'vehicle_$_vehicleId');
    });

    _socket!.onDisconnect((_) {
      print('[v0] Socket disconnected');
      setState(() => _isSocketConnected = false);
    });

    _socket!.on('location_update', (data) {
      try {
        print('[v0] Received socket location update: $data');
        final double lat = (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] as num).toDouble();
        final vehicleLocation = LatLng(lat, lng);

        _animateVehicleMovement(vehicleLocation);
      } catch (e) {
        print('[v0] Error processing socket location update: $e');
      }
    });

    _socket!.connect();
  }

  void _startPeriodicLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_vehicleId != null) {
        _fetchAndUpdateLiveLocation();
      }
    });
  }

  Future<void> _fetchAndUpdateLiveLocation() async {
    if (_vehicleId == null) return;

    try {
      final response = await _dataService.get('vehicles/$_vehicleId/location');
      print('[v0] Live location update #${++_locationUpdateCount}: $response');

      if (response is Map &&
          response['latitude'] != null &&
          response['longitude'] != null) {
        final lat = double.parse(response['latitude'].toString());
        final lng = double.parse(response['longitude'].toString());
        final newLocation = LatLng(lat, lng);

        if (_currentVehicleLocation == null ||
            _calculateDistance(_currentVehicleLocation!, newLocation) > 0.001) {
          print('[v0] Location changed, updating vehicle position');
          _animateVehicleMovement(newLocation);
        } else {
          print('[v0] Location unchanged, skipping update');
        }
      }
    } catch (e) {
      print('[v0] Error fetching live location: $e');
      _simulateVehicleMovement();
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  void _simulateVehicleMovement() {
    if (_currentVehicleLocation == null) return;

    final random = Random();
    final latOffset = (random.nextDouble() - 0.5) * 0.001; // ~100m
    final lngOffset = (random.nextDouble() - 0.5) * 0.001; // ~100m

    final newLocation = LatLng(
      _currentVehicleLocation!.latitude + latOffset,
      _currentVehicleLocation!.longitude + lngOffset,
    );

    print(
      '[v0] Simulating vehicle movement to: ${newLocation.latitude}, ${newLocation.longitude}',
    );
    _animateVehicleMovement(newLocation);
  }

  void _animateVehicleMovement(LatLng newLocation) {
    if (_currentVehicleLocation == null) {
      _currentVehicleLocation = newLocation;
      _fetchAndDisplayRoute(newLocation, _defaultDestination);
      return;
    }

    _previousVehicleLocation = _currentVehicleLocation;
    final targetLocation = newLocation;

    _vehicleBearing = _calculateBearing(
      _currentVehicleLocation!,
      targetLocation,
    );

    _animationController?.reset();
    _animationController?.forward();

    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_animation != null && _previousVehicleLocation != null) {
        final progress = _animation!.value;
        final lat =
            _previousVehicleLocation!.latitude +
            (targetLocation.latitude - _previousVehicleLocation!.latitude) *
                progress;
        final lng =
            _previousVehicleLocation!.longitude +
            (targetLocation.longitude - _previousVehicleLocation!.longitude) *
                progress;

        _currentVehicleLocation = LatLng(lat, lng);
        _updateVehicleMarker();

        if (progress >= 1.0) {
          timer.cancel();
          _currentVehicleLocation = targetLocation;
          _updateVehicleMarker();
        }
      }
    });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final deltaLng = (end.longitude - start.longitude) * pi / 180;

    final y = sin(deltaLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  Future<void> _fetchAndDisplayRoute(LatLng origin, LatLng destination) async {
    if (_isLoadingRoutes) return;

    setState(() => _isLoadingRoutes = true);

    try {
      print(
        '[v0] API Key configured: ${_googleMapsApiKey.isNotEmpty && _googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY'}',
      );

      if (_googleMapsApiKey.isEmpty ||
          _googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
        print(
          '[v0] Google Maps API key not configured, using fallback polyline',
        );
        _updateMarkersAndPolyline(origin, destination);
        return;
      }

      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'alternatives=true&'
          'key=$_googleMapsApiKey';

      print('[v0] Making API request to: $url');
      final response = await http.get(Uri.parse(url));

      print('[v0] API Response Status: ${response.statusCode}');
      print(
        '[v0] API Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[v0] Google Directions API status: ${data['status']}');

        if (data['status'] == 'REQUEST_DENIED') {
          print('[v0] API Request denied - check API key and billing');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Google Maps API access denied. Check API key and billing.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          _updateMarkersAndPolyline(origin, destination);
          return;
        }

        if (data['status'] == 'OVER_QUERY_LIMIT') {
          print('[v0] API quota exceeded');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Google Maps API quota exceeded. Using fallback route.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          _updateMarkersAndPolyline(origin, destination);
          return;
        }

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          _alternativeRoutes.clear();
          _polylines.clear();

          for (int i = 0; i < data['routes'].length; i++) {
            final route = data['routes'][i];
            final polylinePoints = _decodePolyline(
              route['overview_polyline']['points'],
            );
            final duration = route['legs'][0]['duration']['text'];
            final distance = route['legs'][0]['distance']['text'];

            _alternativeRoutes.add({
              'points': polylinePoints,
              'duration': duration,
              'distance': distance,
              'color': i == 0
                  ? Colors.blue
                  : (i == 1 ? Colors.green : Colors.orange),
            });

            _polylines.add(
              Polyline(
                polylineId: PolylineId('route_$i'),
                points: polylinePoints,
                color: i == _selectedRouteIndex ? Colors.blue : Colors.grey,
                width: i == _selectedRouteIndex ? 6 : 4,
                patterns: i == _selectedRouteIndex
                    ? []
                    : [PatternItem.dash(10), PatternItem.gap(5)],
              ),
            );
          }

          if (_alternativeRoutes.isNotEmpty) {
            _currentRoute = _alternativeRoutes[_selectedRouteIndex]['points'];
          }

          print(
            '[v0] Successfully created ${_polylines.length} polylines from Google Directions',
          );
          _updateMarkersAndCamera(origin, destination);
        } else {
          print('[v0] No routes found in Google Directions response');
          _updateMarkersAndPolyline(origin, destination);
        }
      } else {
        print('[v0] Google Directions API HTTP error: ${response.statusCode}');
        print('[v0] Error response: ${response.body}');
        _updateMarkersAndPolyline(origin, destination);
      }
    } catch (e) {
      print('[v0] Exception fetching route: $e');
      _updateMarkersAndPolyline(origin, destination);
    } finally {
      setState(() => _isLoadingRoutes = false);
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
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

  void _updateVehicleMarker() {
    print(
      '[v0] Updating vehicle marker. Current location: $_currentVehicleLocation',
    );

    if (_currentVehicleLocation == null) {
      print('[v0] No current vehicle location, cannot update marker');
      return;
    }

    final vehicleMarker = Marker(
      markerId: const MarkerId('vehicle'),
      position: _currentVehicleLocation!,
      infoWindow: const InfoWindow(title: 'Vehicle Location'),
      icon:
          _carIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      rotation: _vehicleBearing,
      anchor: const Offset(0.5, 0.5), // Center the marker properly
    );

    final destinationMarker = Marker(
      markerId: const MarkerId('destination'),
      position: _defaultDestination,
      infoWindow: const InfoWindow(title: 'Destination'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers.clear();
      _markers.addAll([vehicleMarker, destinationMarker]);
    });

    print('[v0] Vehicle marker updated. Total markers: ${_markers.length}');
  }

  void _updateMarkersAndPolyline(LatLng start, LatLng end) {
    print('[v0] Creating fallback straight-line polyline');

    final startMarker = Marker(
      markerId: const MarkerId('start'),
      position: start,
      infoWindow: const InfoWindow(title: 'You are here'),
      icon:
          _carIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      rotation: _vehicleBearing,
      anchor: const Offset(0.5, 0.5),
    );

    final endMarker = Marker(
      markerId: const MarkerId('destination'),
      position: end,
      infoWindow: const InfoWindow(title: 'Destination'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    final polyline = Polyline(
      polylineId: const PolylineId('fallback_route'),
      points: [start, end],
      color: Colors.blue,
      width: 5,
      patterns: [
        PatternItem.dash(20),
        PatternItem.gap(10),
      ], // Dashed line to indicate fallback
    );

    setState(() {
      _markers.clear();
      _markers.addAll([startMarker, endMarker]);

      _polylines.clear();
      _polylines.add(polyline);
    });

    print(
      '[v0] Fallback markers and polyline updated. Markers: ${_markers.length}, Polylines: ${_polylines.length}',
    );
  }

  void _updateMarkersAndCamera(LatLng start, LatLng end) {
    _updateVehicleMarker();
    _moveCameraToIncludeBoth(start, end);
  }

  void _moveCameraToIncludeBoth(LatLng start, LatLng end) {
    if (_mapController == null) return;

    final southwestLat = start.latitude < end.latitude
        ? start.latitude
        : end.latitude;
    final southwestLng = start.longitude < end.longitude
        ? start.longitude
        : end.longitude;
    final northeastLat = start.latitude > end.latitude
        ? start.latitude
        : end.latitude;
    final northeastLng = start.longitude > end.longitude
        ? start.longitude
        : end.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    print(
      '[v0] Building map with ${_markers.length} markers and ${_polylines.length} polylines',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Vehicle'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  _isSocketConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isSocketConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'M:${_markers.length} P:${_polylines.length}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            onMapCreated: (controller) {
              _mapController = controller;
              print('[v0] Map controller created');
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            trafficEnabled: true,
            onTap: (LatLng position) {
              print(
                '[v0] Map tapped at: ${position.latitude}, ${position.longitude}',
              );
              final tapMarker = Marker(
                markerId: MarkerId(
                  'tap_${DateTime.now().millisecondsSinceEpoch}',
                ),
                position: position,
                infoWindow: InfoWindow(
                  title: 'Tapped Here',
                  snippet:
                      '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              );

              setState(() {
                _markers.add(tapMarker);
              });
            },
          ),

          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Debug Info:',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Markers: ${_markers.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Polylines: ${_polylines.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Vehicle ID: ${_vehicleId ?? "None"}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Location: ${_currentVehicleLocation?.latitude.toStringAsFixed(4) ?? "None"}, ${_currentVehicleLocation?.longitude.toStringAsFixed(4) ?? "None"}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Socket: ${_isSocketConnected ? "Connected" : "Disconnected"}',
                    style: TextStyle(
                      color: _isSocketConnected ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Updates: $_locationUpdateCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                print('[v0] Manual refresh triggered');
                _fetchAndUpdateLiveLocation();
              },
              child: const Icon(Icons.refresh),
              backgroundColor: Colors.blue,
            ),
          ),

          if (_alternativeRoutes.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Route Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _alternativeRoutes.length,
                        itemBuilder: (context, index) {
                          final route = _alternativeRoutes[index];
                          final isSelected = index == _selectedRouteIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRouteIndex = index;
                                _currentRoute = route['points'];

                                _polylines.clear();
                                for (
                                  int i = 0;
                                  i < _alternativeRoutes.length;
                                  i++
                                ) {
                                  _polylines.add(
                                    Polyline(
                                      polylineId: PolylineId('route_$i'),
                                      points: _alternativeRoutes[i]['points'],
                                      color: i == _selectedRouteIndex
                                          ? Colors.blue
                                          : Colors.grey,
                                      width: i == _selectedRouteIndex ? 6 : 4,
                                      patterns: i == _selectedRouteIndex
                                          ? []
                                          : [
                                              PatternItem.dash(10),
                                              PatternItem.gap(5),
                                            ],
                                    ),
                                  );
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    route['duration'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    route['distance'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoadingRoutes)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Finding best routes...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
