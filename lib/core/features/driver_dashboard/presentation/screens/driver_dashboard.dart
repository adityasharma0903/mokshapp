import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:my_app/core/services/data_service.dart';

class DriverDashboard extends StatefulWidget {
  final String userId;
  const DriverDashboard({super.key, required this.userId});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isSharing = false;
  final DataService _dataService = DataService();
  StreamSubscription<Position>? _locationSubscription;
  String? _vehicleId;
  IO.Socket? _socket;
  bool _isSocketConnected = false;

  static const String serverUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _fetchVehicleId();
    _initSocket();
  }

  @override
  void dispose() {
    _stopLocationSharing();
    _socket?.disconnect();
    super.dispose();
  }

  void _initSocket() {
    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('Driver socket connected: ${_socket!.id}');
      if (mounted) {
        setState(() {
          _isSocketConnected = true;
        });
      }
    });

    _socket!.onDisconnect((_) {
      print('Driver socket disconnected');
      if (mounted) {
        setState(() {
          _isSocketConnected = false;
        });
      }
    });

    _socket!.connect();
  }

  Future<void> _fetchVehicleId() async {
    try {
      final response = await _dataService.get(
        'vehicles/by-driver/${widget.userId}',
      );
      if (mounted && response is Map && response['vehicle_id'] != null) {
        setState(() {
          _vehicleId = response['vehicle_id'].toString();
        });
        print('Fetched vehicle ID: $_vehicleId');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle not found for this driver')),
          );
        }
      }
    } catch (e) {
      print('Error fetching vehicle ID: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch vehicle id: $e')),
        );
      }
    }
  }

  void _toggleSharing() {
    setState(() {
      _isSharing = !_isSharing;
    });

    if (_isSharing) {
      _startLocationSharing();
    } else {
      _stopLocationSharing();
    }
  }

  Future<void> _startLocationSharing() async {
    if (_vehicleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No vehicle assigned to this driver yet'),
          ),
        );
      }
      setState(() => _isSharing = false);
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
      }
      setState(() => _isSharing = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission not granted')),
        );
      }
      setState(() => _isSharing = false);
      return;
    }

    if (!_isSocketConnected) {
      _socket?.connect();
      // Wait for connection
      int attempts = 0;
      while (!_isSocketConnected && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (!_isSocketConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to server')),
          );
        }
        setState(() => _isSharing = false);
        return;
      }
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
      timeLimit: Duration(hours: 8),
    );

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            final payload = {
              'vehicle_id': _vehicleId,
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': DateTime.now().toIso8601String(),
            };

            print(
              'Sending location update: ${position.latitude}, ${position.longitude}',
            );

            try {
              await _dataService.post('vehicles/location', payload);
              print('Successfully sent location to API');
            } catch (e) {
              print('Failed to send HTTP location: $e');
            }

            if (_isSocketConnected && _socket != null) {
              _socket!.emit('driver_location_update', payload);
              print('Emitted location via socket');
            }
          },
          onError: (err) {
            print('Position stream error: $err');
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Location error: $err')));
            }
          },
          cancelOnError: false,
        );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Started sharing location')));
    }
  }

  void _stopLocationSharing() {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    if (_isSocketConnected && _vehicleId != null) {
      _socket!.emit('driver_stop_sharing', {'vehicle_id': _vehicleId});
    }

    setState(() => _isSharing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stopped sharing location')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Panel'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSharing ? Icons.location_on : Icons.location_off,
                size: 80,
                color: _isSharing ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                _isSharing ? 'Sharing Location...' : 'Location Sharing Off',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (_vehicleId != null)
                Text(
                  'Vehicle ID: $_vehicleId',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _toggleSharing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSharing ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(_isSharing ? 'Stop Sharing' : 'Start Sharing'),
              ),
              const SizedBox(height: 20),
              if (_isSocketConnected)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Connected to server',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Disconnected from server',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
