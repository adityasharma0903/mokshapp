// lib/core/services/data_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kDebugMode

class DataService {
  // Use a different base URL for the web, mobile emulator, or a physical device
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; // Android Emulator
  // static const String _baseUrl = 'http://localhost:3000/api'; // iOS Simulator
  // static const String _baseUrl = 'http://192.168.x.x:3000/api'; // Physical device

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // --- GET Request ---
  Future<List<dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print(
            'GET request failed for $endpoint with status: ${response.statusCode}',
          );
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network error for GET $endpoint: $e');
      }
      return [];
    }
  }

  // --- POST Request ---
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print(
            'POST request failed for $endpoint with status: ${response.statusCode}',
          );
        }
        return {'error': 'Failed to post data', 'status': response.statusCode};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network error for POST $endpoint: $e');
      }
      return {'error': 'Network error occurred'};
    }
  }

  // --- PUT Request ---
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print(
            'PUT request failed for $endpoint with status: ${response.statusCode}',
          );
        }
        return {
          'error': 'Failed to update data',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network error for PUT $endpoint: $e');
      }
      return {'error': 'Network error occurred'};
    }
  }

  // --- DELETE Request ---
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print(
            'DELETE request failed for $endpoint with status: ${response.statusCode}',
          );
        }
        return {
          'error': 'Failed to delete data',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network error for DELETE $endpoint: $e');
      }
      return {'error': 'Network error occurred'};
    }
  }
}
