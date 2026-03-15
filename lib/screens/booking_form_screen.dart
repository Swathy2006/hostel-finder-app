import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic> hostel;

  const BookingFormScreen({super.key, required this.hostel});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final aadhaarCtrl = TextEditingController();
  final durationValueCtrl = TextEditingController();

  String selectedDurationUnit = "Months";

  bool loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    aadhaarCtrl.dispose();
    durationValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    print("BOOKING BUTTON PRESSED");

    if (!_formKey.currentState!.validate()) {
      print("FORM VALIDATION FAILED");
      return;
    }

    final userId = AuthService.currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    final hostelId = widget.hostel['_id'] ?? widget.hostel['id'];
    final ownerId = widget.hostel['owner'];
    final hostelName = widget.hostel['name'];

    if (hostelId == null || ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hostel information missing")),
      );
      return;
    }

    setState(() => loading = true);

    final bookingData = {
      "userId": userId,
      "hostelId": hostelId,
      "hostelName": hostelName,
      "ownerId": ownerId,
      "name": nameCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "aadhaar": aadhaarCtrl.text.trim(),
      "duration": "${durationValueCtrl.text.trim()} $selectedDurationUnit",
      "status": "pending"
    };

    print("BOOKING DATA:");
    print(bookingData);

    final error = await BookingService.submitBooking(bookingData);

    setState(() => loading = false);

    if (error == null) {
      print("BOOKING SUCCESS");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Booking application submitted successfully")),
        );
        Navigator.pop(context);
      }
    } else {
      print("BOOKING FAILED: $error");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isNumber = false,
    bool isEmail = false,
    bool isPhone = false,
    bool isAadhaar = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber || isPhone || isAadhaar
          ? TextInputType.number
          : TextInputType.text,
      maxLength: isAadhaar ? 12 : (isPhone ? 10 : null),
      inputFormatters: isNumber || isPhone || isAadhaar
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Required field";
        }

        if (isEmail && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return "Invalid email";
        }

        if (isPhone && value.length != 10) {
          return "Phone must be 10 digits";
        }

        if (isAadhaar && value.length != 12) {
          return "Aadhaar must be 12 digits";
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Book ${widget.hostel['name']}"),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField("Full Name", Icons.person, nameCtrl),
              const SizedBox(height: 16),
              _buildField("Email", Icons.email, emailCtrl, isEmail: true),
              const SizedBox(height: 16),
              _buildField("Phone", Icons.phone, phoneCtrl, isPhone: true),
              const SizedBox(height: 16),
              _buildField("Aadhaar", Icons.badge, aadhaarCtrl, isAadhaar: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                        "Duration", Icons.timer, durationValueCtrl,
                        isNumber: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedDurationUnit,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ["Days", "Weeks", "Months"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => selectedDurationUnit = v!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit Application",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
