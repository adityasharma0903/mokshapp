import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_app/core/services/data_service.dart';
import 'package:my_app/core/models/student.dart';
import 'track_vehicle_screen.dart';

class TrackVehicleDashboard extends StatefulWidget {
  final Student student;

  const TrackVehicleDashboard({super.key, required this.student});

  @override
  State<TrackVehicleDashboard> createState() => _TrackVehicleDashboardState();
}

class _TrackVehicleDashboardState extends State<TrackVehicleDashboard> {
  final DataService _dataService = DataService();
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
    // Auto-refresh every 30 seconds to get updated driver status
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchDrivers();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDrivers() async {
    try {
      final response = await _dataService.get('drivers/all');
      if (mounted) {
        setState(() {
          if (response is List) {
            _drivers = List<Map<String, dynamic>>.from(response);
          } else if (response is Map && response['drivers'] != null) {
            _drivers = List<Map<String, dynamic>>.from(response['drivers']);
          } else {
            _drivers = [];
          }
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load drivers: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshDrivers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _fetchDrivers();
  }

  void _trackDriver(Map<String, dynamic> driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackVehicleScreen(
          student: widget.student,
          vehicleIdFromParent: driver['vehicle_id']?.toString(),
        ),
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final driverEmail = driver['email']?.toString() ?? 'Unknown';
    final vehicleNumber = driver['vehicle_number']?.toString() ?? 'N/A';
    final vehicleId = driver['vehicle_id']?.toString() ?? '';
    final hasLocation = driver['has_location'] == true;
    final lastUpdate = driver['last_update']?.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: vehicleId.isNotEmpty ? () => _trackDriver(driver) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasLocation ? Colors.green[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasLocation ? Icons.location_on : Icons.location_off,
                      color: hasLocation ? Colors.green[700] : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverEmail,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vehicle: $vehicleNumber',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasLocation ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasLocation ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (lastUpdate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last update: $lastUpdate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
              if (vehicleId.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.touch_app, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to track this vehicle',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Dashboard'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDrivers,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Drivers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a driver to track their vehicle location',
                  style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading drivers...'),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshDrivers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _drivers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No drivers found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later or contact administration',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshDrivers,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _drivers.length,
                      itemBuilder: (context, index) {
                        return _buildDriverCard(_drivers[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshDrivers,
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
