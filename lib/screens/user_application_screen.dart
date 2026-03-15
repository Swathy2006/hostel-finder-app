import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/application_service.dart';
import 'map_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserApplicationScreen extends StatefulWidget {
  const UserApplicationScreen({super.key});

  @override
  State<UserApplicationScreen> createState() => _UserApplicationScreenState();
}

class _UserApplicationScreenState extends State<UserApplicationScreen> {
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final ownerNameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  // Basic granular stats at application level

  String? district;
  String? city;
  double? lat;
  double? lng;
  bool loading = false;

  final Map<String, List<String>> kerelaDistrictsAndCities = {
    "Alappuzha": ["Alappuzha", "Chengannur", "Cherthala", "Haripad", "Kayamkulam", "Mavelikkara"],
    "Ernakulam": ["Kochi", "Aluva", "Angamaly", "Kalamassery", "Kothamangalam", "Muvattupuzha", "North Paravur", "Perumbavoor", "Thrippunithura"],
    "Idukki": ["Thodupuzha", "Kattappana"],
    "Kannur": ["Kannur", "Anthoor", "Iritty", "Kuthuparamba", "Mattannur", "Payyanur", "Sreekandapuram", "Thalassery", "Taliparamba"],
    "Kasaragod": ["Kasaragod", "Kanhangad", "Nileshwaram"],
    "Kollam": ["Kollam", "Karunagappalli", "Kottarakkara", "Paravur", "Pathanapuram", "Punalur"],
    "Kottayam": ["Kottayam", "Changanassery", "Ettumanoor", "Erattupetta", "Pala", "Vaikom"],
    "Kozhikode": ["Kozhikode", "Feroke", "Koduvally", "Koyilandy", "Payyoli", "Ramanattukara", "Vadakara"],
    "Malappuram": ["Malappuram", "Kondotty", "Kottakkal", "Manjeri", "Nilambur", "Parappanangadi", "Perinthalmanna", "Ponnani", "Tanur", "Tirur", "Tirurangadi", "Valanchery"],
    "Palakkad": ["Palakkad", "Cherpulassery", "Chittur-Thathamangalam", "Mannarkkad", "Ottapalam", "Pattambi", "Shoranur"],
    "Pathanamthitta": ["Pathanamthitta", "Adoor", "Pandalam", "Thiruvalla"],
    "Thiruvananthapuram": ["Thiruvananthapuram", "Attingal", "Nedumangad", "Neyyattinkara", "Varkala"],
    "Thrissur": ["Thrissur", "Chalakudy", "Chavakkad", "Guruvayur", "Irinjalakuda", "Kodungallur", "Kunnamkulam", "Wadakkancherry"],
    "Wayanad": ["Kalpetta", "Mananthavady", "Sulthan Bathery"],
  };

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    ownerNameCtrl.dispose();
    contactCtrl.dispose();
    super.dispose();
  }

  Future<void> submitApplication() async {
    if (nameCtrl.text.isEmpty ||
        addressCtrl.text.isEmpty ||
        ownerNameCtrl.text.isEmpty ||
        contactCtrl.text.isEmpty ||
        district == null ||
        city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (contactCtrl.text.trim().length != 10 || 
        int.tryParse(contactCtrl.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number must be exactly 10 digits")),
      );
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final error = await ApplicationService.submitApplication(
        userId: userId,
        hostelName: nameCtrl.text.trim(),
        ownerName: ownerNameCtrl.text.trim(),
        email: "N/A", // Email fallback
        phone: contactCtrl.text.trim(),
        district: district!,
        city: city!,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Application Submitted Successfully!")),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectLocation() async {
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

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isNumber = false, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: isNumber ? 10 : null,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Hostel Application"),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Submit Basic Details",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Fill in the core info. Once an admin approves this, you will be able to add deep details like photos and specific sharing room rents.",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            _buildTextField("Hostel Name", Icons.apartment, nameCtrl),
            _buildTextField("Owner Name", Icons.person, ownerNameCtrl),
            _buildTextField("Contact Number", Icons.phone, contactCtrl, isNumber: true),

            DropdownButtonFormField<String>(
              value: district,
              hint: const Text("Select District", style: TextStyle(color: Colors.white70)),
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.map, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: kerelaDistrictsAndCities.keys.map((d) => DropdownMenuItem<String>(
                value: d, 
                child: Text(d)
              )).toList(),
              onChanged: (val) {
                setState(() {
                  district = val;
                  city = null; // reset city
                });
              },
            ),
            const SizedBox(height: 16),

            if (district != null)
              DropdownButtonFormField<String>(
                value: city,
                hint: const Text("Select City", style: TextStyle(color: Colors.white70)),
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_city, color: Colors.blueAccent),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: kerelaDistrictsAndCities[district]!.map((c) => DropdownMenuItem<String>(
                  value: c, 
                  child: Text(c)
                )).toList(),
                onChanged: (val) => setState(() => city = val),
              ),
            const SizedBox(height: 16),

            _buildTextField("Address / GPS Link", Icons.location_on, addressCtrl, readOnly: true, onTap: _selectLocation),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Application", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
