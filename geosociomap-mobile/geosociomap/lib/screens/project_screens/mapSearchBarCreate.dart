import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapSearchBarCreate extends StatefulWidget {
  final Function(double, double) onLocationSelected; 

  const MapSearchBarCreate({super.key, required this.onLocationSelected});

  @override
  _MapSearchBarState createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBarCreate> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;


  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });
    final String mapboxAccessToken = await MapboxOptions.getAccessToken();
    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$mapboxAccessToken&limit=5";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data["features"] as List;

      setState(() {
        searchResults = features.map((place) {
          return {
            "name": place["place_name"],
            "lat": place["geometry"]["coordinates"][1],
            "lng": place["geometry"]["coordinates"][0],
          };
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception("Failed to fetch locations");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 300, maxWidth: 350),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    searchResults = []; 
                  });
                } else {
                  searchPlaces(value);
                }
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.grey, size: 20),
                hintText: 'ค้นหาสถานที่...',
                hintStyle: GoogleFonts.sarabun(
                    textStyle:
                        const TextStyle(color: Colors.grey, fontSize: 14)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      8), 
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 11.0),
              ),
              style: GoogleFonts.sarabun(
                  textStyle:
                      const TextStyle(color: Colors.black, fontSize: 14)),
            ),
          ),

          
          if (searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 350),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final place = searchResults[index];
                  return ListTile(
                    title: Text(
                      place["name"],
                      style: GoogleFonts.sarabun(
                          textStyle: const TextStyle(fontSize: 14)),
                    ),
                    onTap: () {
                      widget.onLocationSelected(place["lat"],
                          place["lng"]);
                      setState(() {
                        searchController.text = place["name"];
                        searchResults = [];
                      });
                    },
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
