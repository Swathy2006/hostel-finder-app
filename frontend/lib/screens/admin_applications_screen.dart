import 'package:flutter/material.dart';
import '../services/application_service.dart';
import 'package:intl/intl.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  bool loadingApps = true;
  List<dynamic> applications = [];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() => loadingApps = true);
    final data = await ApplicationService.getAllApplications();
    if (mounted) {
      setState(() {
        applications = data.where((app) {
          final s = app['status'];
          return s == 'pending' || s == 'reviewed' || s == 'approved' || s == 'rejected';
        }).toList();
        loadingApps = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return const Color(0xFF22C55E); // Green
      case 'approved':
        return const Color(0xFF6366F1); // Indigo
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'publish_request_pending':
        return const Color(0xFFEAB308); // Yellow
      case 'reviewed':
        return const Color(0xFFEAB308); // Yellow
      default:
        return const Color(0xFF94A3B8); // Grey (pending)
    }
  }

  void _showReviewDialog(Map<String, dynamic> app) {
    String currentStatus = app['status'] ?? 'pending';
    final msgCtrl = TextEditingController(text: app['adminMessage'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                "Review Application",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hostel: ${app['hostelName']}", style: const TextStyle(color: Colors.white70)),
                    Text("Owner: ${app['ownerName']}", style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    const Text("Status:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: currentStatus,
                      dropdownColor: const Color(0xFF0F172A),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<String>(value: 'pending', child: Text("Pending", style: TextStyle(color: Colors.grey))),
                        DropdownMenuItem<String>(value: 'reviewed', child: Text("Reviewing", style: TextStyle(color: Color(0xFFEAB308)))),
                        DropdownMenuItem<String>(value: 'approved', child: Text("Approved", style: TextStyle(color: Color(0xFF6366F1)))),
                        DropdownMenuItem<String>(value: 'rejected', child: Text("Rejected", style: TextStyle(color: Color(0xFFEF4444)))),
                      ],
                      onChanged: (val) {
                        setDialogState(() => currentStatus = val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Feedback Message (Optional):", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: msgCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter a message for the user...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          final success = await ApplicationService.updateApplicationStatus(
                            app['_id'],
                            currentStatus,
                            msgCtrl.text.trim(),
                          );
                          if (mounted) {
                            setDialogState(() => saving = false);
                            if (success) {
                              Navigator.pop(context); 
                              _fetchApplications(); 
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application updated.")));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update.")));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAB308),
                    foregroundColor: Colors.black,
                  ),
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("Save & Notify User"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title:
            const Text("Hostel Applicants", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _buildApplicationsTab(),
    );
  }

  Widget _buildApplicationsTab() {
    if (loadingApps) return const Center(child: CircularProgressIndicator(color: Color(0xFFEAB308)));
    if (applications.isEmpty) return const Center(child: Text("No applications found.", style: TextStyle(color: Colors.white54, fontSize: 16)));
    
    return RefreshIndicator(
      onRefresh: _fetchApplications,
      color: const Color(0xFFEAB308),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final app = applications[index];
          final status = app['status'] ?? 'pending';
          String formattedDate = '';
          if (app['createdAt'] != null) {
            final date = DateTime.tryParse(app['createdAt']);
            if (date != null) formattedDate = DateFormat('MMM d, yyyy').format(date);
          }

          return _buildApplicationCard(app, status, formattedDate);
        },
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app, String status, String date) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReviewDialog(app),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      app['hostelName'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("Owner: ${app['ownerName']}", style: const TextStyle(color: Colors.white70)),
              Text("City: ${app['city']}, District: ${app['district']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const Text("Tap to Review", style: TextStyle(color: Color(0xFFEAB308), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

