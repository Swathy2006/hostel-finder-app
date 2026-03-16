import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../utils/location_data.dart';
import 'my_hostels_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_applications_screen.dart';
import 'admin_manage_bookings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  void _showLocationSelectionDialog(BuildContext context) {
    String? selectedDistrict;
    String? selectedCity;

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
                "Select Hostel Location",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "District",
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: const Color(0xFF0F172A),
                    value: selectedDistrict,
                    items: keralaDistrictsAndCities.keys.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedDistrict = val;
                        selectedCity = null; 
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "City",
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: const Color(0xFF0F172A),
                    value: selectedCity,
                    items: selectedDistrict == null
                        ? []
                        : keralaDistrictsAndCities[selectedDistrict]!
                            .map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(city, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                    onChanged: selectedDistrict == null
                        ? null
                        : (val) {
                            setDialogState(() {
                              selectedCity = val;
                            });
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedDistrict != null && selectedCity != null
                      ? () async {
                          Navigator.pop(context);
                          await Navigator.pushNamed(
                            context,
                            '/createHostel',
                            arguments: {
                              'district': selectedDistrict,
                              'city': selectedCity,
                            },
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAB308), // Yellow
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAB308).withOpacity(0.15),
              border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.5), width: 1.5),
            ),
            child: const Center(
              child: Text(
                "A",
                style: TextStyle(
                  color: Color(0xFFEAB308),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  "Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.5)),
            ),
            child: const Text(
              "ADMIN",
              style: TextStyle(
                color: Color(0xFFEAB308),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showLiveBadge = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (showLiveBadge) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                              ),
                              child: const Text(
                                "LIVE",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: iconColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.person_rounded, color: Color(0xFFEAB308), size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                );
              },
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isMobile(context) ? 20.0 : 32.0,
            vertical: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              
              _buildSectionHeader("MANAGEMENT"),
              
              _buildActionTile(
                icon: Icons.assignment_ind_rounded,
                iconColor: const Color(0xFFF97316), // Orange
                title: "Hostel Applicants",
                subtitle: "Review incoming user requests to\nadd a new hostel.",
                showLiveBadge: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminApplicationsScreen()),
                  );
                },
              ),
              
              _buildActionTile(
                icon: Icons.business_rounded,
                iconColor: const Color(0xFF3B82F6), // Blue
                title: "Manage Published Hostels",
                subtitle: "View published hostels and review\nrequested changes.",
                onTap: () {
                  Navigator.pushNamed(context, '/adminManageHostels');
                },
              ),
              
              _buildActionTile(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF10B981), // Green
                title: "Manage Bookings",
                subtitle: "View, confirm or reject booking\nrequests.",
                showLiveBadge: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminManageBookingsScreen()),
                  );
                },
              ),
              
              _buildActionTile(
                icon: Icons.manage_accounts_rounded,
                iconColor: const Color(0xFFA855F7), // Purple
                title: "My Profile",
                subtitle: "Edit your admin account details.",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
