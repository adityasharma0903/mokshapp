import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/models/student.dart';
import 'package:my_app/core/services/data_service.dart';
import 'package:my_app/core/services/directions_service.dart';
import 'package:my_app/core/models/route_info.dart';
import 'dart:math' as math;

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

class _TrackVehicleScreenState extends State<TrackVehicleScreen> {
  IO.Socket? _socket;
  String? _vehicleId;
  final DataService _dataService = DataService();
  final DirectionsService _directionsService = DirectionsService();

  bool _isVehicleOnline = false;
  bool _isSocketConnected = false;
  bool _isLoadingRoute = false;

  LatLng? _currentVehicleLocation;
  RouteInfo? _currentRoute;
  Timer? _reconnectTimer;
  Timer? _routeUpdateTimer;

  static const String SERVER_URL = 'http://10.0.2.2:3000';
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  static const LatLng _defaultDestination = LatLng(30.5789, 76.8372);

  CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(30.5789, 76.8372),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _routeUpdateTimer?.cancel();
    _leaveSocketRoom();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initTracking() async {
    await _fetchVehicleId();
    _setupDestinationMarker();
    _connectSocketAndListen();
    await _fetchLastKnownLocation();
  }

  Future<void> _fetchVehicleId() async {
    try {
      if (widget.vehicleIdFromParent != null) {
        _vehicleId = widget.vehicleIdFromParent;
        print('Using vehicle ID from parent: $_vehicleId');
        return;
      }

      if (widget.student.vehicleId != null &&
          widget.student.vehicleId!.isNotEmpty) {
        _vehicleId = widget.student.vehicleId;
        print('Using vehicle ID from student: $_vehicleId');
        return;
      }

      final response = await _dataService.get(
        'vehicles/by-student/${widget.student.id}',
      );
      if (response is Map && response['vehicle_id'] != null) {
        setState(() {
          _vehicleId = response['vehicle_id'].toString();
        });
        print('Fetched vehicle ID from API: $_vehicleId');
      } else {
        print('No vehicle assigned to student, using fallback');
        _vehicleId = 'f2294eae-d884-4cbe-abf2-3ff5f4845883';
      }
    } catch (e) {
      print('Error fetching vehicle ID: $e');
      _vehicleId = 'f2294eae-d884-4cbe-abf2-3ff5f4845883';
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

        print('Found last known location: $lat, $lng');
        await _updateVehicleLocationWithRoute(lastLocation);

        setState(() {
          _isVehicleOnline = false;
        });
      }
    } catch (e) {
      print('Error fetching last known location: $e');
    }
  }

  void _setupDestinationMarker() {
    final destinationMarker = Marker(
      markerId: const MarkerId('destination'),
      position: _defaultDestination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(
        title: 'Destination',
        snippet: 'Derabassi, Punjab, India',
      ),
    );

    setState(() {
      _markers.add(destinationMarker);
    });
  }

  void _connectSocketAndListen() {
    if (_vehicleId == null) {
      print('Cannot connect socket: vehicle ID is null');
      return;
    }

    _socket = IO.io(
      SERVER_URL,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('Student socket connected: ${_socket!.id}');
      setState(() {
        _isSocketConnected = true;
      });

      final room = 'vehicle_$_vehicleId';
      _socket!.emit('join_room', room);
      print('Student joining room: $room');
    });

    _socket!.on('room_joined', (data) {
      print('Successfully joined room: ${data['room']}');
    });

    _socket!.on('location_update', (data) {
      print('Student received location update: $data');
      try {
        final double lat = (data['latitude'] is int)
            ? (data['latitude'] as int).toDouble()
            : (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] is int)
            ? (data['longitude'] as int).toDouble()
            : (data['longitude'] as num).toDouble();

        final vehicleLocation = LatLng(lat, lng);
        _updateVehicleLocationWithRoute(vehicleLocation);

        if (!_isVehicleOnline) {
          setState(() {
            _isVehicleOnline = true;
          });
        }
      } catch (e) {
        print('Invalid location update data: $e');
      }
    });

    _socket!.on('vehicle_offline', (data) {
      print('Vehicle went offline: $data');
      setState(() {
        _isVehicleOnline = false;
      });
    });

    _socket!.onDisconnect((_) {
      print('Student socket disconnected');
      setState(() {
        _isSocketConnected = false;
        _isVehicleOnline = false;
      });

      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isSocketConnected) {
          print('Attempting to reconnect...');
          _socket?.connect();
        }
      });
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
    });

    _socket!.connect();
  }

  void _leaveSocketRoom() {
    if (_socket != null) {
      final room = _vehicleId != null ? 'vehicle_$_vehicleId' : null;
      if (room != null) {
        _socket!.emit('leave_room', room);
      }
      _socket!.disconnect();
      _socket = null;
    }
  }

  Future<void> _updateVehicleLocationWithRoute(LatLng vehicleLocation) async {
    _currentVehicleLocation = vehicleLocation;

    // Update vehicle marker immediately
    _updateVehicleMarker(vehicleLocation);

    // Check if we need to update the route (significant location change or no existing route)
    if (_shouldUpdateRoute(vehicleLocation)) {
      await _fetchAndDisplayRoute(vehicleLocation, _defaultDestination);
    }

    _fitCameraToShowBothLocations(vehicleLocation, _defaultDestination);
  }

  bool _shouldUpdateRoute(LatLng newLocation) {
    if (_currentRoute == null) return true;

    // Update route if vehicle moved more than 100 meters from last route calculation
    if (_currentRoute!.lastCalculatedFrom != null) {
      final distance = _calculateDistance(
        newLocation,
        _currentRoute!.lastCalculatedFrom!,
      );
      return distance > 0.1; // 100 meters
    }

    return true;
  }

  Future<void> _fetchAndDisplayRoute(LatLng origin, LatLng destination) async {
    if (_isLoadingRoute) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final route = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.driving,
      );

      if (route != null && mounted) {
        setState(() {
          _currentRoute = route;
          _isLoadingRoute = false;
        });

        _displayRoute(route);
        _showRouteInfo(route);
      }
    } catch (e) {
      print('Error fetching route: $e');
      setState(() {
        _isLoadingRoute = false;
      });

      // Fallback to straight line if routing fails
      _displayStraightLineRoute(origin, destination);
    }
  }

  void _displayRoute(RouteInfo route) {
    final routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      points: route.polylinePoints,
      color: Colors.blue,
      width: 4,
      patterns: [],
    );

    // Add waypoint markers if any
    Set<Marker> waypointMarkers = {};
    for (int i = 0; i < route.waypoints.length; i++) {
      waypointMarkers.add(
        Marker(
          markerId: MarkerId('waypoint_$i'),
          position: route.waypoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: 'Waypoint ${i + 1}'),
        ),
      );
    }

    setState(() {
      _polylines.clear();
      _polylines.add(routePolyline);

      // Remove old waypoint markers
      _markers.removeWhere(
        (marker) => marker.markerId.value.startsWith('waypoint_'),
      );
      _markers.addAll(waypointMarkers);
    });
  }

  void _displayStraightLineRoute(LatLng origin, LatLng destination) {
    final straightLinePolyline = Polyline(
      polylineId: const PolylineId('straight_line'),
      points: [origin, destination],
      color: Colors.red,
      width: 3,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );

    setState(() {
      _polylines.clear();
      _polylines.add(straightLinePolyline);
    });
  }

  void _updateVehicleMarker(LatLng vehicleLocation) {
    final distance = _calculateDistance(vehicleLocation, _defaultDestination);

    final vehicleMarker = Marker(
      markerId: MarkerId('vehicle_$_vehicleId'),
      position: vehicleLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: 'Vehicle $_vehicleId',
        snippet: _formatDistance(distance),
      ),
    );

    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value.startsWith('vehicle_'),
      );
      _markers.add(vehicleMarker);
    });
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  void _showRouteInfo(RouteInfo route) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Route: ${route.distance} • ${route.duration}'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;

    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  void _fitCameraToShowBothLocations(LatLng vehicle, LatLng destination) async {
    if (_mapController == null) return;

    try {
      List<LatLng> allPoints = [vehicle, destination];

      // Include route points for better camera fitting
      if (_currentRoute != null && _currentRoute!.polylinePoints.isNotEmpty) {
        allPoints.addAll(_currentRoute!.polylinePoints);
      }

      double minLat = allPoints.map((p) => p.latitude).reduce(math.min);
      double maxLat = allPoints.map((p) => p.latitude).reduce(math.max);
      double minLng = allPoints.map((p) => p.longitude).reduce(math.min);
      double maxLng = allPoints.map((p) => p.longitude).reduce(math.max);

      double latPadding = (maxLat - minLat) * 0.1;
      double lngPadding = (maxLng - minLng) * 0.1;

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          100.0,
        ),
      );
    } catch (e) {
      print('Error fitting camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Vehicle'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoadingRoute)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _fetchLastKnownLocation();
              if (!_isSocketConnected) {
                _socket?.connect();
              }
              // Force route refresh
              if (_currentVehicleLocation != null) {
                await _fetchAndDisplayRoute(
                  _currentVehicleLocation!,
                  _defaultDestination,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: () {
              if (_currentVehicleLocation != null) {
                _fetchAndDisplayRoute(
                  _currentVehicleLocation!,
                  _defaultDestination,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: _isVehicleOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehicle: ${_vehicleId?.substring(0, 8)}...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _isVehicleOnline
                                ? 'Vehicle is online'
                                : 'Vehicle is offline',
                            style: TextStyle(
                              color: _isVehicleOnline
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_currentRoute != null) ...[
                          Text(
                            _currentRoute!.distance,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _currentRoute!.duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ] else if (_currentVehicleLocation != null) ...[
                          Text(
                            _formatDistance(
                              _calculateDistance(
                                _currentVehicleLocation!,
                                _defaultDestination,
                              ),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSocketConnected ? Icons.wifi : Icons.wifi_off,
                          size: 16,
                          color: _isSocketConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isSocketConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isSocketConnected
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (_currentRoute != null)
                      Row(
                        children: [
                          Icon(Icons.route, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Route Active',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialCamera,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
              trafficEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
