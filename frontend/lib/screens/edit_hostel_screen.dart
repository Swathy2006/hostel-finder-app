import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../services/hostel_service.dart';
import '../models/room_entry.dart';
import 'map_picker.dart';

class EditHostelScreen extends StatefulWidget {
  final Map<String, dynamic> hostel;
  final String? prefilledDistrict;
  final String? prefilledCity;

  const EditHostelScreen({
    super.key,
    required this.hostel,
    this.prefilledDistrict,
    this.prefilledCity,
  });

  @override
  State<EditHostelScreen> createState() => _EditHostelScreenState();
}

class _EditHostelScreenState extends State<EditHostelScreen> {
  // Controllers
  late TextEditingController nameCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController ownerNameCtrl;
  late TextEditingController contactCtrl;
  final facilityCtrl = TextEditingController();

  List<String> facilities = [];
  List<RoomEntry> rooms = [];

  double? lat;
  double? lng;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];
  List<String> _existingImages = [];
  List<String> _existingVideos = [];

  final totalRoomsCtrl = TextEditingController();
  final capacityCtrl = TextEditingController();
  final vacantRoomsCtrl = TextEditingController();

  String selectedGender = "mixed";

  String? district;
  String? city;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    final h = widget.hostel;

    nameCtrl = TextEditingController(text: h['name'] ?? '');
    addressCtrl = TextEditingController(text: h['address'] ?? '');
    ownerNameCtrl = TextEditingController(text: h['ownerName'] ?? '');
    contactCtrl = TextEditingController(text: h['contactNo'] ?? '');

    district = widget.prefilledDistrict ?? h['district'];
    city = widget.prefilledCity ?? h['city'];

    if (h['facilities'] is List) {
      facilities = List<String>.from(h['facilities']);
    }

    final coords = h['location']?['coordinates'];

    if (coords is List && coords.length >= 2) {
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    }

    rooms = [];

    // Map existing data to RoomEntries
    if (h['rooms'] != null && (h['rooms'] as List).isNotEmpty) {
      for (var r in (h['rooms'] as List)) {
        String sharingVal = (r['sharingCount'] ?? 1).toString();
        // Ensure sharingVal is within the supported dropdown range (1-5)
        if (!['1', '2', '3', '4', '5'].contains(sharingVal)) {
          sharingVal = '2'; // Default to 2 if out of range to prevent crash
        }

        rooms.add(
          RoomEntry(
            type: r['type'] ?? 'single',
            sharing: sharingVal,
          )
            ..rentCtrl.text = (r['rent'] ?? 0).toString()
            ..vacancyCtrl.text = (r['vacancy'] ?? 0).toString()
            ..totalRoomsCtrl.text = (r['totalRooms'] ?? 0).toString(),
        );
      }
    } else {
      // Fallback to legacy fields
      if (h['rentSingle'] != null && (h['rentSingle'] as num) > 0) {
        rooms.add(
          RoomEntry(type: 'single')
            ..rentCtrl.text = h['rentSingle'].toString()
            ..vacancyCtrl.text = (h['vacancySingle'] ?? 0).toString()
            ..totalRoomsCtrl.text = (h['totalRoomsSingle'] ?? 0).toString(),
        );
      }

      if (h['rentShared'] != null && (h['rentShared'] as num) > 0) {
        final shCount = h['sharedCount'] ?? 2;
        rooms.add(
          RoomEntry(type: 'shared', sharing: shCount.toString())
            ..rentCtrl.text = h['rentShared'].toString()
            ..vacancyCtrl.text = (h['vacancyShared'] ?? 0).toString()
            ..totalRoomsCtrl.text = (h['totalRoomsShared'] ?? 0).toString(),
        );
      }
    }

    if (rooms.isEmpty) {
      rooms.add(RoomEntry(type: 'single'));
    }

    if (h['images'] is List) {
      _existingImages = List<String>.from(h['images']);
    }

    if (h['videos'] is List) {
      _existingVideos = List<String>.from(h['videos']);
    }

    totalRoomsCtrl.text = (h['totalRooms'] ?? 0).toString();
    capacityCtrl.text =
        (h['totalMembers'] ?? h['totalCapacity'] ?? 0).toString();
    vacantRoomsCtrl.text = (h['vacantRooms'] ?? 0).toString();
    selectedGender = h['gender'] ?? "Mixed";
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    ownerNameCtrl.dispose();
    contactCtrl.dispose();
    facilityCtrl.dispose();

    for (var r in rooms) {
      r.rentCtrl.dispose();
      r.vacancyCtrl.dispose();
      r.totalRoomsCtrl.dispose();
      r.sharingCountCtrl.dispose();
    }
    totalRoomsCtrl.dispose();
    capacityCtrl.dispose();
    vacantRoomsCtrl.dispose();

    super.dispose();
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

  Future<void> saveChanges() async {
    if (nameCtrl.text.isEmpty ||
        addressCtrl.text.isEmpty ||
        ownerNameCtrl.text.isEmpty ||
        contactCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final phone = contactCtrl.text.trim();
    if (phone.length != 10 || int.tryParse(phone) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number must be exactly 10 digits")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final Map<String, dynamic> changes = {};

      changes['name'] = nameCtrl.text.trim();
      changes['address'] = addressCtrl.text.trim();
      changes['ownerName'] = ownerNameCtrl.text.trim();
      changes['contactNo'] = contactCtrl.text.trim();
      changes['facilities'] = facilities;

      if (district != null) changes['district'] = district;
      if (city != null) changes['city'] = city;

      if (lat != null && lng != null) {
        changes['lat'] = lat;
        changes['lng'] = lng;
      }

      double rentSingle = 0;
      double rentShared = 0;
      int totalVac = 0;

      for (var r in rooms) {
        final rent = double.tryParse(r.rentCtrl.text.trim()) ?? 0;
        final vac = int.tryParse(r.vacancyCtrl.text.trim()) ?? 0;

        totalVac += vac;

        if (r.type == 'single') {
          if (rentSingle == 0 || (rent > 0 && rent < rentSingle)) {
            rentSingle = rent;
          }
        }
        if (r.type == 'shared') {
          if (rentShared == 0 || (rent > 0 && rent < rentShared)) {
            rentShared = rent;
          }
        }
      }

      changes['rentSingle'] = rentSingle;
      changes['rentShared'] = rentShared;
      changes['vacancy'] = totalVac;
      changes['rooms'] = rooms.map((r) => r.toJson()).toList();
      changes['totalRooms'] = int.tryParse(totalRoomsCtrl.text.trim()) ?? 0;
      changes['totalMembers'] = int.tryParse(capacityCtrl.text.trim()) ?? 0;
      changes['vacantRooms'] = int.tryParse(vacantRoomsCtrl.text.trim()) ?? 0;
      changes['gender'] = selectedGender;

      // Note: Backend might need update to handle granular rooms, existing vs new images, etc.
      // Filtering out empty images
      List<String> combinedImages = [..._existingImages];
      List<String> newImagePaths = _selectedImages.map((e) => e.path).toList();

      List<String> combinedVideos = [..._existingVideos];
      List<String> newVideoPaths = _selectedVideos.map((e) => e.path).toList();

      changes['images'] = combinedImages;
      changes['videos'] = combinedVideos;
      changes['newImagePaths'] = newImagePaths;
      changes['newVideoPaths'] = newVideoPaths;

      final bool isPublished = widget.hostel['isApproved'] == true;
      bool success;

      if (isPublished) {
        success = await HostelService.submitEditRequest(
          widget.hostel['_id'],
          changes,
        );
      } else {
        success = await HostelService.updateHostel(
          widget.hostel['_id'],
          changes,
        );
      }

      setState(() => loading = false);

      if (success) {
        if (mounted) {
          final msg = isPublished
              ? "Edit request submitted for admin approval!"
              : "Hostel updated successfully!";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Failed to submit changes. Please try again.")),
          );
        }
      }
    } catch (e) {
      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating hostel: $e")),
        );
      }
    }
  }

  /// Helper to build sleek aesthetic cards wrapping form sections (matching Create screen)
  Widget _buildSectionCard(
      {required String title, required Widget child, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
        border: Border.all(
          color: const Color(0xFF334155),
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
                    color: Colors.white,
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

  Widget _mediaThumbnail(String path,
      {required bool isUrl, required VoidCallback onDelete}) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8),
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF475569)),
            image: DecorationImage(
              image: isUrl
                  ? NetworkImage(path) as ImageProvider
                  : FileImage(File(path)),
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
              onPressed: onDelete,
            ),
          ),
        ),
      ],
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
                    const Text("Room Type",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: r.type,
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem<String>(
                              value: "single", child: Text("Single")),
                          DropdownMenuItem<String>(
                              value: "shared", child: Text("Shared")),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            r.type = val;
                            if (val == 'single') {
                              r.sharingCountCtrl.text = '1';
                            } else if (r.sharingCountCtrl.text == '1') {
                              r.sharingCountCtrl.text = '2';
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (r.type == 'shared') ...[
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: r.sharingCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sharing Count',
                      prefixIcon: Icon(Icons.groups_rounded, size: 18),
                    ),
                  ),
                ),
              ],
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
        title: const Text('Edit Hostel'),
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
                          labelText: 'Hostel Name',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: const InputDecoration(
                          labelText: "Gender Category",
                          prefixIcon: Icon(Icons.people_outline_rounded),
                        ),
                        dropdownColor: const Color(0xFF1E293B),
                        items: ["Boys", "Girls", "Mixed"]
                            .map((e) => DropdownMenuItem<String>(
                                  value: e,
                                  child: Text(e,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedGender = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ownerNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Owner / Manager Name',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contactCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: totalRoomsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Number of Rooms',
                          prefixIcon: Icon(Icons.meeting_room_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: capacityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Capacity (People)',
                          prefixIcon: Icon(Icons.people_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: vacantRoomsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Vacant Number of Rooms',
                          prefixIcon: Icon(Icons.meeting_room_outlined),
                        ),
                      ),
                    ],
                  ),
                ),

                /// X. Pre-Selected / Current Location Info
                if (district != null && city != null)
                  _buildSectionCard(
                    title: "Selected Region",
                    icon: Icons.map_rounded,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "District: $district\nCity: $city",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF6366F1), size: 32),
                      ],
                    ),
                  ),

                /// 2. Location Card
                _buildSectionCard(
                  title: "Location Link",
                  icon: Icons.location_on_rounded,
                  child: Column(
                    children: [
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Google Maps Link',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.map_rounded),
                          label: const Text("Update Pinned Location"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF6366F1), // Indigo Primary
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final result = await Navigator.push<LatLng?>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MapPicker()),
                            );

                            if (result != null) {
                              setState(() {
                                lat = result.latitude;
                                lng = result.longitude;
                                addressCtrl.text =
                                    "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                /// 3. Facilities Card
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
                        children: rooms.asMap().entries.map((entry) {
                          return roomWidget(entry.key);
                        }).toList(),
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

                /// 5. Media Section
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
                              label: const Text("Add More Images",
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
                      if (_existingImages.isNotEmpty ||
                          _selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text("Current Images:",
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Existing URLs
                              ..._existingImages.asMap().entries.map((entry) {
                                int idx = entry.key;
                                String url = entry.value;
                                return _mediaThumbnail(
                                  url,
                                  isUrl: true,
                                  onDelete: () => setState(
                                      () => _existingImages.removeAt(idx)),
                                );
                              }),
                              // New selected files
                              ..._selectedImages.asMap().entries.map((entry) {
                                int idx = entry.key;
                                XFile file = entry.value;
                                return _mediaThumbnail(
                                  file.path,
                                  isUrl: false,
                                  onDelete: () => setState(
                                      () => _selectedImages.removeAt(idx)),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickVideo,
                              icon: const Icon(Icons.video_library_rounded,
                                  color: Colors.white),
                              label: const Text("Add More Videos",
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
                      if (_existingVideos.isNotEmpty ||
                          _selectedVideos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text("Videos:",
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            ..._existingVideos.asMap().entries.map((entry) {
                              int idx = entry.key;
                              return ListTile(
                                leading: const Icon(Icons.videocam_rounded,
                                    color: Color(0xFF6366F1)),
                                title: Text(entry.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () => setState(
                                      () => _existingVideos.removeAt(idx)),
                                ),
                              );
                            }),
                            ..._selectedVideos.asMap().entries.map((entry) {
                              int idx = entry.key;
                              return ListTile(
                                leading: const Icon(Icons.videocam_rounded,
                                    color: Color(0xFF8B5CF6)),
                                title: Text(entry.value.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () => setState(
                                      () => _selectedVideos.removeAt(idx)),
                                ),
                              );
                            }),
                          ],
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
                    onPressed: loading ? null : saveChanges,
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
                        : Text(
                            widget.hostel['isApproved'] == true
                                ? "Submit for Change"
                                : "Save Changes",
                            style: const TextStyle(
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
