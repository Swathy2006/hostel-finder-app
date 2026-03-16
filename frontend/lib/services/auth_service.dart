import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class AuthService {
  static const String deviceIp = "10.113.191.186";

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }
    return "http://$deviceIp:5000/api";
  }

  static String? currentUserId;

  /* ================= CHECK ADMIN EXISTS ================= */
  static Future<bool> checkAdminExists() async {
    final url = "$baseUrl/auth/admin-exists";
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['hasAdmin'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("ADMIN EXISTS CHECK ERROR: $e");
      return false;
    }
  }

  /* ================= REGISTER ================= */

  static Future<void> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final url = "$baseUrl/auth/register";

    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name,
              "email": email,
              "password": password,
              "role": role,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw Exception("Register failed: ${res.body}");
      }
    } catch (e) {
      debugPrint("REGISTER ERROR: $e");
      throw Exception(e.toString());
    }
  }

  /* ================= LOGIN ================= */

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = "$baseUrl/auth/login";

    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        currentUserId = data["id"];

        return {
          "role": data["role"],
          "id": data["id"],
        };
      }

      throw Exception("Login failed");
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      throw Exception(e.toString());
    }
  }

  /* ================= GET USER PROFILE ================= */

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final url = "$baseUrl/auth/me/$userId";

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint("GET PROFILE ERROR: $e");
      return null;
    }
  }

  /* ================= UPDATE USER PROFILE ================= */

  static Future<bool> updateUserProfile(
      String userId, String name, String email, String phone) async {
    final url = "$baseUrl/auth/update-profile/$userId";

    try {
      final res = await http
          .put(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"name": name, "email": email, "phone": phone}),
          )
          .timeout(const Duration(seconds: 20));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("UPDATE PROFILE ERROR: $e");
      return false;
    }
  }

  /* ================= CHANGE PASSWORD ================= */

  static Future<String?> changePassword(
      String userId, String currentPassword, String newPassword) async {
    final url = "$baseUrl/auth/change-password/$userId";

    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "currentPassword": currentPassword,
              "newPassword": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        return null; // Success (no error string)
      } else {
        final body = jsonDecode(res.body);
        return body["message"] ?? "Failed to change password";
      }
    } catch (e) {
      debugPrint("CHANGE PASSWORD ERROR: $e");
      return "An unexpected error occurred.";
    }
  }
}
