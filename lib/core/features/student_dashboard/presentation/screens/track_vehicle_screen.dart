import 'dart:async';
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

  static const String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(30.5789, 76.8372),
    zoom: 14,
  );

  static String get SERVER_URL => AppConstants.socketUrl;

  bool _isInitialLoad = true;
  bool _isLoadingRoutes = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _createCustomMarkers();
    _initTracking();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _mapController?.dispose();
    _animationController?.dispose();
    _movementTimer?.cancel();
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
    _carIcon =
        await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/images/car_marker.png', // Add this asset to your project
        ).catchError((_) {
          // Fallback to default marker if custom asset not found
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
        });
  }

  Future<void> _initTracking() async {
    await _fetchVehicleId();
    if (_vehicleId != null) {
      await _fetchLastKnownLocation();
      _connectSocketAndListen();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No vehicle assigned.'),
            backgroundColor: Colors.red,
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

    try {
      final response = await _dataService.get('vehicles/$_vehicleId/location');
      if (response is Map &&
          response['latitude'] != null &&
          response['longitude'] != null) {
        final lat = double.parse(response['latitude'].toString());
        final lng = double.parse(response['longitude'].toString());
        final lastLocation = LatLng(lat, lng);

        _currentVehicleLocation = lastLocation;
        _fetchAndDisplayRoute(lastLocation, _defaultDestination);
        _moveCameraToIncludeBoth(lastLocation, _defaultDestination);
      }
    } catch (_) {}
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
      _socket!.emit('join_room', 'vehicle_$_vehicleId');
    });

    _socket!.on('location_update', (data) {
      try {
        final double lat = (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] as num).toDouble();
        final vehicleLocation = LatLng(lat, lng);

        _animateVehicleMovement(vehicleLocation);
      } catch (_) {}
    });

    _socket!.connect();
  }

  void _animateVehicleMovement(LatLng newLocation) {
    if (_currentVehicleLocation == null) {
      _currentVehicleLocation = newLocation;
      _fetchAndDisplayRoute(newLocation, _defaultDestination);
      return;
    }

    _previousVehicleLocation = _currentVehicleLocation;
    final targetLocation = newLocation;

    // Calculate bearing for car rotation
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
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'alternatives=true&'
          'key=$_googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

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

            // Add polyline to map
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

          _updateMarkersAndCamera(origin, destination);
        }
      }
    } catch (e) {
      // Fallback to simple polyline if API fails
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
    if (_currentVehicleLocation == null) return;

    final vehicleMarker = Marker(
      markerId: const MarkerId('vehicle'),
      position: _currentVehicleLocation!,
      infoWindow: const InfoWindow(title: 'Vehicle Location'),
      icon:
          _carIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      rotation: _vehicleBearing,
      anchor: const Offset(0.5, 0.5),
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
  }

  void _updateMarkersAndCamera(LatLng start, LatLng end) {
    _updateVehicleMarker();
    _moveCameraToIncludeBoth(start, end);
  }

  void _updateMarkersAndPolyline(LatLng start, LatLng end) {
    final startMarker = Marker(
      markerId: const MarkerId('start'),
      position: start,
      infoWindow: const InfoWindow(title: 'You are here'),
      icon:
          _carIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      rotation: _vehicleBearing,
    );

    final endMarker = Marker(
      markerId: const MarkerId('destination'),
      position: end,
      infoWindow: const InfoWindow(title: 'Destination'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [start, end],
      color: Colors.blue,
      width: 5,
    );

    setState(() {
      _markers.clear();
      _markers.addAll([startMarker, endMarker]);

      _polylines.clear();
      _polylines.add(polyline);
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Vehicle'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            trafficEnabled: true,
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

                                // Update polyline colors
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
