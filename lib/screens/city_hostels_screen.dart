import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/hostel_service.dart';
import 'hostel_details_screen.dart';
import '../utils/responsive.dart';

class CityHostelsScreen extends StatefulWidget {
  final String city;
  final bool isAdminView;
  final LatLng? userLocation;

  const CityHostelsScreen({
    super.key,
    required this.city,
    this.isAdminView = false,
    this.userLocation,
  });

  @override
  State<CityHostelsScreen> createState() => _CityHostelsScreenState();
}

class _CityHostelsScreenState extends State<CityHostelsScreen> {
  List<dynamic> hostels = [];
  bool loading = true;
  LatLng? searchLocation;
  String searchQuery = "";
  String filterValue = "Any Share";
  String genderFilterValue = "Any Gender";

  final TextEditingController _placeController = TextEditingController();
  List<dynamic> _placeSuggestions = [];
  bool _locating = false;
  int _selectedRadius = 5000; // Default 5km

  final LayerLink _layerLink = LayerLink();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (widget.city == "Nearby") {
      searchLocation = widget.userLocation;
    } else {
      _getCityCoordinates(widget.city);
    }
    loadHostels();
  }

  Future<void> _getCityCoordinates(String cityName) async {
    String urlStr = 'https://nominatim.openstreetmap.org/search?q=$cityName&format=json&limit=1&countrycodes=in';
    try {
      final response = await http.get(Uri.parse(urlStr), headers: {'User-Agent': 'HostelFinderApp/1.0'});
      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body);
        if (result.isNotEmpty) {
          final lat = double.parse(result[0]['lat']);
          final lng = double.parse(result[0]['lon']);
          setState(() {
            searchLocation = LatLng(lat, lng);
          });
          _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(searchLocation!, 12));
          loadHostels(); // Reload with new coordinates for distance calculation
        }
      }
    } catch (e) {
      debugPrint("City Geocoding Error: $e");
    }
  }

  Future<void> loadHostels() async {
    setState(() => loading = true);

    List<dynamic> data;
    // We fetch based on availability
    if (searchLocation != null) {
      // Fetch nearby from backend to find potential candidates
      data = await HostelService.getNearbyHostels(
          searchLocation!.latitude, searchLocation!.longitude,
          radius: _selectedRadius);
    } else {
      // Just fetch all to filter by city
      data = await HostelService.getAllHostels();
    }

    setState(() {
      hostels = data;
      loading = false;
    });
  }

  Future<void> _getPlaceSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _placeSuggestions = []);
      return;
    }

    // Nominatim Search API (Free, no billing needed)
    String urlStr =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=in';

    try {
      final response = await http.get(
        Uri.parse(urlStr),
        headers: {
          'User-Agent': 'HostelFinderApp/1.0', // Required by Nominatim Policy
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body);
        setState(() {
          _placeSuggestions = result;
        });
      }
    } catch (e) {
      debugPrint("OSM Search Error: $e");
    }
  }

  Future<void> _selectPlace(dynamic suggestion) async {
    setState(() {
      _placeSuggestions = [];
      _placeController.text = suggestion['display_name'];
    });
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      // OSM Nominatim provides lat/lng directly in the search results
      final lat = double.parse(suggestion['lat']);
      final lng = double.parse(suggestion['lon']);

      setState(() {
        searchLocation = LatLng(lat, lng);
        searchQuery = "";
      });
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(searchLocation!, 14));
      loadHostels();
    } catch (e) {
      debugPrint("OSM Selection Error: $e");
    }
  }

  Future<void> _handleMyLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Location permissions are permanently denied.")),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        searchLocation = LatLng(position.latitude, position.longitude);
        _placeController.text = "Current Location";
        searchQuery = "";
      });

      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(searchLocation!, 14));
      loadHostels();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error getting location: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<dynamic> get filteredHostels {
    // Reference point for distance calculation
    LatLng? refPoint = searchLocation ?? widget.userLocation;

    return hostels.where((h) {
      // 1. City Filter (Always apply if not in "Nearby" mode)
      if (widget.city != "Nearby" && h['city'] != widget.city) return false;

      // 2. Name search
      final nameMatches = (h['name'] ?? "")
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      final addressMatches = (h['address'] ?? "")
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      if (!(nameMatches || addressMatches)) return false;

      // 3. Room Type Filter
      if (filterValue == "Single" && (h['rentSingle'] ?? 0) <= 0) return false;
      if (filterValue == "Shared" && (h['rentShared'] ?? 0) <= 0) return false;

      // 4. Gender Filter
      if (genderFilterValue != "Any Gender" &&
          (h['gender'] ?? "Mixed") != genderFilterValue) return false;

      // 5. Distance Logic & Radius Filter
      if (refPoint != null) {
        final coords = h['location']?['coordinates'];
        if (coords != null && coords.length == 2) {
          double distMeters = Geolocator.distanceBetween(
            refPoint.latitude,
            refPoint.longitude,
            (coords[1] as num).toDouble(),
            (coords[0] as num).toDouble(),
          );
          
          h['dist_km'] = distMeters / 1000.0;
          
          // Strict Radius Filter
          if (distMeters > _selectedRadius) return false;
        } else {
          // Hide if no coords when radius is active
          return false;
        }
      } else {
        h['dist_km'] = null;
      }

      return true;
    }).toList()..sort((a, b) {
      // Sort by distance if available
      double da = a['dist_km'] ?? 999999.0;
      double db = b['dist_km'] ?? 999999.0;
      return da.compareTo(db);
    });
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.blueAccent : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? labelBuilder,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 0.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.blueAccent),
            const SizedBox(width: 6),
          ],
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(labelBuilder?.call(e) ?? e.toString(),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: const Color(0xFF0F172A),
              icon: const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TabController? tabController) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              const Icon(Icons.map_outlined, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Hostels in ${widget.city}",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Toggle Buttons like in the screenshot
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      icon: Icons.list_rounded,
                      isSelected: tabController?.index == 0,
                      onTap: () => tabController?.animateTo(0),
                    ),
                    _buildToggleButton(
                      icon: Icons.map_rounded,
                      isSelected: tabController?.index == 1,
                      onTap: () => tabController?.animateTo(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextField(
                    controller: _placeController,
                    onChanged: _getPlaceSuggestions,
                    decoration: InputDecoration(
                      hintText: "Location or hostel nam...",
                      prefixIcon: const Icon(Icons.location_on_rounded,
                          size: 18, color: Colors.blueAccent),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_locating)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.blueAccent),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.my_location_rounded,
                                  size: 18, color: Colors.blueAccent),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _handleMyLocation,
                            ),
                          if (_placeController.text.isNotEmpty)
                            IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _placeController.clear();
                                  setState(() {
                                    _placeSuggestions = [];
                                    if (widget.city == "Nearby") {
                                      searchLocation = widget.userLocation;
                                    } else {
                                      searchLocation = null;
                                    }
                                    loadHostels();
                                  });
                                }),
                        ],
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterDropdown<String>(
                value: filterValue,
                items: ["Any Share", "Single", "Shared"],
                onChanged: (val) => setState(() => filterValue = val!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Scrollable other filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown<int>(
                  value: _selectedRadius,
                  items: [500, 1000, 2000, 5000, 10000, 20000, 50000],
                  icon: Icons.radar_rounded,
                  onChanged: (val) {
                    setState(() => _selectedRadius = val!);
                    loadHostels();
                  },
                  labelBuilder: (r) => "${r >= 1000 ? r ~/ 1000 : r}${r >= 1000 ? 'km' : 'm'}",
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown<String>(
                  value: genderFilterValue,
                  items: ["Any Gender", "Boys", "Girls", "Mixed"],
                  icon: Icons.people_rounded,
                  onChanged: (val) => setState(() => genderFilterValue = val!),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 150,
                  height: 36,
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search name...",
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
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
    final gender = h['gender'] ?? "Mixed";

    double? displayDist = h['dist_km'];

    num minRent = 0;
    if (rentSingle > 0 && rentShared > 0) {
      minRent = min(rentSingle, rentShared);
    } else {
      minRent = rentSingle > 0 ? rentSingle : rentShared;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HostelDetailsScreen(
                hostel: h,
                isAdminView: widget.isAdminView,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Header
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF334155), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.apartment_rounded,
                        color: Colors.white12, size: 80),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(rating.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (gender == "Boys"
                                ? Colors.blue
                                : (gender == "Girls"
                                    ? Colors.pink
                                    : Colors.green))
                            .withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(gender,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "₹$minRent",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFACC15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.blueAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address.startsWith("http") ? "View location on map" : address,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (displayDist != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk_rounded,
                                  size: 12, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(
                                "${displayDist.toStringAsFixed(1)} km away",
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat(Icons.meeting_room_rounded,
                          h['totalRooms'] ?? 0, "Rooms"),
                      _buildMiniStat(Icons.people_rounded,
                          h['totalMembers'] ?? h['totalCapacity'] ?? 0, "Members"),
                      _buildMiniStat(Icons.bed_rounded, h['vacancy'] ?? 0,
                          "Vacancy"),
                      _buildMiniStat(Icons.door_front_door_rounded,
                          h['vacantRooms'] ?? 0, "Vacant"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (facilities.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: facilities.take(4).map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF475569), width: 0.5),
                          ),
                          child: Text(
                            f.toString(),
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("STARTING FROM",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            "₹$minRent",
                            style: const TextStyle(
                                color: Color(0xFFFACC15),
                                fontWeight: FontWeight.w900,
                                fontSize: 20),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: (h['rooms'] != null && (h['rooms'] as List).isNotEmpty)
                              ? Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: (h['rooms'] as List).map((r) {
                                    final type = r['type'] ?? 'shared';
                                    final sharing = r['sharingCount'] ?? 1;
                                    final label = type == 'single' ? 'Single' : '${sharing} Share';
                                    final rent = r['rent'] ?? 0;
                                    final totalR = r['totalRooms'] ?? 0;
                                    final vac = r['vacancy'] ?? 0;
                                    return _shareChip(label, rent, totalR, vac);
                                  }).toList(),
                                )
                              : Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  children: [
                                    if (rentSingle > 0) _shareChip("Single", rentSingle, 0, 0),
                                    if (rentShared > 0) _shareChip("Shared", rentShared, 0, 0),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, dynamic value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontSize: 8, color: Colors.grey, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _shareChip(String label, num price, int totalRooms, int vacancy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
              const SizedBox(width: 4),
              Text("₹$price",
                  style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text("$vacancy Vacant / $totalRooms Total",
              style: TextStyle(
                  color: vacancy > 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildMapWidget(List<dynamic> displayHostels, LatLng center) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF334155))),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 14),
            style:
                "[{\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#212121\"}]},{\"elementType\":\"labels.icon\",\"stylers\":[{\"visibility\":\"off\"}]},{\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"elementType\":\"labels.text.stroke\",\"stylers\":[{\"color\":\"#212121\"}]},{\"featureType\":\"administrative\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"administrative.country\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#9e9e9e\"}]},{\"featureType\":\"administrative.land_parcel\",\"stylers\":[{\"visibility\":\"off\"}]},{\"featureType\":\"administrative.locality\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#bdbdbd\"}]},{\"featureType\":\"poi\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#181818\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#616161\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"labels.text.stroke\",\"stylers\":[{\"color\":\"#1b1b1b\"}]},{\"featureType\":\"road\",\"elementType\":\"geometry.fill\",\"stylers\":[{\"color\":\"#2c2c2c\"}]},{\"featureType\":\"road\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#8a8a8a\"}]},{\"featureType\":\"road.arterial\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#373737\"}]},{\"featureType\":\"road.highway\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#3c3c3c\"}]},{\"featureType\":\"road.highway.controlled_access\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#4e4e4e\"}]},{\"featureType\":\"road.local\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#616161\"}]},{\"featureType\":\"transit\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"water\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#000000\"}]},{\"featureType\":\"water\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#3d3d3d\"}]}]",
            markers: {
              // Landmark Marker (Blue)
              if (searchLocation != null)
                Marker(
                  markerId: const MarkerId("search_landmark"),
                  position: searchLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueCyan),
                  infoWindow: InfoWindow(title: _placeController.text),
                ),
              // Hostel Markers (Red)
              ...displayHostels
                  .where((h) =>
                      h['location']?['coordinates'] != null &&
                      (h['location']['coordinates'] as List).length == 2)
                  .map((h) {
                final coords = h['location']['coordinates'];
                return Marker(
                  markerId: MarkerId(
                      (h['_id'] ?? h['name'] ?? h.hashCode).toString()),
                  position: LatLng((coords[1] as num).toDouble(),
                      (coords[0] as num).toDouble()),
                  infoWindow: InfoWindow(title: h['name'] ?? "Hostel"),
                );
              }),
            },
            circles: {
              if (searchLocation != null)
                Circle(
                  circleId: const CircleId("radius_circle"),
                  center: searchLocation!,
                  radius: _selectedRadius.toDouble(),
                  fillColor: Colors.blueAccent.withOpacity(0.1),
                  strokeColor: Colors.blueAccent.withOpacity(0.5),
                  strokeWidth: 2,
                ),
            },
            onMapCreated: (c) => _mapController = c,
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16)),
                child: Text("${displayHostels.length} hostels shown",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListWidget(List<dynamic> displayHostels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text("ALL HOSTELS (${displayHostels.length})",
              style: const TextStyle(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  fontSize: 12)),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: displayHostels.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => HostelDetailsScreen(
                              hostel: displayHostels[index],
                              isAdminView: widget.isAdminView)));
                },
                child: _buildHostelCard(displayHostels[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        final tabController = DefaultTabController.of(context);
        
        // Listen to tab changes to rebuild header toggle state
        tabController.addListener(() {
          if (!tabController.indexIsChanging) {
            setState(() {});
          }
        });

        final displayHostels = filteredHostels;
        LatLng center = searchLocation ?? widget.userLocation ?? const LatLng(10.8505, 76.2711);

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: SafeArea(
            child: Stack(
              children: [
                // Main Layer
                Column(
                  children: [
                    _buildHeader(tabController),
                    Expanded(
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.blueAccent))
                          : TabBarView(
                              physics: const NeverScrollableScrollPhysics(), // Only toggle via header
                              children: [
                                // Tab 1: List View
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildListWidget(displayHostels),
                                ),
                                // Tab 2: Map View
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: _buildMapWidget(displayHostels, center),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                // Suggestions Layer (Highest Z-index)
                if (_placeSuggestions.isNotEmpty)
                  _buildSuggestionsList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSuggestionsList() {
    return Positioned(
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 48), // Directly below the search bar
        child: Padding(
          padding: const EdgeInsets.only(right: 32), // Account for filter dropdown sibling
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 280),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _placeSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF334155)),
                  itemBuilder: (context, index) {
                    final p = _placeSuggestions[index];
                    final displayName = p['display_name'] as String;
                    return ListTile(
                      dense: true,
                      title: Text(displayName, style: const TextStyle(fontSize: 12, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _selectPlace(p),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
