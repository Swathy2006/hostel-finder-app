import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/location_data.dart';
import '../utils/image_data.dart';
import 'city_selection_screen.dart';
import 'user_profile_screen.dart';
import 'user_notifications_screen.dart';
import 'hostel_status_screen.dart';
import 'city_hostels_screen.dart';
import 'user_application_screen.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<dynamic> userApps = [];
  bool loadingApps = true;

  @override
  void initState() {
    super.initState();
    _checkHostelStatus();
  }

  Future<void> _checkHostelStatus() async {
    final userId = AuthService.currentUserId;
    if (userId != null) {
      final apps = await ApplicationService.getUserApplications(userId);
      if (mounted) {
        setState(() {
          userApps = apps;
          loadingApps = false;
        });
      }
    } else {
      if (mounted) setState(() => loadingApps = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final districts = keralaDistrictsAndCities.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Select District",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!loadingApps && userApps.isNotEmpty) _buildSpecialNotificationBar(),
            const Padding(
              padding: EdgeInsets.only(bottom: 16, left: 4),
              child: Text(
                "Where are you looking for a hostel?",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                "Popular Districts",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: districts.length,
                itemBuilder: (context, index) {
                  final districtName = districts[index];
                  final imageUrl = getDistrictImage(districtName);
                  return _buildDistrictCard(context, districtName, imageUrl);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1E293B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.home_work_rounded, color: Color(0xFF6366F1), size: 48),
                SizedBox(height: 12),
                Text(
                  "HostelHub",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Colors.white70),
            title: const Text("Home", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded, color: Colors.white70),
            title: const Text("My Profile", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_home_work_rounded, color: Colors.white70),
            title: const Text("Add Hostel", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserApplicationScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_rounded, color: Colors.white70),
            title: const Text("Notifications", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserNotificationsScreen()));
            },
          ),
          const Divider(color: Color(0xFF334155), height: 32),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialNotificationBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HostelStatusScreen()),
        ).then((_) => _checkHostelStatus());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hostel Management Updates",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Check your registration & publishing status",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictCard(BuildContext context, String name, String bgImage) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 10),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CitySelectionScreen(district: name)),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                bgImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF334155)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0F172A).withOpacity(0.95),
                      const Color(0xFF0F172A).withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "Select Cities",
                            style: TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFFFDE047), size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
