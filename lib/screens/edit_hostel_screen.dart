import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/hostel_service.dart';
import '../models/room_entry.dart';
import 'map_picker.dart';

class EditHostelScreen extends StatefulWidget {
  final Map<String, dynamic> hostel;
  const EditHostelScreen({super.key, required this.hostel});

  @override
  State<EditHostelScreen> createState() => _EditHostelScreenState();
}

class _EditHostelScreenState extends State<EditHostelScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController addressCtrl;
  List<RoomEntry> rooms = [];
  double? lat;
  double? lng;
  List<TextEditingController> imageCtrls = [];
  List<TextEditingController> videoCtrls = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final h = widget.hostel;
    nameCtrl = TextEditingController(text: h['name'] ?? '');
    addressCtrl = TextEditingController(text: h['address'] ?? '');
    final coords = h['location']?['coordinates'];
    if (coords is List && coords.length >= 2) {
      lng = coords[0] as double;
      lat = coords[1] as double;
    }
    // build rooms from rentSingle/rentShared/vacancy
    rooms = [];
    if (h['rentSingle'] != null) {
      rooms.add(
        RoomEntry(type: 'single')..rentCtrl.text = h['rentSingle'].toString(),
      );
    }
    if (h['rentShared'] != null) {
      rooms.add(
        RoomEntry(type: 'shared')..rentCtrl.text = h['rentShared'].toString(),
      );
    }
    // vacancy total not used per-room here
    if (h['vacancy'] != null) {
      final vacAll = h['vacancy'].toString();
      if (rooms.isNotEmpty) {
        rooms[0].vacancyCtrl.text = vacAll;
      }
    }
    // images/videos
    if (h['images'] is List) {
      for (var url in h['images']) {
        final ctrl = TextEditingController(text: url);
        imageCtrls.add(ctrl);
      }
    }
    if (h['videos'] is List) {
      for (var url in h['videos']) {
        final ctrl = TextEditingController(text: url);
        videoCtrls.add(ctrl);
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    for (var r in rooms) {
      r.rentCtrl.dispose();
      r.vacancyCtrl.dispose();
    }
    for (var c in imageCtrls) {
      c.dispose();
    }
    for (var c in videoCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> saveChanges() async {
    if (nameCtrl.text.isEmpty || addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Name & address required")));
      return;
    }
    setState(() => loading = true);
    try {
      final Map<String, dynamic> changes = {};
      changes['name'] = nameCtrl.text.trim();
      changes['address'] = addressCtrl.text.trim();
      if (lat != null && lng != null) {
        changes['lat'] = lat;
        changes['lng'] = lng;
      }
      // rents / vacancy
      double rentSingle = 0;
      double rentShared = 0;
      int totalVac = 0;
      for (var r in rooms) {
        final rent = double.tryParse(r.rentCtrl.text.trim()) ?? 0;
        final vac = int.tryParse(r.vacancyCtrl.text.trim()) ?? 0;
        totalVac += vac;
        if (r.type == 'single') rentSingle = rent;
        if (r.type == 'shared') rentShared = rent;
      }
      changes['rentSingle'] = rentSingle;
      changes['rentShared'] = rentShared;
      changes['vacancy'] = totalVac;
      // media
      changes['images'] = imageCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      changes['videos'] = videoCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final success = await HostelService.updateHostel(
        widget.hostel['_id'],
        changes,
      );
      setState(() => loading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hostel updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating hostel: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Hostel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Hostel Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<LatLng?>(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPicker()),
                );
                if (result != null) {
                  setState(() {
                    lat = result.latitude;
                    lng = result.longitude;
                    addressCtrl.text =
                        "${result.latitude}, ${result.longitude}";
                  });
                }
              },
              icon: const Icon(Icons.map_rounded),
              label: const Text('Pick on map'),
            ),
            const SizedBox(height: 16),
            Column(
              children: rooms.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: r.type,
                        items: const [
                          DropdownMenuItem(
                            value: 'single',
                            child: Text('Single'),
                          ),
                          DropdownMenuItem(
                            value: 'shared',
                            child: Text('Shared'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => r.type = val);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: r.rentCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rent'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: r.vacancyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Vacancy',
                          ),
                        ),
                      ),
                      if (rooms.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => rooms.removeAt(idx));
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => rooms.add(RoomEntry(type: 'single')));
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add room type'),
              ),
            ),
            const SizedBox(height: 16),
            _buildMediaSection('Images', imageCtrls),
            const SizedBox(height: 16),
            _buildMediaSection('Videos', videoCtrls),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: loading ? null : saveChanges,
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(String label, List<TextEditingController> ctrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Column(
          children: ctrls.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c,
                    decoration: InputDecoration(labelText: '$label URL'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      c.dispose();
                      ctrls.removeAt(idx);
                    });
                  },
                ),
              ],
            );
          }).toList(),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() => ctrls.add(TextEditingController()));
            },
            icon: const Icon(Icons.add),
            label: Text('Add $label'),
          ),
        ),
      ],
    );
  }
}
