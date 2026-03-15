import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/hostel_service.dart';
import '../models/room_entry.dart';
import 'map_picker.dart';

class CreateHostelScreen extends StatefulWidget {
  const CreateHostelScreen({super.key});

  @override
  State<CreateHostelScreen> createState() => _CreateHostelScreenState();
}

class _CreateHostelScreenState extends State<CreateHostelScreen> {
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final ownerNameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final totalRoomsCtrl = TextEditingController();
  final capacityCtrl = TextEditingController();
  final vacantRoomsCtrl = TextEditingController();
  final facilityCtrl = TextEditingController();

  String? district;
  String? city;
  String selectedGender = "Mixed";

  List<String> facilities = [];
  List<RoomEntry> rooms = [RoomEntry(type: "single")];

  double? lat;
  double? lng;

  bool loading = false;
  bool _initialized = false;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];

  bool _isUserSubmission = false;
  String? _applicationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        district = args['district'];
        city = args['city'];
        _isUserSubmission = args['isUserSubmission'] ?? false;
        _applicationId = args['applicationId'];
        // Pre-fill if coming from application
        // nameCtrl.text = args['hostelName'] ?? "";
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    ownerNameCtrl.dispose();
    contactCtrl.dispose();
    totalRoomsCtrl.dispose();
    capacityCtrl.dispose();
    vacantRoomsCtrl.dispose();
    facilityCtrl.dispose();
    for (var r in rooms) {
      r.rentCtrl.dispose();
      r.vacancyCtrl.dispose();
      r.totalRoomsCtrl.dispose();
      r.sharingCountCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> selectLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPicker()),
    );
    if (result != null) {
      setState(() {
        lat = result.latitude;
        lng = result.longitude;
        addressCtrl.text = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
      });
    }
  }

  void addFacility() {
    final text = facilityCtrl.text.trim();
    if (text.isNotEmpty && !facilities.contains(text)) {
      setState(() => facilities.add(text));
      facilityCtrl.clear();
    }
  }

  void removeFacility(String label) {
    setState(() => facilities.remove(label));
  }

  Future<void> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _selectedImages.addAll(images));
  }

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) setState(() => _selectedVideos.add(video));
  }

  Future<void> saveHostel() async {
    if (nameCtrl.text.isEmpty || addressCtrl.text.isEmpty || ownerNameCtrl.text.isEmpty || contactCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    if (contactCtrl.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone number must be exactly 10 digits")));
      return;
    }

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please pin hostel location")));
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
        if (r.type == 'single' && (rentSingle == 0 || (rent > 0 && rent < rentSingle))) rentSingle = rent;
        if (r.type == 'shared' && (rentShared == 0 || (rent > 0 && rent < rentShared))) rentShared = rent;
      }

      final imagePaths = _selectedImages.map((e) => e.path).toList();
      final videoPaths = _selectedVideos.map((e) => e.path).toList();

      final error = await HostelService.createHostel(
        nameCtrl.text.trim(),
        addressCtrl.text.trim(),
        ownerNameCtrl.text.trim(),
        contactCtrl.text.trim(),
        rentSingle,
        rentShared,
        totalVacancy,
        AuthService.currentUserId ?? "",
        lat!,
        lng!,
        facilities,
        imagePaths,
        videoPaths,
        district: district ?? "",
        city: city ?? "",
        gender: selectedGender,
        totalRooms: int.tryParse(totalRoomsCtrl.text.trim()) ?? 0,
        totalMembers: int.tryParse(capacityCtrl.text.trim()) ?? 0,
        vacantRooms: int.tryParse(vacantRoomsCtrl.text.trim()) ?? 0,
        rooms: rooms.map((r) => r.toJson()).toList(),
        applicationId: _applicationId,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_isUserSubmission
                  ? "Application to Publish Submitted!"
                  : "Hostel Created Successfully!")));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(_isUserSubmission ? "Complete Publishing Form" : "Create New Hostel", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: loading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("BASIC INFORMATION"),
                _buildTextField("Hostel Name", Icons.apartment_rounded, nameCtrl),
                _buildTextField("Owner Name", Icons.person_rounded, ownerNameCtrl),
                _buildTextField("Contact Number", Icons.phone_rounded, contactCtrl, isPhone: true),
                const SizedBox(height: 24),

                _buildSectionHeader("LOCATION DETAILS"),
                _buildLocationPicker(),
                const SizedBox(height: 24),

                _buildSectionHeader("OCCUPANCY & GENDER"),
                _buildGenderDropdown(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField("Total Rooms", Icons.door_front_door_rounded, totalRoomsCtrl, isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField("Total Capacity", Icons.people_rounded, capacityCtrl, isNumber: true)),
                  ],
                ),
                _buildTextField("Current Vacant Rooms", Icons.event_available_rounded, vacantRoomsCtrl, isNumber: true),
                const SizedBox(height: 24),

                _buildSectionHeader("ROOM TYPES & PRICING"),
                ...rooms.map((r) => _buildRoomEntry(r)),
                TextButton.icon(
                  onPressed: () => setState(() => rooms.add(RoomEntry(type: "shared"))),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6366F1)),
                  label: const Text("Add Room Type", style: TextStyle(color: Color(0xFF6366F1))),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader("FACILITIES"),
                _buildFacilityInput(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: facilities.map((f) => Chip(
                    label: Text(f, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: const Color(0xFF1E293B),
                    onDeleted: () => removeFacility(f),
                    deleteIconColor: Colors.redAccent,
                  )).toList(),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader("MEDIA UPLOADS"),
                _buildMediaPickers(),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: loading ? null : saveHostel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                    ),
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isUserSubmission ? "SUBMIT FOR PUBLISHING" : "CREATE HOSTEL", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(title, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController ctrl, {bool isNumber = false, bool isPhone = false, bool readOnly = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: isNumber || isPhone ? TextInputType.number : TextInputType.text,
        maxLength: isPhone ? 10 : null,
        inputFormatters: isNumber || isPhone ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    return InkWell(
      onTap: selectLocation,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lat != null ? const Color(0xFF6366F1) : Colors.transparent),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lat != null ? "Location Pinned ($lat, $lng)" : "Tap to Pin Hostel Location",
                style: TextStyle(color: lat != null ? Colors.white : Colors.white54),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: selectedGender,
          dropdownColor: const Color(0xFF1E293B),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
          decoration: const InputDecoration(border: InputBorder.none),
          items: ["Mixed", "Boys", "Girls"].map((val) => DropdownMenuItem<String>(
            value: val, 
            child: Text(val, style: const TextStyle(color: Colors.white))
          )).toList(),
          onChanged: (val) => setState(() => selectedGender = val!),
        ),
      ),
    );
  }

  Widget _buildRoomEntry(RoomEntry r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B).withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF334155))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: r.type,
                  dropdownColor: const Color(0xFF1E293B),
                  items: ["single", "shared"].map((t) => DropdownMenuItem<String>(
                    value: t, 
                    child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12))
                  )).toList(),
                  onChanged: (val) => setState(() => r.type = val!),
                ),
              ),
              if (rooms.length > 1) IconButton(onPressed: () => setState(() => rooms.remove(r)), icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField("Rent/Month", Icons.payments_rounded, r.rentCtrl, isNumber: true)),
              const SizedBox(width: 8),
              if (r.type == 'shared') Expanded(child: _buildTextField("Sharing", Icons.groups_rounded, r.sharingCountCtrl, isNumber: true)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField("Total Rooms", Icons.meeting_room_rounded, r.totalRoomsCtrl, isNumber: true)),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField("Vacancies", Icons.check_circle_rounded, r.vacancyCtrl, isNumber: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityInput() {
    return Row(
      children: [
        Expanded(child: _buildTextField("E.g., Free Wi-Fi, Food", Icons.add_task_rounded, facilityCtrl)),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: addFacility, 
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _buildMediaPickers() {
    return Row(
      children: [
        Expanded(
          child: _mediaButton("PHOTOS (${_selectedImages.length})", Icons.add_photo_alternate_rounded, pickImages),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _mediaButton("VIDEOS (${_selectedVideos.length})", Icons.video_call_rounded, pickVideo),
        ),
      ],
    );
  }

  Widget _mediaButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

