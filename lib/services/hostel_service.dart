import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class HostelService {
  static const String deviceIp = "10.113.191.186";

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }
    return "http://$deviceIp:5000/api";
  }

  /* ================= CREATE HOSTEL ================= */

  static Future<String?> createHostel(
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
    required String district,
    required String city,
    String gender = "Mixed",
    int totalRooms = 0,
    int totalMembers = 0,
    int vacantRooms = 0,
    List<Map<String, dynamic>> rooms = const [],
    String? applicationId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/hostels/create"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
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
              "district": district,
              "city": city,
              "gender": gender,
              "totalRooms": totalRooms,
              "totalMembers": totalMembers,
              "vacantRooms": vacantRooms,
              "rooms": rooms,
              if (applicationId != null) "applicationId": applicationId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success
      } else {
        debugPrint("CREATE HOSTEL FAILED: ${response.statusCode}");
        debugPrint("RESPONSE BODY: ${response.body}");

        if (response.headers['content-type']?.contains('application/json') ?? false) {
          final body = jsonDecode(response.body);
          return body['message'] ?? "Server error (${response.statusCode})";
        } else {
          String snippet = response.body.length > 100 
              ? response.body.substring(0, 100) + "..." 
              : response.body;
          return "Server error ${response.statusCode}: $snippet";
        }
      }
    } catch (e) {
      debugPrint("CREATE HOSTEL ERROR: $e");
      return "Connection error: ${e.toString()}";
    }
  }

  /* ================= GET ALL HOSTELS ================= */

  static Future<List<dynamic>> getAllHostels() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/hostels"))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint("GET HOSTELS ERROR: $e");
      return [];
    }
  }

  /* ================= GET HOSTELS BY OWNER ================= */

  static Future<List<dynamic>> getHostelsByOwner(String ownerId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/hostels/owner/$ownerId"))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint("GET OWNER HOSTELS ERROR: $e");
      return [];
    }
  }

  /* ================= GET NEARBY HOSTELS ================= */

  static Future<List<dynamic>> getNearbyHostels(double lat, double lng,
      {int radius = 50000}) async {
    try {
      final response = await http
          .get(Uri.parse(
              "$baseUrl/hostels/nearby?lat=$lat&lng=$lng&maxDistance=$radius"))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint("NEARBY HOSTELS ERROR: $e");
      return [];
    }
  }

  /* ================= UPDATE HOSTEL ================= */

  static Future<bool> updateHostel(
    String id,
    Map<String, dynamic> changes,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse("$baseUrl/hostels/$id"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(changes),
          )
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("UPDATE HOSTEL ERROR: $e");
      return false;
    }
  }

  /* ================= GET PUBLISH REQUESTS (ADMIN) ================= */

  static Future<List<dynamic>> getPublishRequests() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/hostels/publish-requests"))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("GET PUBLISH REQUESTS ERROR: $e");
      return [];
    }
  }

  /* ================= APPROVE PUBLISH REQUEST (ADMIN) ================= */

  static Future<bool> approvePublishRequest(String id) async {
    try {
      final response = await http
          .put(Uri.parse("$baseUrl/hostels/approve/$id"))
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("APPROVE HOSTEL ERROR: $e");
      return false;
    }
  }

  static Future<bool> rejectPublishRequest(String id, String message) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/hostels/reject/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"adminMessage": message}),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("REJECT PUBLISH ERROR: $e");
      return false;
    }
  }

  /* ================= SUBMIT EDIT REQUEST (OWNER) ================= */

  static Future<bool> submitEditRequest(
    String id,
    Map<String, dynamic> changes,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse("$baseUrl/hostels/submit-change/$id"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(changes),
          )
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("SUBMIT EDIT ERROR: $e");
      return false;
    }
  }

  /* ================= GET EDIT REQUESTS (ADMIN) ================= */

  static Future<List<dynamic>> getEditRequests() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/hostels/edit-requests"))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("GET EDIT REQUESTS ERROR: $e");
      return [];
    }
  }

  /* ================= APPROVE EDIT REQUEST (ADMIN) ================= */

  static Future<bool> approveEditRequest(String id) async {
    try {
      final response = await http
          .put(Uri.parse("$baseUrl/hostels/approve-edit/$id"))
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("APPROVE EDIT ERROR: $e");
      return false;
    }
  }

  /* ================= REJECT EDIT REQUEST (ADMIN) ================= */

  static Future<bool> rejectEditRequest(String id) async {
    try {
      final response = await http
          .put(Uri.parse("$baseUrl/hostels/reject-edit/$id"))
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("REJECT EDIT ERROR: $e");
      return false;
    }
  }
}
