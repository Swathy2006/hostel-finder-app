import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_hostel_screen.dart';

class HostelDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final bool isAdminView;

  const HostelDetailsScreen({
    super.key,
    required this.hostel,
    this.isAdminView = false,
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
            expandedHeight: 300,
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
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
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

                  const SizedBox(height: 32),

                  // Pricing Section
                  const Text("PRICING",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.indigoAccent,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _priceCard("Single Room", rentS.toString()),
                      const SizedBox(width: 16),
                      _priceCard("Shared Room", rentShared.toString()),
                    ],
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

                  if (isAdminView)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditHostelScreen(hostel: hostel),
                            ),
                          );
                          // No state to refresh here as it pops back to admin_dashboard which handles it
                        },
                        icon: const Icon(Icons.edit_note_rounded, size: 28),
                        label: const Text(
                          "EDIT HOSTEL",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                        ),
                      ),
                    )
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makeCall(contact),
                            icon: const Icon(Icons.call_rounded),
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
}
