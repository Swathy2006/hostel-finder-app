import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class AuthService {
  // return correct backend URL depending on platform
  static String get baseUrl {
    if (kIsWeb) {
      // web build runs in browser so localhost:5000 is fine
      return "http://localhost:5000/api";
    }
    // For physical Android devices, use your machine's IP
    // For Android emulator, use 10.0.2.2:5000
    return "http://172.16.144.176:5000/api";
  }

  /// latest logged-in user id (useful for owner operations)
  static String? currentUserId;

  /// Registers a new user. Throws an [Exception] containing
  /// status code / server message on failure.
  static Future<void> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final url = "$baseUrl/auth/register";
    debugPrint("Registering user at: $url");

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
          .timeout(const Duration(seconds: 30));

      debugPrint("Register response status: ${res.statusCode}");
      debugPrint("Register response body: ${res.body}");

      if (res.statusCode != 200) {
        final msg = 'register failed ${res.statusCode}: ${res.body}';
        debugPrint(msg);
        throw Exception(msg);
      }
    } on Exception catch (e) {
      debugPrint("Register exception: $e");
      rethrow;
    }
  }

  /// Attempts login returning a map with `role` and `id`. Throws on failure.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = "$baseUrl/auth/login";
    debugPrint("Logging in at: $url");

    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint("Login response status: ${res.statusCode}");
      debugPrint("Login response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        currentUserId = data['id'] as String?;
        return {'role': data['role'], 'id': data['id']};
      }

      final msg = 'login failed ${res.statusCode}: ${res.body}';
      debugPrint(msg);
      throw Exception(msg);
    } on Exception catch (e) {
      debugPrint("Login exception: $e");
      rethrow;
    }
  }
}
