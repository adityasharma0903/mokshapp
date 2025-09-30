// lib/core/services/data_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class DataService {
  static final String _baseUrl = AppConstants.baseUrl;

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // --- GET ---
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('❌ GET $endpoint failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Network error GET $endpoint: $e');
      return null;
    }
  }

  // --- POST ---
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
          print('❌ POST $endpoint failed: ${response.statusCode}');
        }
        return {'error': 'Failed to post', 'status': response.statusCode};
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Network error POST $endpoint: $e');
      return {'error': 'Network error'};
    }
  }

  // --- PUT ---
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
          print('❌ PUT $endpoint failed: ${response.statusCode}');
        }
        return {'error': 'Failed to update', 'status': response.statusCode};
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Network error PUT $endpoint: $e');
      return {'error': 'Network error'};
    }
  }

  // --- DELETE ---
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
          print('❌ DELETE $endpoint failed: ${response.statusCode}');
        }
        return {'error': 'Failed to delete', 'status': response.statusCode};
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Network error DELETE $endpoint: $e');
      return {'error': 'Network error'};
    }
  }
}
