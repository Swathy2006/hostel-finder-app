import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import 'package:intl/intl.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  bool loading = true;
  List<dynamic> myBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchMyBookings();
  }

  Future<void> _fetchMyBookings() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    setState(() => loading = true);
    final data = await BookingService.getUserBookings(userId);
    if (mounted) {
      setState(() {
        myBookings = data;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(onPressed: _fetchMyBookings, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : myBookings.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.hotel_class_outlined, color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text("No bookings yet.", style: TextStyle(color: Colors.white54, fontSize: 16)),
                  Text("Apply to hostels to see your bookings here.", style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myBookings.length,
              itemBuilder: (context, index) {
                final b = myBookings[index];
                return _buildBookingCard(b);
              },
            ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final status = b['status'] ?? 'pending';
    bool hasAppt = (b['appointmentDate'] ?? '').isNotEmpty;

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF334155))),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['hostelName'] ?? 'Hostel Name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        b['createdAt'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(b['createdAt'])) : '',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _statusBadge(status, b['waitlistRank']),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            
            if (status == 'rejected')
               const Text("Your application was not approved by the admin. Try another hostel.", style: TextStyle(color: Colors.redAccent, fontSize: 13, height: 1.4))
            else if (status == 'waitlisted')
               Text("You are on the waiting list at rank #${b['waitlistRank']}. We'll notify you if a spot opens up.", style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, height: 1.4))
            else if (status == 'approved' && !hasAppt)
               const Text("Admin approved! Waiting for the owner to schedule your appointment...", style: TextStyle(color: Colors.greenAccent, fontSize: 13, height: 1.4))
            else if (status == 'approved' && hasAppt)
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text("APPOINTMENT SCHEDULED", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3))),
                     child: Row(
                       children: [
                         const Icon(Icons.event_available_rounded, color: Color(0xFF6366F1), size: 32),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text("${b['appointmentDate']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                               Text("at ${b['appointmentTime']}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 8),
                   const Text("Please be on time for your appointment.", style: TextStyle(color: Colors.white38, fontSize: 11)),
                 ],
               )
            else
               const Text("Your application is under review by the admin.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),

            const SizedBox(height: 20),
            _infoChip(Icons.timer_outlined, "Duration: ${b['duration']}"),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, dynamic rank) {
    Color color = Colors.grey;
    String label = status.toUpperCase();
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;
    if (status == 'waitlisted') {
      color = Colors.orange;
      label = "WAITLIST #$rank";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
