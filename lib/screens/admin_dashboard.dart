import 'package:flutter/material.dart';
import 'hostel_details_screen.dart';
import '../services/hostel_service.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool loading = true;
  List<dynamic> myHostels = [];
  int _selectedIndex = 0; // 0 for Home Page, 1 for My Hostel

  @override
  void initState() {
    super.initState();
    _loadMyHostels();
  }

  Future<void> _loadMyHostels() async {
    final ownerId = AuthService.currentUserId ?? '';
    final list = await HostelService.getHostelsByOwner(ownerId);
    setState(() {
      myHostels = list;
      loading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Publish a new accommodation",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await Navigator.pushNamed(context, '/createHostel');
                _loadMyHostels(); // refresh list when returning
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B),
                      const Color(0xFF334155).withOpacity(0.5),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_business_rounded,
                        color: Color(0xFF6366F1), // Indigo 500
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add New Hostel",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Create a new listing with rooms and pricing",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostelPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "My Hostels", // Updated label
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Manage and edit your published listings",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : myHostels.isEmpty
                    ? const Center(child: Text('No hostels created yet'))
                    : ListView.builder(
                        itemCount: myHostels.length,
                        itemBuilder: (context, index) {
                          final h = myHostels[index];
                          final name = h['name'] ?? 'Unnamed';
                          final addressUrl = h['address'] ?? '';
                          final isGoogleMapLink =
                              addressUrl.toString().contains('google.com/maps');

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 6,
                            shadowColor: Colors.black45,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HostelDetailsScreen(
                                      hostel: h,
                                      isAdminView: true,
                                    ),
                                  ),
                                );
                                _loadMyHostels();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.visibility_rounded,
                                            color: Color(0xFF8B5CF6), size: 28),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Mini Stats Row
                                    Row(
                                      children: [
                                        _buildMiniStatTile(
                                          icon: Icons.meeting_room_rounded,
                                          value: "${h['totalRooms'] ?? 'N/A'}",
                                          label: "Total Rooms",
                                        ),
                                        const SizedBox(width: 12),
                                        _buildMiniStatTile(
                                          icon: Icons.currency_rupee_rounded,
                                          value:
                                              "₹${h['rentSingle'] ?? h['rentShared'] ?? '0'}",
                                          label: "Price / Mo",
                                        ),
                                        const SizedBox(width: 12),
                                        _buildMiniStatTile(
                                          icon: Icons.people_alt_rounded,
                                          value:
                                              "${h['totalCapacity'] ?? 'N/A'}",
                                          label: "Capacity",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    if (isGoogleMapLink)
                                      SizedBox(
                                        width: double.infinity,
                                        child: IgnorePointer(
                                          child: ElevatedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.map_rounded),
                                            label: const Text("View on Maps"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF1E293B),
                                              foregroundColor:
                                                  const Color(0xFF6366F1),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: const BorderSide(
                                                    color: Color(0xFF334155)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (addressUrl.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded,
                                              color: Colors.grey, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              addressUrl,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? "Admin Dashboard" : "My Hostel",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E293B),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF0F172A),
                image: DecorationImage(
                  image: AssetImage('assets/images/admin_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black54,
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Admin Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.white),
              title: const Text('Home Page',
                  style: TextStyle(color: Colors.white)),
              selectedTileColor: const Color(0xFF334155),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.business_rounded, color: Colors.white),
              title: const Text('My Hostel',
                  style: TextStyle(color: Colors.white)),
              selectedTileColor: const Color(0xFF334155),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/admin_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay to ensure text readability
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F172A).withOpacity(0.85),
            ),
          ),
          // Main content
          _selectedIndex == 0 ? _buildHomePage() : _buildHostelPage(),
        ],
      ),
    );
  }

  Widget _buildMiniStatTile(
      {required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
