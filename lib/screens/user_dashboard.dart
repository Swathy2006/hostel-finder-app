import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/hostel_service.dart';
import 'hostel_details_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<dynamic> hostels = [];
  bool loading = true;
  LatLng? userLocation;
  String searchQuery = "";
  String filterValue = "Any Share";

  @override
  void initState() {
    super.initState();
    loadHostels();
  }

  Future<void> loadHostels() async {
    setState(() => loading = true);

    List<dynamic> data;
    if (userLocation != null) {
      data = await HostelService.getNearbyHostels(
          userLocation!.latitude, userLocation!.longitude);
    } else {
      data = await HostelService.getAllHostels();
    }

    setState(() {
      hostels = data;
      loading = false;
    });
  }

  List<dynamic> get filteredHostels {
    return hostels.where((h) {
      final nameMatches = (h['name'] ?? "")
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      final addressMatches = (h['address'] ?? "")
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      bool typeMatches = true;
      if (filterValue == "Single") {
        typeMatches = (h['rentSingle'] ?? 0) > 0;
      } else if (filterValue == "Shared") {
        typeMatches = (h['rentShared'] ?? 0) > 0;
      }

      return (nameMatches || addressMatches) && typeMatches;
    }).toList();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.map_outlined, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 12),
          const Text(
            "Find Hostels",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Search Bar
          Container(
            width: 300,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search name or area...",
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          const SizedBox(width: 16),
          // Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filterValue,
                items: ["Any Share", "Single", "Shared"]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => filterValue = val!),
                dropdownColor: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostelCard(dynamic h) {
    final name = h['name'] ?? "Premium Hostel";
    final address = h['address'] ?? "Unknown Location";
    final rentSingle = (h['rentSingle'] ?? 0) as num;
    final rentShared = (h['rentShared'] ?? 0) as num;
    final facilities = h['facilities'] as List? ?? [];
    final rating = (h['rating'] ?? 4.5).toDouble();

    num minRent = 0;
    if (rentSingle > 0 && rentShared > 0) {
      minRent = min(rentSingle, rentShared);
    } else {
      minRent = rentSingle > 0 ? rentSingle : rentShared;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.home_rounded,
                  color: Colors.orangeAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.pinkAccent),
                        const SizedBox(width: 4),
                        Text(address,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(rating.toString(),
                      style: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "From Rs.$minRent/mo",
            style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 12),
          // Facilities
          Wrap(
            spacing: 8,
            children: facilities
                .take(4)
                .map((f) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(f,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          // Room Shares
          Row(
            children: [
              _shareChip("1-sh", rentSingle),
              _shareChip("2-sh", rentShared),
              _shareChip("3-sh", (rentShared * 0.9).toInt()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareChip(String label, dynamic price) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 4),
          Text("Rs.${(price / 1000).toStringAsFixed(1)}k",
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayHostels = filteredHostels;

    LatLng center = const LatLng(13.0827, 80.2707);
    if (displayHostels.isNotEmpty) {
      double lat = 0;
      double lng = 0;
      for (var h in displayHostels) {
        final coords = h['location']['coordinates'];
        lat += coords[1];
        lng += coords[0];
      }
      center = LatLng(lat / displayHostels.length, lng / displayHostels.length);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                // Left Map Side
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 12, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: center,
                            zoom: center.latitude == 13.0827 ? 12 : 14,
                          ),
                          style:
                              "[{\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#212121\"}]},{\"elementType\":\"labels.icon\",\"stylers\":[{\"visibility\":\"off\"}]},{\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"elementType\":\"labels.text.stroke\",\"stylers\":[{\"color\":\"#212121\"}]},{\"featureType\":\"administrative\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"administrative.country\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#9e9e9e\"}]},{\"featureType\":\"administrative.land_parcel\",\"stylers\":[{\"visibility\":\"off\"}]},{\"featureType\":\"administrative.locality\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#bdbdbd\"}]},{\"featureType\":\"poi\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#181818\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#616161\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"labels.text.stroke\",\"stylers\":[{\"color\":\"#1b1b1b\"}]},{\"featureType\":\"road\",\"elementType\":\"geometry.fill\",\"stylers\":[{\"color\":\"#2c2c2c\"}]},{\"featureType\":\"road\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#8a8a8a\"}]},{\"featureType\":\"road.arterial\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#373737\"}]},{\"featureType\":\"road.highway\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#3c3c3c\"}]},{\"featureType\":\"road.highway.controlled_access\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#4e4e4e\"}]},{\"featureType\":\"road.local\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#616161\"}]},{\"featureType\":\"transit\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"water\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#000000\"}]},{\"featureType\":\"water\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#3d3d3d\"}]}]",
                          markers: displayHostels.map((h) {
                            final coords = h['location']?['coordinates'];
                            return Marker(
                              markerId: MarkerId(h['_id'] ?? h['name']),
                              position: LatLng(coords[1], coords[0]),
                              infoWindow: InfoWindow(title: h['name']),
                            );
                          }).toSet(),
                        ),
                        // Overlay Text
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${displayHostels.length} hostels shown · Click any marker to see details",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right List Side
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            "ALL HOSTELS (${displayHostels.length})",
                            style: const TextStyle(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: displayHostels.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HostelDetailsScreen(
                                          hostel: displayHostels[index]),
                                    ),
                                  );
                                },
                                child: _buildHostelCard(displayHostels[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
