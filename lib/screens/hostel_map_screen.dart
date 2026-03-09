import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/hostel_service.dart';

class HostelMapScreen extends StatefulWidget {
  const HostelMapScreen({super.key});

  @override
  State<HostelMapScreen> createState() => _HostelMapScreenState();
}

class _HostelMapScreenState extends State<HostelMapScreen> {
  List hostels = [];

  @override
  void initState() {
    super.initState();
    loadHostels();
  }

  Future<void> loadHostels() async {
    final data = await HostelService.getAllHostels();

    setState(() {
      hostels = data;
    });
  }

  Set<Marker> buildMarkers() {
    return hostels.map((h) {
      final coords = h['location']['coordinates'];

      return Marker(
        markerId: MarkerId(h['_id']),
        position: LatLng(coords[1], coords[0]),
        infoWindow: InfoWindow(
          title: h['name'],
          snippet: "₹${h['rentShared']}",
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hostels Map"),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(10.0462, 76.3264),
          zoom: 13,
        ),
        markers: buildMarkers(),
      ),
    );
  }
}
