// lib/screens/admin/drivers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/core/constants/app_constants.dart'; // Import your constants
import 'driver_details_screen.dart'; // Import the details screen

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen> {
  Future<List<dynamic>>? _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = _fetchDrivers();
  }

  Future<List<dynamic>> _fetchDrivers() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/drivers/all',
        ), // Backend route: GET /api/drivers/all
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // The API returns a list of driver objects
        return json.decode(response.body);
      } else {
        // Handle server errors
        throw Exception('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or parsing errors
      throw Exception('Network Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drivers & Vehicle Status 🚌'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _driversFuture = _fetchDrivers(); // Refresh the list
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _driversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No drivers found.'));
          } else {
            final drivers = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                final bool isOnline = driver['has_location'] == 1;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOnline ? Colors.green : Colors.red,
                      child: Icon(
                        isOnline ? Icons.location_on : Icons.location_off,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(driver['email']),
                    subtitle: Text(
                      'Vehicle: ${driver['vehicle_number']} (${driver['vehicle_type']})',
                    ),
                    trailing: isOnline
                        ? const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    onTap: () {
                      // Navigate to the details screen, passing the driver's User ID
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverDetailsScreen(
                            driverUserId: driver['user_id'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
