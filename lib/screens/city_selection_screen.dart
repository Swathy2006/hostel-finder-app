import 'package:flutter/material.dart';
import '../utils/location_data.dart';
import '../utils/image_data.dart';
import 'city_hostels_screen.dart';

class CitySelectionScreen extends StatelessWidget {
  final String district;
  final bool isAdminView;

  const CitySelectionScreen({
    super.key, 
    required this.district,
    this.isAdminView = false,
  });

  @override
  Widget build(BuildContext context) {
    final cities = keralaDistrictsAndCities[district] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(district),
        centerTitle: true,
      ),
      body: cities.isEmpty
          ? const Center(child: Text('No cities available for this district.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final cityName = cities[index];
                final imageUrl = getCityImage(cityName);

                return _buildCityCard(context, cityName, imageUrl);
              },
            ),
    );
  }

  Widget _buildCityCard(BuildContext context, String name, String bgImage) {
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
                builder: (_) => CityHostelsScreen(
                  city: name,
                  isAdminView: isAdminView,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "View Hostels",
                            style: TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFF818CF8), size: 14),
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
