import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../constants/app_constants.dart';
import '../../../../../core/services/data_service.dart';
import '../../../../../core/services/directions_service.dart';
import '../../../../../core/models/student.dart';
import '../../../../models/route_info.dart';

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
  bool _isInitialLoad = true;

  LatLng? _currentVehicleLocation;
  RouteInfo? _currentRoute;
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Animation fields
  List<LatLng> _routePoints = [];
  int _animationIndex = 0;
  Timer? _animationTimer;
  double _vehicleRotation = 0.0;
  Duration _animationStepDuration = const Duration(milliseconds: 300);

  static const LatLng _defaultDestination = LatLng(30.5789, 76.8372);

  CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(30.5789, 76.8372),
    zoom: 12,
  );

  static String get SERVER_URL => AppConstants.socketUrl;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _socket?.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initTracking() async {
    setState(() => _isInitialLoad = true);

    await _fetchVehicleId();
    if (_vehicleId != null) {
      _setupDestinationMarker();
      _connectSocketAndListen();
      await _fetchLastKnownLocation();
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

        await _updateVehicleLocationWithRoute(lastLocation);
        setState(() => _isVehicleOnline = false);
      }
    } catch (_) {}
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

    setState(() => _markers.add(destinationMarker));
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
      setState(() => _isSocketConnected = true);
      _socket!.emit('join_room', 'vehicle_$_vehicleId');
    });

    _socket!.on('location_update', (data) {
      try {
        final double lat = (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] as num).toDouble();
        final vehicleLocation = LatLng(lat, lng);
        _updateVehicleLocationWithRoute(vehicleLocation);
        if (!_isVehicleOnline) setState(() => _isVehicleOnline = true);
      } catch (_) {}
    });

    _socket!.onDisconnect((_) {
      setState(() {
        _isSocketConnected = false;
        _isVehicleOnline = false;
      });
    });

    _socket!.connect();
  }

  Future<void> _updateVehicleLocationWithRoute(LatLng vehicleLocation) async {
    _currentVehicleLocation = vehicleLocation;
    _updateVehicleMarker(vehicleLocation);

    // Fetch new route and start animation
    await _fetchAndAnimateRoute(vehicleLocation, _defaultDestination);

    _mapController?.animateCamera(CameraUpdate.newLatLng(vehicleLocation));
  }

  void _updateVehicleMarker(LatLng location) {
    final vehicleMarker = Marker(
      markerId: MarkerId('vehicle_$_vehicleId'),
      position: location,
      rotation: _vehicleRotation,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value.startsWith('vehicle_'));
      _markers.add(vehicleMarker);
    });
  }

  Future<void> _fetchAndAnimateRoute(LatLng origin, LatLng destination) async {
    try {
      setState(() => _isLoadingRoute = true);
      final route = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.driving,
      );

      if (route != null) {
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: route.polylinePoints,
          color: Colors.blue,
          width: 5,
        );

        setState(() {
          _polylines.clear();
          _polylines.add(polyline);
          _routePoints = route.polylinePoints;
          _animationIndex = 0;
        });

        _startMarkerAnimation();
      }
    } catch (_) {}
    setState(() => _isLoadingRoute = false);
  }

  void _startMarkerAnimation() {
    _animationTimer?.cancel();
    if (_routePoints.isEmpty) return;

    _animationTimer = Timer.periodic(_animationStepDuration, (timer) {
      if (_animationIndex >= _routePoints.length) {
        timer.cancel();
        return;
      }

      final newLoc = _routePoints[_animationIndex];

      if (_animationIndex > 0) {
        _vehicleRotation = _getBearing(
          _routePoints[_animationIndex - 1],
          newLoc,
        );
      }

      _updateVehicleMarker(newLoc);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLoc));

      _animationIndex++;
    });
  }

  double _getBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180);
    final lng1 = start.longitude * (math.pi / 180);
    final lat2 = end.latitude * (math.pi / 180);
    final lng2 = end.longitude * (math.pi / 180);

    final dLon = lng2 - lng1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * (180 / math.pi);
    return (brng + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Track Vehicle')),
      body: GoogleMap(
        initialCameraPosition: _initialCamera,
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}
