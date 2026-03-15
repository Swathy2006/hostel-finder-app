import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import 'package:intl/intl.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  bool loading = true;
  List<dynamic> approvedBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final ownerId = AuthService.currentUserId;
    if (ownerId == null) return;
    
    setState(() => loading = true);
    final data = await BookingService.getOwnerBookings(ownerId);
    if (mounted) {
      setState(() {
        approvedBookings = data;
        loading = false;
      });
    }
  }

  Future<void> _pickDateTime(String bookingId) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
         final dateStr = DateFormat('EEE, MMM d, yyyy').format(pickedDate);
         final timeStr = pickedTime.format(context);
         
         final success = await BookingService.setAppointment(bookingId, dateStr, timeStr);
         if (success) {
           _fetchBookings();
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment scheduled successfully!")));
           }
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Booking Appointments", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : approvedBookings.isEmpty
          ? const Center(child: Text("No approved bookings for your hostels.", style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: approvedBookings.length,
              itemBuilder: (context, index) {
                final b = approvedBookings[index];
                return _buildBookingCard(b);
              },
            ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    bool hasAppt = (b['appointmentDate'] ?? '').isNotEmpty;

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(b['name'] ?? 'Applicant', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("APPROVED", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("Hostel: ${b['hostelName']}", style: const TextStyle(color: Colors.blueAccent, fontSize: 13)),
            const Divider(color: Colors.white10, height: 24),
            _infoRow(Icons.phone, b['phone']),
            _infoRow(Icons.timer, "Duration: ${b['duration']}"),
            const SizedBox(height: 16),
            
            if (hasAppt)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2))),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF6366F1), size: 18),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Appointment Scheduled", style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text("${b['appointmentDate']} at ${b['appointmentTime']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    TextButton(onPressed: () => _pickDateTime(b['_id']), child: const Text("Reschedule", style: TextStyle(fontSize: 12))),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickDateTime(b['_id']),
                  icon: const Icon(Icons.schedule_send_rounded),
                  label: const Text("Set Appointment Time"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String? text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text(text ?? 'N/A', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
