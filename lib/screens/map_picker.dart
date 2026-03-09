import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapPicker extends StatefulWidget {
  const MapPicker({super.key});

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  LatLng? selectedLocation;
  static const LatLng startLocation = LatLng(10.0462, 76.3264); // Kochi
  Set<Marker> markers = {};
  GoogleMapController? mapController;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placeSuggestions = [];
  bool _isSearching = false;

  // IMPORTANT: For production, do NOT hardcode API keys. Secure them.
  static const String _googleApiKey = "YOUR_GOOGLE_API_KEY_HERE";

  void pickLocation(LatLng position) {
    setState(() {
      selectedLocation = position;
      markers = {
        Marker(
          markerId: const MarkerId("hostel"),
          position: position,
          infoWindow: const InfoWindow(title: "Selected Location"),
        )
      };
    });
    _searchController.clear();
    setState(() {
      _placeSuggestions = [];
    });
  }

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placeSuggestions = [];
      });
      return;
    }

    String urlStr =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleApiKey';

    if (kIsWeb) {
      urlStr = 'https://corsproxy.io/?${Uri.encodeComponent(urlStr)}';
    }

    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'OK') {
          setState(() {
            _placeSuggestions = result['predictions'];
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Search failed: ${result['status']}')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search failed: Network error')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  Future<void> _getPlaceDetails(String placeId, String description) async {
    setState(() {
      _isSearching = true;
      _placeSuggestions = [];
      _searchController.text = description;
    });
    FocusManager.instance.primaryFocus?.unfocus();

    String urlStr =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey';

    if (kIsWeb) {
      urlStr = 'https://corsproxy.io/?${Uri.encodeComponent(urlStr)}';
    }

    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'OK') {
          final loc = result['result']['geometry']['location'];
          final lat = loc['lat'];
          final lng = loc['lng'];

          final LatLng newPos = LatLng(lat, lng);
          pickLocation(newPos);
          mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Place details failed: ${result['status']}')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Place details failed: Network error')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Place details error: $e')),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Share Hostel Location"),
        actions: [
          TextButton(
            onPressed: selectedLocation == null
                ? null
                : () {
                    Navigator.pop(context, selectedLocation);
                  },
            child: const Text(
              "SAVE",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: startLocation,
              zoom: 15,
            ),
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            onTap: pickLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Search Bar Overlay
          Positioned(
            top: 20,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _getSuggestions(val),
                    decoration: InputDecoration(
                      hintText: "Search for a place...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.indigoAccent),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _placeSuggestions = [];
                                });
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                if (_placeSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _placeSuggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _placeSuggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined,
                              color: Colors.grey),
                          title: Text(suggestion['description']),
                          onTap: () {
                            _getPlaceDetails(suggestion['place_id'],
                                suggestion['description']);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
