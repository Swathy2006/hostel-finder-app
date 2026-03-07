import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/hostel_service.dart';
import '../services/auth_service.dart';
// note: location_service no longer needed for map picker
import 'map_picker.dart';

class CreateHostelScreen extends StatefulWidget {
  const CreateHostelScreen({super.key});

  @override
  State<CreateHostelScreen> createState() => _CreateHostelScreenState();
}

// helper class for dynamic room entries
class RoomEntry {
  String type;
  final TextEditingController rentCtrl = TextEditingController();
  final TextEditingController vacancyCtrl = TextEditingController();

  RoomEntry({this.type = 'single'});
}

class _CreateHostelScreenState extends State<CreateHostelScreen> {
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  // list of room type entries
  final List<RoomEntry> rooms = [RoomEntry(type: 'single')];

  double? lat;
  double? lng;

  List<TextEditingController> imageCtrls = [];
  List<TextEditingController> videoCtrls = [];

  bool loading = false;

  Future<void> saveHostel() async {
    if (nameCtrl.text.isEmpty || addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Name & address required")));
      return;
    }

    // ensure at least one room with valid data
    for (var r in rooms) {
      if (r.rentCtrl.text.trim().isEmpty || r.vacancyCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill rent/vacancy for each room")),
        );
        return;
      }
    }

    setState(() => loading = true);

    // convert rooms to values for API
    double rentSingle = 0;
    double rentShared = 0;
    int totalVacancy = 0;

    for (var r in rooms) {
      final rent = double.tryParse(r.rentCtrl.text.trim()) ?? 0;
      final vac = int.tryParse(r.vacancyCtrl.text.trim()) ?? 0;
      totalVacancy += vac;
      if (r.type == 'single') {
        rentSingle = rent;
      } else if (r.type == 'shared') {
        rentShared = rent;
      }
    }

    try {
      final ownerId = AuthService.currentUserId ?? "";
      final success = await HostelService.createHostel(
        nameCtrl.text.trim(),
        addressCtrl.text.trim(),
        rentSingle,
        rentShared,
        totalVacancy,
        ownerId,
        lat ?? 0.0,
        lng ?? 0.0,
        imageCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        videoCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

      setState(() => loading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hostel created successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create hostel")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error creating hostel: $e")));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Create New Hostel",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.add_home_work_rounded,
              size: 60,
              color: Color(0xFF6C63FF),
            ),
            const SizedBox(height: 16),
            const Text(
              "Hostel Details",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              "Provide information about the new listing",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Hostel Name",
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: "Complete Address",
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // open map picker screen
                            final result = await Navigator.push<LatLng?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MapPicker(),
                              ),
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
                          label: const Text("Pick on map"),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            lat != null
                                ? "Lat: ${lat!.toStringAsFixed(4)}, Lng: ${lng!.toStringAsFixed(4)}"
                                : "Location not set",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // dynamic room entries
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
                                  decoration: const InputDecoration(
                                    labelText: "Rent",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: r.vacancyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Vacancy",
                                  ),
                                ),
                              ),
                              if (rooms.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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
                        label: const Text("Add room type"),
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
                        onPressed: loading ? null : saveHostel,
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
                                "Publish Listing",
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
            ),
          ],
        ),
      ),
    );
  }
}
