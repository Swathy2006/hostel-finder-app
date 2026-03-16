import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/application_service.dart';
import 'package:intl/intl.dart';
import 'edit_hostel_screen.dart';

class HostelStatusScreen extends StatefulWidget {
  const HostelStatusScreen({super.key});

  @override
  State<HostelStatusScreen> createState() => _HostelStatusScreenState();
}

class _HostelStatusScreenState extends State<HostelStatusScreen> {
  bool loading = true;
  List<dynamic> applications = [];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final data = await ApplicationService.getUserApplications(userId);
    if (mounted) {
      setState(() {
        applications = data;
        loading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published': return const Color(0xFF22C55E);
      case 'approved': return const Color(0xFF6366F1);
      case 'rejected': return const Color(0xFFEF4444);
      case 'publish_request_pending': return const Color(0xFFEAB308);
      case 'reviewed': return const Color(0xFFEAB308);
      default: return const Color(0xFF94A3B8);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'published': return Icons.verified_rounded;
      case 'approved': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      case 'publish_request_pending': return Icons.hourglass_top_rounded;
      case 'reviewed': return Icons.rate_review_rounded;
      default: return Icons.access_time_filled_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Hostel Management Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : applications.isEmpty
              ? const _EmptyState(message: "No hostel applications found. Start by adding a hostel!")
              : RefreshIndicator(
                  onRefresh: _fetchApplications,
                  color: const Color(0xFF6366F1),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: applications.length,
                    itemBuilder: (context, index) => _buildAppCard(applications[index]),
                  ),
                ),
    );
  }

  Widget _buildAppCard(Map<String, dynamic> app) {
    final status = app['status'] ?? 'pending';
    final message = app['adminMessage'] ?? '';
    final dateStr = app['createdAt'];
    String formattedDate = '';

    if (dateStr != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(date);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _getStatusColor(status).withOpacity(0.1),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Registration ${status.toUpperCase()}",
                        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (formattedDate.isNotEmpty)
                        Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['hostelName'] ?? 'Unknown Hostel',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.pinkAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "${app['city'] ?? ''}, ${app['district'] ?? ''}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                if (message.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: _getStatusColor(status), width: 4)),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                if (status == 'approved') ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/createHostel',
                          arguments: {
                            'isUserSubmission': true,
                            'district': app['district'],
                            'city': app['city'],
                            'applicationId': app['_id'],
                          },
                        ).then((_) => _fetchApplications());
                      },
                      icon: const Icon(Icons.add_home_work_rounded),
                      label: const Text("Publish Now"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
                if (status == 'reviewed') ...[
                  const SizedBox(height: 20),
                   SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditHostelScreen(hostel: app)),
                        ).then((_) => _fetchApplications());
                      },
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text("Edit & Resubmit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
                if (status == 'pending' || status == 'rejected') ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        setState(() => loading = true);
                        await ApplicationService.deleteApplication(app['_id']);
                        _fetchApplications();
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      label: const Text("Cancel Application", style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white10, size: 80),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
