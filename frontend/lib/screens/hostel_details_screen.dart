import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_form_screen.dart';
import '../services/hostel_service.dart';
import 'edit_hostel_screen.dart';
import '../utils/responsive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HostelDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final bool isAdminView;
  final bool isReviewMode;
  final bool showBooking;

  const HostelDetailsScreen({
    super.key,
    required this.hostel,
    this.isAdminView = false,
    this.isReviewMode = false,
    this.showBooking = true,
  });

  Future<void> _makeCall(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showRejectDialog(BuildContext context, String hostelId) {
    final msgCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Reject Publish Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Please provide a reason or feedback for the user.", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter a message...",
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
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          final success = await HostelService.rejectPublishRequest(hostelId, msgCtrl.text.trim());
                          if (ctx.mounted) {
                            setDialogState(() => saving = false);
                            if (success) {
                              Navigator.pop(ctx); 
                              Navigator.pop(context, true); 
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Failed to reject.")));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Reject & Notify"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _launchMaps() async {
    final coords = hostel['location']?['coordinates'];
    if (coords is List && coords.length >= 2) {
      final double lat = (coords[1] as num).toDouble();
      final double lng = (coords[0] as num).toDouble();
      final String url =
          "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = hostel;
    final name = h['name'] ?? "Luxury Hostel";
    final address = h['address'] ?? "Address not available";
    final owner = h['ownerName'] ?? "N/A";
    final contact = h['contactNo'] ?? "";
    final rentS = h['rentSingle'] ?? 0;
    final rentShared = h['rentShared'] ?? 0;
    final vacancy = h['vacancy'] ?? 0;
    final List facilities = h['facilities'] ?? [];
    final images = h['images'] ?? [];
    final String hostelId = h['_id'] ?? h['name'] ?? "unknown";
    // Deterministic random index for AI image pool
    final int imgIdx = hostelId.hashCode.abs() % 5;
    final List<String> aiImages = [
      "https://images.unsplash.com/photo-1555854817-5b2260d15d49?q=80&w=1200&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1596272875729-ed2ff7d6d9c5?q=80&w=1200&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1520277739336-7bf67edfa768?q=80&w=1200&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1563911302283-d2bc129e7570?q=80&w=1200&auto=format&fit=crop",
      "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?q=80&w=1200&auto=format&fit=crop",
    ];
    final String aiBackground = aiImages[imgIdx];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // Header with Image
          SliverAppBar(
            expandedHeight: Responsive.isMobile(context) ? 250 : 400,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    images.isNotEmpty ? images[0] : aiBackground,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                      ),
                      child: const Icon(Icons.apartment_rounded,
                          size: 80, color: Colors.white24),
                    ),
                  ),
                  // Gradient Overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Colors.black87
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (h['gender'] == "Boys"
                                        ? Colors.blue
                                        : (h['gender'] == "Girls"
                                            ? Colors.pink
                                            : Colors.green))
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (h['gender'] ?? "Mixed").toUpperCase(),
                                style: TextStyle(
                                  color: (h['gender'] == "Boys"
                                      ? Colors.blueAccent
                                      : (h['gender'] == "Girls"
                                          ? Colors.pinkAccent
                                          : Colors.greenAccent)),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: vacancy > 0
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          vacancy > 0 ? "AVAILABLE" : "FULL",
                          style: TextStyle(
                            color: vacancy > 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Occupancy Stats Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("TOTAL ROOMS", h['totalRooms'] ?? 0),
                        _buildStatItem("TOTAL MEMBERS", h['totalMembers'] ?? h['totalCapacity'] ?? 0),
                        _buildStatItem("VACANCY", h['vacancy'] ?? 0),
                        _buildStatItem("VACANT ROOMS", h['vacantRooms'] ?? 0),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _launchMaps,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFF6366F1), size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(address,
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mini Map
                  if (hostel['location']?['coordinates'] != null &&
                      (hostel['location']['coordinates'] as List).length == 2)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            (hostel['location']['coordinates'][1] as num).toDouble(),
                            (hostel['location']['coordinates'][0] as num).toDouble(),
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId("hostel_loc"),
                            position: LatLng(
                              (hostel['location']['coordinates'][1] as num).toDouble(),
                              (hostel['location']['coordinates'][0] as num).toDouble(),
                            ),
                          ),
                        },
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: false,
                        style:
                            "[{\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#212121\"}]},{\"elementType\":\"labels.icon\",\"stylers\":[{\"visibility\":\"off\"}]},{\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"elementType\":\"labels.text.stroke\",\"stylers\":[{\"color\":\"#212121\"}]},{\"featureType\":\"administrative\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"administrative.country\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#9e9e9e\"}]},{\"featureType\":\"administrative.land_parcel\",\"stylers\":[{\"visibility\":\"off\"}]},{\"featureType\":\"administrative.locality\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#bdbdbd\"}]},{\"featureType\":\"poi\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#181818\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#616161\"}]},{\"featureType\":\"poi.park\",\"elementType\":\"labels.text.stroke\",\"stylers\":[{\"color\":\"#1b1b1b\"}]},{\"featureType\":\"road\",\"elementType\":\"geometry.fill\",\"stylers\":[{\"color\":\"#2c2c2c\"}]},{\"featureType\":\"road\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#8a8a8a\"}]},{\"featureType\":\"road.arterial\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#373737\"}]},{\"featureType\":\"road.highway\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#3c3c3c\"}]},{\"featureType\":\"road.highway.controlled_access\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#4e4e4e\"}]},{\"featureType\":\"road.local\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#616161\"}]},{\"featureType\":\"transit\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#757575\"}]},{\"featureType\":\"water\",\"elementType\":\"geometry\",\"stylers\":[{\"color\":\"#000000\"}]},{\"featureType\":\"water\",\"elementType\":\"labels.text.fill\",\"stylers\":[{\"color\":\"#3d3d3d\"}]}]",
                      ),
                    ),

                  const SizedBox(height: 32),

                  const SizedBox(height: 32),
                  const Text("ROOM TYPES & PRICING",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.indigoAccent,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  if (h['rooms'] != null && (h['rooms'] as List).isNotEmpty)
                    Column(
                      children: (h['rooms'] as List).map((r) {
                        final type = r['type'] ?? 'shared';
                        final sharing = r['sharingCount'] ?? 1;
                        final label = type == 'single' ? 'Single Room' : '$sharing Shared Room';
                        final rent = r['rent'] ?? 0;
                        final roomVac = r['vacancy'] ?? 0;
                        final totalR = r['totalRooms'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$roomVac vacancies in $totalR rooms",
                                    style: TextStyle(
                                        color: roomVac > 0 ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              Text("₹$rent",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1))),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Responsive(
                      mobile: Column(
                        children: [
                          Row(
                            children: [
                              _priceCard("Single Room", rentS.toString()),
                              const SizedBox(width: 12),
                              _priceCard("Shared Room", rentShared.toString()),
                            ],
                          ),
                        ],
                      ),
                      desktop: Row(
                        children: [
                          _priceCard("Single Room", rentS.toString()),
                          const SizedBox(width: 16),
                          _priceCard("Shared Room", rentShared.toString()),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Contact Info
                  _infoTile(Icons.person, "Owner", owner),
                  const SizedBox(height: 12),
                  _infoTile(Icons.phone, "Contact", contact,
                      onAction: () => _makeCall(contact)),

                  const SizedBox(height: 32),

                  // Facilities
                  const Text("FACILITIES",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.indigoAccent,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  if (facilities.isEmpty)
                    const Text("No facilities listed",
                        style: TextStyle(color: Colors.white54))
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: facilities
                          .map((f) => _facilityChip(f.toString()))
                          .toList(),
                    ),

                  const SizedBox(height: 48),

                  if (isReviewMode)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success = await HostelService.approvePublishRequest(hostelId);
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Hostel Approved and Published!")),
                                  );
                                  Navigator.pop(context, true); // returns true to signal refresh
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Failed to approve hostel.")),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 28),
                            label: const Text(
                              "APPROVE & PUBLISH",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: Colors.green.withOpacity(0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showRejectDialog(context, hostelId);
                            },
                            icon: const Icon(Icons.cancel_rounded, size: 28),
                            label: const Text(
                              "REJECT / SEND TO REVIEW",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: Colors.orange.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (isAdminView)
                    const SizedBox.shrink() // Removed EDIT HOSTEL button as per request
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchMaps,
                            icon: const Icon(Icons.map_rounded),
                            label: const Text("OPEN IN MAPS"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              side: const BorderSide(color: Color(0xFF334155)),
                            ),
                          ),
                        ),
                        if (showBooking) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingFormScreen(hostel: hostel),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded),
                              label: const Text("BOOK NOW"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor:
                                    const Color(0xFF8B5CF6).withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(String label, String price) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text("₹$price",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1))),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {VoidCallback? onAction}) {
    return InkWell(
      onTap: onAction,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            if (onAction != null)
              const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _facilityChip(String label) {
    IconData icon = Icons.check_circle_outline;
    if (label.toLowerCase().contains("wifi")) icon = Icons.wifi;
    if (label.toLowerCase().contains("ac")) icon = Icons.ac_unit;
    if (label.toLowerCase().contains("food")) icon = Icons.restaurant;
    if (label.toLowerCase().contains("laundry"))
      icon = Icons.local_laundry_service;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: Colors.grey),
        ),
      ],
    );
  }
}
