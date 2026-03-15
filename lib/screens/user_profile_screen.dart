import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/application_service.dart';
import '../services/hostel_service.dart';
import 'hostel_details_screen.dart';
import 'edit_hostel_screen.dart';
import 'user_bookings_screen.dart';
import 'owner_bookings_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool loading = true;
  bool saving = false;
  Map<String, dynamic>? profileData;
  List<dynamic> userApplications = [];
  List<dynamic> myHostels = [];
  bool loadingApps = true;
  bool loadingHostels = true;

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final data = await AuthService.getUserProfile(userId);
    if (data != null && mounted) {
      setState(() {
        profileData = data;
        nameCtrl.text = data['name'] ?? '';
        phoneCtrl.text = data['phone'] ?? '';
        emailCtrl.text = data['email'] ?? '';
        loading = false;
      });
      _fetchApplications(userId);
      _fetchMyHostels(userId);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile data")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchApplications(String userId) async {
    final apps = await ApplicationService.getUserApplications(userId);
    if (mounted) {
      setState(() {
        userApplications = apps;
        loadingApps = false;
      });
    }
  }

  Future<void> _fetchMyHostels(String userId) async {
    final hostels = await HostelService.getHostelsByOwner(userId);
    if (mounted) {
      setState(() {
        myHostels = hostels.where((h) => h['isApproved'] == true).toList();
        loadingHostels = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    setState(() => saving = true);

    final success = await AuthService.updateUserProfile(
      userId,
      nameCtrl.text.trim(),
      emailCtrl.text.trim(),
      phoneCtrl.text.trim(),
    );

    if (mounted) {
      setState(() {
        saving = false;
        if (success) isEditing = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final curPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    bool changing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Change Password",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: curPassCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "New Password",
                      labelStyle: const TextStyle(color: Colors.grey),
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
              actions: [
                TextButton(
                  onPressed: changing ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: changing
                      ? null
                      : () async {
                          if (curPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          setDialogState(() => changing = true);

                          final error = await AuthService.changePassword(
                            AuthService.currentUserId!,
                            curPassCtrl.text,
                            newPassCtrl.text,
                          );

                          if (mounted) {
                            setDialogState(() => changing = false);
                            Navigator.pop(context); // Close dialog
                            if (error == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Password changed successfully!")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1), // Indigo Theme
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: changing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Save Password", style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Big Avatar Header
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.15),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 2),
              ),
              child: Center(
                child: Text(
                  nameCtrl.text.isNotEmpty ? nameCtrl.text.trim()[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Base Details Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF818CF8)),
                      filled: true,
                      fillColor: isEditing ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isEditing ? const BorderSide(color: Color(0xFF6366F1)) : BorderSide.none,
                      ),
                    ),
                    enabled: isEditing,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailCtrl,
                    style: TextStyle(color: isEditing ? Colors.white : Colors.white54, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Registered Email",
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                      filled: true,
                      fillColor: isEditing ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isEditing ? const BorderSide(color: Color(0xFF6366F1)) : BorderSide.none,
                      ),
                    ),
                    enabled: isEditing,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Phone Number (Optional)",
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF3B82F6)),
                      filled: true,
                      fillColor: isEditing ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: isEditing ? const BorderSide(color: Color(0xFF6366F1)) : BorderSide.none,
                      ),
                    ),
                    enabled: isEditing,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: saving 
                        ? null 
                        : () {
                            if (isEditing) {
                              _saveProfile();
                            } else {
                              setState(() => isEditing = true);
                            }
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing ? "Save Changes" : "Edit Profile",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Security Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security_rounded, color: Colors.white70),
                      SizedBox(width: 12),
                      Text(
                        "Security",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "You will be required to provide your current password to set a new one.",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _showChangePasswordDialog,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)), // Red
                        foregroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Change Password",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Bookings & Appointments Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.book_online_rounded, color: Color(0xFF818CF8)),
                      SizedBox(width: 12),
                      Text(
                        "Bookings & Appointments",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Track your stay applications and manage scheduled appointments.",
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserBookingsScreen()),
                        );
                      },
                      icon: const Icon(Icons.history_edu_rounded),
                      label: const Text("My Booking Applications"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  if (myHostels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OwnerBookingsScreen()),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_rounded, color: Colors.orangeAccent),
                        label: const Text("Booking Appointments (Owner)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent.withOpacity(0.1),
                          foregroundColor: Colors.orangeAccent,
                          side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Manage Published Hostels
            _buildPublishedHostelsSection(),

            const SizedBox(height: 32),
            
            // Manage Active Drafts Container
            _buildManageDraftsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildManageDraftsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_document, color: Color(0xFFF59E0B)),
              SizedBox(width: 12),
              Text(
                "My Publish Requests",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Manage the hostel details you submitted for publishing review.",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (loadingApps)
            const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          else if (userApplications.where((a) => a['status'] == 'publish_request_pending').isEmpty)
            const Center(
              child: Text(
                "You have no pending publish requests.",
                style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...userApplications
                .where((a) => a['status'] == 'publish_request_pending')
                .map((app) => _buildDraftCard(app)),
        ],
      ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_rounded, color: Color(0xFF818CF8), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  app['hostelName'] ?? 'Unknown Hostel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "PENDING",
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final draft = await ApplicationService.getLinkedDraft(app['_id']);
                    if (draft != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => HostelDetailsScreen(
                              hostel: draft,
                              isAdminView: false,
                              isReviewMode: false,
                              showBooking: false,
                            ),
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Draft not found")));
                    }
                  },
                  icon: const Icon(Icons.preview_rounded, color: Colors.white, size: 18),
                  label: const Text("Preview", style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final draft = await ApplicationService.getLinkedDraft(app['_id']);
                    if (draft != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditHostelScreen(hostel: draft),
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Draft not found")));
                    }
                  },
                  icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  label: const Text("Edit", style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedHostelsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.greenAccent),
              SizedBox(width: 12),
              Text(
                "My Published Hostels",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Manage your live hostels. Any edits will require admin approval.",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (loadingHostels)
            const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          else if (myHostels.isEmpty)
            const Center(
              child: Text(
                "You have no published hostels yet.",
                style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...myHostels.map((hostel) => _buildHostelCard(hostel)),
        ],
      ),
    );
  }

  Widget _buildHostelCard(Map<String, dynamic> hostel) {
    bool hasPending = hostel['hasPendingEdits'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hostel['name'] ?? 'Unknown Hostel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (hasPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "EDIT PENDING",
                    style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HostelDetailsScreen(
                          hostel: hostel,
                          isAdminView: false,
                          showBooking: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
                  label: const Text("View Live", style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditHostelScreen(hostel: hostel),
                      ),
                    );
                    if (result == true) {
                      _fetchMyHostels(AuthService.currentUserId!);
                    }
                  },
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                  label: const Text("Edit", style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
