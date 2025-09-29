// lib/screens/admin/driver_details_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/core/constants/app_constants.dart'; // Import your constants

class DriverDetailsScreen extends StatefulWidget {
  final String driverUserId; // The user_id of the driver

  const DriverDetailsScreen({super.key, required this.driverUserId});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  Future<Map<String, dynamic>>? _driverDetailsFuture;

  @override
  void initState() {
    super.initState();
    _driverDetailsFuture = _fetchDriverDetails(widget.driverUserId);
  }

  Future<Map<String, dynamic>> _fetchDriverDetails(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/drivers/$driverId',
        ), // Backend route: GET /api/drivers/:driverId
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Driver not found');
      } else {
        throw Exception(
          'Failed to load driver details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  Widget _buildDetailRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Details'),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _driverDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No details available.'));
          } else {
            final driver = snapshot.data!;
            final bool isOnline = driver['has_location'] == 1;
            final String locationStatus = isOnline ? 'ONLINE' : 'OFFLINE';
            final Color statusColor = isOnline ? Colors.green : Colors.red;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Status Card ---
                  Card(
                    color: statusColor.withOpacity(0.1),
                    child: ListTile(
                      leading: Icon(
                        Icons.drive_eta,
                        color: statusColor,
                        size: 30,
                      ),
                      title: Text(
                        'Status: $locationStatus',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      subtitle: Text(
                        'Last Updated: ${driver['last_update'] ?? 'N/A'}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Driver Details ---
                  const Text(
                    'Driver Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildDetailRow('Email:', driver['email']),
                  _buildDetailRow('User ID:', driver['user_id']),

                  const SizedBox(height: 20),

                  // --- Vehicle Details ---
                  const Text(
                    'Vehicle Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildDetailRow('Vehicle ID:', driver['vehicle_id'] ?? 'N/A'),
                  _buildDetailRow(
                    'Registration No.:',
                    driver['vehicle_number'] ?? 'Not Assigned',
                    Colors.indigo,
                  ),
                  _buildDetailRow('Type:', driver['vehicle_type'] ?? 'N/A'),
                  _buildDetailRow(
                    'Capacity:',
                    '${driver['capacity'] ?? 'N/A'} seats',
                  ),
                  _buildDetailRow(
                    'Vehicle Status:',
                    driver['vehicle_status'] ?? 'N/A',
                  ),

                  const SizedBox(height: 20),

                  // --- Live Location ---
                  const Text(
                    'Live Location Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Latitude:',
                    driver['latitude']?.toString() ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Longitude:',
                    driver['longitude']?.toString() ?? 'N/A',
                  ),

                  const SizedBox(height: 40),

                  // Simple button for future actions (e.g., View on Map)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: isOnline
                          ? () {
                              // TODO: Implement map view navigation here
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Implement Map View'),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.map),
                      label: const Text('View Live Location on Map'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
