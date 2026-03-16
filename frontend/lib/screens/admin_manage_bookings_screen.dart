import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import 'package:intl/intl.dart';

class AdminManageBookingsScreen extends StatefulWidget {
  const AdminManageBookingsScreen({super.key});

  @override
  State<AdminManageBookingsScreen> createState() => _AdminManageBookingsScreenState();
}

class _AdminManageBookingsScreenState extends State<AdminManageBookingsScreen> {
  bool loading = true;
  List<dynamic> allBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => loading = true);
    final data = await BookingService.getAllBookings();

    if (mounted) {
      setState(() {
        allBookings = data;
        loading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String status, {int? rank}) async {
    final success = await BookingService.updateBookingStatus(id, status, waitlistRank: rank);
    if (success) {
      _fetchBookings();
    }
  }

  void _showWaitlistDialog(String bookingId) {
    final rankCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Enter Waitlist Rank", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: rankCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "e.g. 1, 2, 5", hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final r = int.tryParse(rankCtrl.text.trim());
              if (r != null) {
                Navigator.pop(context);
                _updateStatus(bookingId, "waitlisted", rank: r);
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterData(String mode) {
    if (mode == 'all') return allBookings;
    if (mode == 'approved') return allBookings.where((b) => b['status'] == 'approved').toList();
    if (mode == 'waitlisted') return allBookings.where((b) => b['status'] == 'waitlisted').toList();
    return [];
  }

  Widget _buildBookingsList(String mode) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

    final filtered = _filterData(mode);
    if (filtered.isEmpty) {
      return const Center(child: Text("No booking requests found.", style: TextStyle(color: Colors.white54)));
    }

    final Map<String, List<dynamic>> groups = {};
    for (var b in filtered) {
      final hName = b['hostelName'] ?? 'Unknown Hostel';
      if (!groups.containsKey(hName)) groups[hName] = [];
      groups[hName]!.add(b);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groups.keys.map((hName) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                hName.toUpperCase(),
                style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            ...groups[hName]!.map((b) => _buildBookingCard(b)).toList(),
            const Divider(color: Colors.white10, height: 32),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text("Manage Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F172A),
          actions: [
            IconButton(onPressed: _fetchBookings, icon: const Icon(Icons.refresh)),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF3B82F6),
            labelColor: Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "All Appls"),
              Tab(text: "Approved"),
              Tab(text: "Waitlisted"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingsList('all'),
            _buildBookingsList('approved'),
            _buildBookingsList('waitlisted'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final status = b['status'] ?? 'pending';
    final date = b['createdAt'] != null ? DateFormat('MMM d, h:mm a').format(DateTime.parse(b['createdAt'])) : 'N/A';

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(b['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("Applied: $date", style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: _statusBadge(status, b['waitlistRank']),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white54,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("Phone", b['phone']),
                _detailRow("Aadhaar", b['aadhaar']),
                _detailRow("Duration", b['duration']),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(b['_id'], "approved"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.2), foregroundColor: Colors.green),
                        child: const Text("Approve"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showWaitlistDialog(b['_id']),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.withOpacity(0.2), foregroundColor: Colors.orange),
                        child: const Text("Waitlist"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value?.toString() ?? 'N/A', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
