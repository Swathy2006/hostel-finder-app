import 'package:flutter/material.dart';
import '../utils/location_data.dart';
import '../utils/image_data.dart';
import 'city_selection_screen.dart';

class MyHostelsScreen extends StatelessWidget {
  final bool hideAppBar;
  const MyHostelsScreen({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final districts = keralaDistrictsAndCities.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: hideAppBar ? null : AppBar(
        title: const Text(
          "Manage Published Hostels",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16, left: 4),
              child: Text(
                "Select a district to manage hostels",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: districts.length,
                itemBuilder: (context, index) {
                  final districtName = districts[index];
                  final imageUrl = getDistrictImage(districtName);

                  return _buildDistrictCard(context, districtName, imageUrl);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictCard(BuildContext context, String name, String bgImage) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CitySelectionScreen(
                  district: name,
                  isAdminView: true,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.network(
                bgImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF334155)),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0F172A).withOpacity(0.95),
                      const Color(0xFF0F172A).withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Text Content
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.2), // Purple tint for admin
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "Manage in Cities",
                            style: TextStyle(
                              color: Color(0xFFC4B5FD),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFFC4B5FD), size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

