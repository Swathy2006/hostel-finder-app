import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/hostel_service.dart';
import '../models/room_entry.dart';
import 'map_picker.dart';

class CreateHostelScreen extends StatefulWidget {
  const CreateHostelScreen({super.key});

  @override
  State<CreateHostelScreen> createState() => _CreateHostelScreenState();
}

// RoomEntry now imported from models/room_entry.dart

class _CreateHostelScreenState extends State<CreateHostelScreen> {
  // Controllers
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final ownerNameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final totalRoomsCtrl = TextEditingController();
  final capacityCtrl = TextEditingController();
  final facilityCtrl = TextEditingController();

  List<String> facilities = [];
  List<RoomEntry> rooms = [RoomEntry(type: "single")];

  double? lat;
  double? lng;
  bool loading = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];

  Future<void> selectLocation() async {
    final result = await Navigator.push<LatLng>(
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
            "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
      });
    }
  }

  void addFacility() {
    final text = facilityCtrl.text.trim();
    if (text.isNotEmpty && !facilities.contains(text)) {
      setState(() {
        facilities.add(text);
      });
      facilityCtrl.clear();
    }
  }

  void removeFacility(String label) {
    setState(() {
      facilities.remove(label);
    });
  }

  Future<void> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideos.add(video);
      });
    }
  }

  Future<void> saveHostel() async {
    if (nameCtrl.text.isEmpty ||
        addressCtrl.text.isEmpty ||
        ownerNameCtrl.text.isEmpty ||
        contactCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (AuthService.currentUserId == null ||
        AuthService.currentUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      double rentSingle = 0;
      double rentShared = 0;
      int totalVacancy = 0;

      for (var r in rooms) {
        final rent = double.tryParse(r.rentCtrl.text) ?? 0;
        final vac = int.tryParse(r.vacancyCtrl.text) ?? 0;

        totalVacancy += vac;

        if (r.type == "single") rentSingle = rent;
        if (r.type == "shared") rentShared = rent;
      }

      // Convert XFiles to paths
      List<String> imagePaths = _selectedImages.map((e) => e.path).toList();
      List<String> videoPaths = _selectedVideos.map((e) => e.path).toList();

      final success = await HostelService.createHostel(
        nameCtrl.text.trim(),
        addressCtrl.text.trim(),
        ownerNameCtrl.text.trim(),
        contactCtrl.text.trim(),
        rentSingle,
        rentShared,
        totalVacancy,
        AuthService.currentUserId ?? "",
        lat ?? 0,
        lng ?? 0,
        facilities,
        imagePaths,
        videoPaths,
        totalRooms: int.tryParse(totalRoomsCtrl.text) ?? 0,
        totalCapacity: int.tryParse(capacityCtrl.text) ?? 0,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Hostel Created Successfully!")),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  /// Helper to build sleek aesthetic cards wrapping form sections
  Widget _buildSectionCard(
      {required String title, required Widget child, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 22, 78, 168),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
        border: Border.all(
          color: const Color.fromARGB(255, 15, 56, 113),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 62, 3, 3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget roomWidget(int index) {
    final r = rooms[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Sharing Type",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: r.type == 'single'
                            ? 'single'
                            : '${r.sharingCount}_shared',
                        dropdownColor: const Color(0xFF1E293B),
                        items: [
                          const DropdownMenuItem(
                              value: "single", child: Text("Single")),
                          const DropdownMenuItem(
                              value: "2_shared", child: Text("2 Shared")),
                          const DropdownMenuItem(
                              value: "3_shared", child: Text("3 Shared")),
                          const DropdownMenuItem(
                              value: "4_shared", child: Text("4 Shared")),
                          const DropdownMenuItem(
                              value: "5_shared", child: Text("5 Shared")),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            if (val == 'single') {
                              r.type = 'single';
                              r.sharingCount = 1;
                            } else {
                              r.type = 'shared';
                              r.sharingCount = int.parse(val.split('_')[0]);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: r.rentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rent / Month',
                    prefixIcon: Icon(Icons.currency_rupee, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: r.totalRoomsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Rooms',
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: r.vacancyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Vacancies',
                    prefixIcon: Icon(Icons.bed),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() => rooms.removeAt(index));
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text("Remove",
                  style: TextStyle(color: Colors.redAccent)),
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
        title: const Text("Create New Hostel"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Elegant Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F172A),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 1. Basic Info Card
                _buildSectionCard(
                  title: "Basic Details",
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Hostel Name",
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ownerNameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Owner / Manager Name",
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contactCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Contact Number",
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: totalRoomsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Total Number of Rooms",
                          prefixIcon: Icon(Icons.meeting_room_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: capacityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Total Capacity (People)",
                          prefixIcon: Icon(Icons.people_rounded),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 2. Location Card
                _buildSectionCard(
                  title: "Location",
                  icon: Icons.location_on_rounded,
                  child: Column(
                    children: [
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: "Google Maps Link",
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.map_rounded),
                          label: const Text("Pin Location on Map"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF6366F1), // Indigo Primary
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: selectLocation,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 3. Facilities
                _buildSectionCard(
                  title: "Facilities",
                  icon: Icons.star_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: facilityCtrl,
                              decoration: const InputDecoration(
                                labelText: "Add Facility (e.g., WiFi, AC)",
                                prefixIcon: Icon(Icons.add_task_rounded),
                              ),
                              onSubmitted: (_) => addFacility(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: addFacility,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: facilities.map((f) {
                          return Chip(
                            label: Text(f,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFF334155),
                            deleteIconColor: const Color(0xFFEF4444),
                            onDeleted: () => removeFacility(f),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                /// 4. Rooms & Pricing
                _buildSectionCard(
                  title: "Rooms & Pricing",
                  icon: Icons.meeting_room_rounded,
                  child: Column(
                    children: [
                      Column(
                        children: List.generate(
                          rooms.length,
                          (i) => roomWidget(i),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Color(0xFF8B5CF6)),
                        label: const Text("Add Another Room Type",
                            style: TextStyle(color: Color(0xFF8B5CF6))),
                        onPressed: () {
                          setState(() {
                            rooms.add(RoomEntry(type: "single"));
                          });
                        },
                      ),
                    ],
                  ),
                ),

                /// 5. Media
                _buildSectionCard(
                  title: "Media Collection",
                  icon: Icons.perm_media_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickImages,
                              icon: const Icon(Icons.photo_library_rounded,
                                  color: Colors.white),
                              label: const Text("Images",
                                  style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF475569)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickVideo,
                              icon: const Icon(Icons.video_library_rounded,
                                  color: Colors.white),
                              label: const Text("Video",
                                  style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF475569)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text("Selected Images:",
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        right: 12, top: 8),
                                    width: 140,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFF475569)),
                                      image: DecorationImage(
                                        image: FileImage(
                                            File(_selectedImages[index].path)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 4,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close_rounded,
                                            color: Colors.redAccent, size: 20),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        onPressed: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      if (_selectedVideos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text("Selected Videos:",
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        Column(
                          children:
                              _selectedVideos.asMap().entries.map((entry) {
                            int idx = entry.key;
                            XFile video = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFF334155)),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.videocam_rounded,
                                    color: Color(0xFF6366F1)),
                                title: Text(video.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _selectedVideos.removeAt(idx);
                                    });
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: loading ? null : saveHostel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6), // Violet 500
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Publish Hostel Listing",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
