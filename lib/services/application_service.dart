import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class ApplicationService {
  static const String deviceIp = "10.113.191.186";

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }
    return "http://$deviceIp:5000/api";
  }

  /* ================= SUBMIT APPLICATION ================= */
  static Future<String?> submitApplication({
    required String userId,
    required String hostelName,
    required String ownerName,
    required String email,
    required String phone,
    required String district,
    required String city,
  }) async {
    final url = "$baseUrl/applications/submit";
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
          "hostelName": hostelName,
          "ownerName": ownerName,
          "email": email,
          "phone": phone,
          "district": district,
          "city": city,
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 201) {
        return null; // Success
      } else {
        debugPrint("SUBMIT APP FAILED: ${res.statusCode}");
        debugPrint("RESPONSE BODY: ${res.body}");

        if (res.headers['content-type']?.contains('application/json') ?? false) {
          final body = jsonDecode(res.body);
          return body['message'] ?? "Server error (${res.statusCode})";
        } else {
          String snippet = res.body.length > 100 
              ? res.body.substring(0, 100) + "..." 
              : res.body;
          return "Server error ${res.statusCode}: $snippet";
        }
      }
    } catch (e) {
      debugPrint("SUBMIT APP ERROR: $e");
      return "Connection error: ${e.toString()}";
    }
  }

  /* ================= GET ALL APPLICATIONS (ADMIN) ================= */
  static Future<List<dynamic>> getAllApplications() async {
    final url = "$baseUrl/applications/all";
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      debugPrint("GET ALL APPS ERROR: $e");
      return [];
    }
  }

  /* ================= GET USER APPLICATIONS (NOTIFICATIONS) ================= */
  static Future<List<dynamic>> getUserApplications(String userId) async {
    final url = "$baseUrl/applications/user/$userId";
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      debugPrint("GET USER APPS ERROR: $e");
      return [];
    }
  }

  /* ================= UPDATE APPLICATION STATUS (ADMIN) ================= */
  static Future<bool> updateApplicationStatus(String id, String status, String adminMessage) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/applications/$id/status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "status": status,
          "adminMessage": adminMessage,
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("UPDATE APPLICATION STATUS ERROR: $e");
      return false;
    }
  }

  static Future<bool> deleteApplication(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/applications/$id"),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("DELETE APPLICATION ERROR: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getLinkedDraft(String appId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/applications/hostel-draft/$appId"),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("GET LINKED DRAFT ERROR: $e");
      return null;
    }
  }
}
