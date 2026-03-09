import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

class HostelService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }
    if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api";
    }
    // fall back to localhost for iOS or desktop
    return "http://localhost:5000/api";
  }

  /* ================= CREATE HOSTEL ================= */
  static Future<bool> createHostel(
    String name,
    String address,
    String ownerName,
    String contactNo,
    double rentSingle,
    double rentShared,
    int vacancy,
    String ownerId,
    double lat,
    double lng,
    List<String> facilities,
    List<String> images,
    List<String> videos, {
    int totalRooms = 0,
    int totalCapacity = 0,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/hostels/create"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name,
              "address": address,
              "ownerName": ownerName,
              "contactNo": contactNo,
              "rentSingle": rentSingle,
              "rentShared": rentShared,
              "vacancy": vacancy,
              "ownerId": ownerId,
              "lat": lat,
              "lng": lng,
              "facilities": facilities,
              "images": images,
              "videos": videos,
              "totalRooms": totalRooms,
              "totalCapacity": totalCapacity,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        final msg =
            'create hostel failed ${response.statusCode}: ${response.body}';
        debugPrint(msg);
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint("CREATE HOSTEL EXCEPTION: $e");
      throw Exception("Failed to send request: $e");
    }
  }

  /* ================= GET ALL HOSTELS ================= */
  static Future<List<dynamic>> getAllHostels() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/hostels"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("GET HOSTELS ERROR: $e");
      return [];
    }
  }

  /* ================= GET HOSTELS BY OWNER ================= */
  static Future<List<dynamic>> getHostelsByOwner(String ownerId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/hostels/owner/$ownerId"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load hostels');
      }
    } catch (e) {
      debugPrint('GET HOSTELS BY OWNER ERROR: $e');
      return [];
    }
  }

  /* ================= GET NEARBY HOSTELS ================= */
  static Future<List<dynamic>> getNearbyHostels(double lat, double lng) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/hostels/nearby?lat=$lat&lng=$lng"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('fetch nearby hostels failed ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint("FETCH NEARBY HOSTELS EXCEPTION: $e");
      return [];
    }
  }

  /* ================= UPDATE HOSTEL ================= */
  static Future<bool> updateHostel(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final response = await http
        .put(
          Uri.parse("$baseUrl/hostels/$id"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(changes),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return true;
    } else {
      final msg =
          'update hostel failed ${response.statusCode}: ${response.body}';
      debugPrint(msg);
      throw Exception(msg);
    }
  }
}
