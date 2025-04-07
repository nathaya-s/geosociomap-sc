import 'package:flutter/material.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosociomap/components/components.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapSelectionScreen extends StatelessWidget {
  const MapSelectionScreen({super.key});

  // late MapboxMapController mapController;
  // MapboxMap? mapboxMap;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Mapbox Map
          // MapWidget(
          //     // key: ValueKey("mapWidget"),
          //     cameraOptions: CameraOptions(
          //         center: Point(coordinates: Position(13.814029, 100.037292)),
          //         zoom: 2,
          //         bearing: 0,
          //         pitch: 0)),

         
          const Positioned(
            // top: 20,
            left: 16,
            right: 16,
            child: MapSearchBar(),
          ),

       
          Positioned(
            left: 10,
            bottom: 150,
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.blue),
                  onPressed: () {
                
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.redo, color: Colors.blue),
                  onPressed: () {
                
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: () {
                  
                  },
                ),
              ],
            ),
          ),

          // Area Selection Details
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white.withOpacity(0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เลือกพื้นที่',
                    style: GoogleFonts.prompt(fontSize: 16, color: Colors.blue),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'คลิกบนแผนที่เพื่อสร้างพื้นที่',
                    style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'พื้นที่: 0.01 m²',
                    style:
                        GoogleFonts.prompt(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                        
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('ยกเลิก',
                            style: GoogleFonts.prompt(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () {
                      
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('บันทึก',
                            style: GoogleFonts.prompt(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
