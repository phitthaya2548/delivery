import 'dart:convert';
import 'dart:developer';

import 'package:deliveryrpoject/config/config.dart';
import 'package:http/http.dart' as http;

class RiderLocationService {
  String? apiUrl; // URL will be loaded asynchronously

  RiderLocationService();

  // Initialize the service and fetch configuration
  Future<void> initialize() async {
    try {
      final config = await Configuration.getConfig();
      apiUrl = config['apiEndpoint'];
      if (apiUrl == null || apiUrl!.isEmpty) {
        log("API URL is missing or empty.");
      }
    } catch (e) {
      log("Error initializing RiderLocationService: $e");
    }
  }

  Future<bool> saveLocation({
    required int riderId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    // Ensure the API URL is loaded before using it
    if (apiUrl == null) {
      log("API URL not initialized");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl! + '/riders/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rider_id': riderId,
          'gps_lat': latitude,
          'gps_lng': longitude,
        }),
      );
      log("Response status: ${response.statusCode}");
      log("Response body: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      log("Error saving location: $e");
      return false;
    }
  }
}
