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
  /// Creates a hostel. Throws an exception with details if creation fails.
  static Future<bool> createHostel(
    String name,
    String address,
    double rentSingle,
    double rentShared,
    int vacancy,
    String ownerId,
    double lat,
    double lng,
    List<String> images,
    List<String> videos,
  ) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/hostels/create"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": name,
            "address": address,
            "rentSingle": rentSingle,
            "rentShared": rentShared,
            "vacancy": vacancy,
            "ownerId": ownerId,
            "lat": lat,
            "lng": lng,
            "facilities": [],
            "images": images,
            "videos": videos,
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
