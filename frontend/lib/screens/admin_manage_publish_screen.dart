import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/hostel_service.dart';
import '../utils/responsive.dart';
import 'my_hostels_screen.dart'; 
import 'hostel_details_screen.dart';

class AdminManagePublishScreen extends StatefulWidget {
  const AdminManagePublishScreen({super.key});

  @override
  State<AdminManagePublishScreen> createState() => _AdminManagePublishScreenState();
}

class _AdminManagePublishScreenState extends State<AdminManagePublishScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loadingPublishRequests = true;
  bool loadingEditRequests = true;
  List<dynamic> publishRequests = [];
  List<dynamic> editRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPublishRequests();
    _fetchEditRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPublishRequests() async {
    setState(() => loadingPublishRequests = true);
    final data = await HostelService.getPublishRequests();
    if (mounted) {
      setState(() {
        publishRequests = data;
        loadingPublishRequests = false;
      });
    }
  }
  Future<void> _fetchEditRequests() async {
    setState(() => loadingEditRequests = true);
    final data = await HostelService.getEditRequests();
    if (mounted) {
      setState(() {
        editRequests = data;
        loadingEditRequests = false;
      });
    }
  }

  void _showEditReviewDialog(Map<String, dynamic> hostel) {
    final changes = hostel['pendingChanges'] ?? {};
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
                "Review Edit Request",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hostel: ${hostel['name']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("Owner: ${hostel['owner']['name'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      const Text("Proposed Changes:", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white24),
                      ...changes.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              children: [
                                TextSpan(text: "${e.key}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                TextSpan(text: "${e.value}"),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () async {
                    setDialogState(() => saving = true);
                    final success = await HostelService.rejectEditRequest(hostel['_id']);
                    if (mounted) {
                      setDialogState(() => saving = false);
                      if (success) {
                        Navigator.pop(context);
                        _fetchEditRequests();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit request rejected.")));
                      }
                    }
                  },
                  child: const Text("Reject", style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          final success = await HostelService.approveEditRequest(hostel['_id']);
                          if (mounted) {
                            setDialogState(() => saving = false);
                            if (success) {
                              Navigator.pop(context);
                              _fetchEditRequests();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes approved and applied!")));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to apply changes.")));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPublishRequestsTab() {
    if (loadingPublishRequests) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    if (publishRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.publish_rounded, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              "No Publish Requests",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "All hostellers are quiet for now.",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPublishRequests,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: publishRequests.length,
        itemBuilder: (context, index) {
          final req = publishRequests[index];
          String formattedDate = '';
          if (req['createdAt'] != null) {
            final date = DateTime.tryParse(req['createdAt']);
            if (date != null) {
              formattedDate = DateFormat('MMM d, yyyy').format(date);
            }
          }

          return Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF334155)),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                req['name'] ?? 'Unknown Hostel',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text("Owner: ${req['ownerName'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
                  Text("District: ${req['district']}, City: ${req['city']}", style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 8),
                  Text("Submitted: $formattedDate", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF3B82F6)),
              onTap: () async {
                final refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HostelDetailsScreen(
                      hostel: req,
                      isAdminView: false,
                      isReviewMode: true,
                    ),
                  ),
                );
                if (refresh == true) _fetchPublishRequests();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChangeRequestsTab() {
    if (loadingEditRequests) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    if (editRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 64),
            SizedBox(height: 16),
            Text(
              "No Change Requests",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "When owners submit edits, they will appear here.",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEditRequests,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: editRequests.length,
        itemBuilder: (context, index) {
          final hostel = editRequests[index];
          return _buildEditRequestCard(hostel);
        },
      ),
    );
  }

  Widget _buildEditRequestCard(Map<String, dynamic> hostel) {
    String formattedDate = '';
    if (hostel['updatedAt'] != null) {
      final date = DateTime.tryParse(hostel['updatedAt']);
      if (date != null) formattedDate = DateFormat('MMM d, yyyy').format(date);
    }

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          hostel['name'] ?? 'Unknown Hostel',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text("Owner: ${hostel['owner']['name'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70)),
            Text("City: ${hostel['city']}, District: ${hostel['district']}", style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Text("Requested: $formattedDate", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1)),
        onTap: () => _showEditReviewDialog(hostel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Manage Hostels",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey,
          isScrollable: Responsive.isMobile(context),
          tabs: const [
            Tab(text: "Publish Requests", icon: Icon(Icons.publish_rounded)),
            Tab(text: "Live Listings", icon: Icon(Icons.verified_rounded)),
            Tab(text: "Change Requests", icon: Icon(Icons.change_circle_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPublishRequestsTab(),
          const MyHostelsScreen(hideAppBar: true), 
          _buildChangeRequestsTab(),
        ],
      ),
    );
  }
}
