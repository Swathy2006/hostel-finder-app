import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BookingService {
  static const String deviceIp = "10.113.191.186";

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }
    return "http://$deviceIp:5000/api";
  }

  // Submit a booking application
  static Future<String?> submitBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/bookings/submit"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(bookingData),
      );
      
      if (response.statusCode == 201) {
        return null; // Success
      } else {
        // Log the exact status and body for debugging
        debugPrint("SUBMIT BOOKING FAILED: ${response.statusCode}");
        debugPrint("RESPONSE BODY: ${response.body}");

        if (response.headers['content-type']?.contains('application/json') ?? false) {
          final body = jsonDecode(response.body);
          return body['message'] ?? "Server error (${response.statusCode})";
        } else {
          // If not JSON, return a snippet of the HTML/Text
          String snippet = response.body.length > 100 
              ? response.body.substring(0, 100) + "..." 
              : response.body;
          return "Server error ${response.statusCode}: $snippet";
        }
      }
    } catch (e) {
      debugPrint("SUBMIT BOOKING ERROR: $e");
      return "Connection error: ${e.toString()}";
    }
  }

  // Fetch all bookings for Admin
  static Future<List<dynamic>> getAllBookings() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/bookings/admin/all"),
        headers: {"Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("GET ALL BOOKINGS ERROR: $e");
      return [];
    }
  }

  // Update booking status (Admin)
  static Future<bool> updateBookingStatus(String bookingId, String status, {int? waitlistRank}) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/bookings/admin/$bookingId/status"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "status": status,
          if (waitlistRank != null) "waitlistRank": waitlistRank,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("UPDATE STATUS ERROR: $e");
      return false;
    }
  }

  // Fetch bookings for a User
  static Future<List<dynamic>> getUserBookings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/bookings/user/$userId"),
        headers: {"Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("GET USER BOOKINGS ERROR: $e");
      return [];
    }
  }

  // Fetch bookings for an Owner (Approved ones)
  static Future<List<dynamic>> getOwnerBookings(String ownerId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/bookings/owner/$ownerId"),
        headers: {"Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("GET OWNER BOOKINGS ERROR: $e");
      return [];
    }
  }

  // Set appointment (Owner)
  static Future<bool> setAppointment(String bookingId, String date, String time) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/bookings/owner/$bookingId/appointment"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"date": date, "time": time}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("SET APPOINTMENT ERROR: $e");
      return false;
    }
  }
}
