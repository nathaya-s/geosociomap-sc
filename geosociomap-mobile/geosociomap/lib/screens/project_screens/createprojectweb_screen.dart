// import 'package:flutter/material.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'dart:math' as math;

// class CreateprojectwebScreen extends StatefulWidget {
//   @override
//   _CreateprojectwebState createState() => _CreateprojectwebState();
// }

// class _CreateprojectwebState extends State<CreateprojectwebScreen> {
//   MapboxMapController? mapController;
//   LatLng? userLocation;
//   final String mapboxAccessToken =
//       'pk.eyJ1IjoibmF0aGF5YS1zIiwiYSI6ImNtMG5ub3gwYjBmeGYybHB1a2JueGNqOXQifQ.Jc0c7IGEYFjVbRnLFtdEvA';
//   List<LatLng> selectedPoints = [];
//   List<LatLng> polygonCoordinates = [];
//   List<List<LatLng>> undoStack = [];
//   List<List<LatLng>> redoStack = [];
//   final double tapRadius = 0.0005;
//   bool isDeleteMode = false;

//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//   }

//   Future<void> _getUserLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return;
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       return;
//     }

//     Position position = await Geolocator.getCurrentPosition();
//     setState(() {
//       userLocation = LatLng(position.latitude, position.longitude);
//     });

//     if (mapController != null && userLocation != null) {
//       mapController!.animateCamera(CameraUpdate.newLatLng(userLocation!));
//       mapController!.addSymbol(SymbolOptions(
//         geometry: userLocation!,
//         iconImage: "marker-15",
//       ));
//     }
//   }

//   void _onMapCreated(MapboxMapController controller) {
//     mapController = controller;
//     if (userLocation != null) {
//       mapController!.animateCamera(CameraUpdate.newLatLng(userLocation!));
//       mapController!.addSymbol(SymbolOptions(
//         geometry: userLocation!,
//         iconImage: "marker-15",
//         iconSize: 2.0,
//       ));
//     }
//   }

//   void _onMapTapped(math.Point<double> point, LatLng coordinates) {
//     setState(() {
//       if (isDeleteMode) {
//         final LatLng? pointToDelete = _findNearestPoint(coordinates);
//         if (pointToDelete != null) {
//           undoStack.add(List.from(polygonCoordinates));
//           selectedPoints.remove(pointToDelete);
//           polygonCoordinates.remove(pointToDelete);
//         }
//       } else {
//         if (polygonCoordinates.isNotEmpty &&
//             _isPointClose(coordinates, polygonCoordinates.first)) {
//           // เชื่อมเส้นที่จุดแรก
//           polygonCoordinates.add(polygonCoordinates.first);
//           undoStack.add(List.from(polygonCoordinates));
//           _drawLine(); // วาดเส้นหลังจากที่เส้นมาบรรจบ
//           return;
//         }

//         undoStack.add(List.from(polygonCoordinates));
//         selectedPoints.add(coordinates);
//         polygonCoordinates.add(coordinates);
//       }
//     });
//     _drawPolygon();
//     _drawPointCircles();
//     _drawLine();
//   }

//   bool _isPointClose(LatLng point1, LatLng point2,
//       [double threshold = 0.0005]) {
//     final double latDiff = point1.latitude - point2.latitude;
//     final double lngDiff = point1.longitude - point2.longitude;
//     final double distance = (latDiff * latDiff) + (lngDiff * lngDiff);
//     return distance <= (threshold * threshold);
//   }

//   void _drawPolygon() {
//     mapController?.clearFills();
//       mapController?.addFill(
//         FillOptions(
//           geometry: [polygonCoordinates],
//           fillColor: "#699BF7",
//           fillOpacity: 0.3,
//         ),
//       );
//   }

//   void _drawPointCircles() {
//     mapController?.clearCircles();
//     for (LatLng point in selectedPoints) {
//       mapController?.addCircle(
//         CircleOptions(
//           geometry: point,
//           circleRadius: 7.0,
//           circleColor: "#699BF7",
//           circleOpacity: 0.9,
//         ),
//       );
//     }
//   }

//   void _drawLine() {
//     mapController?.clearLines(); // ล้างเส้นก่อนหน้า

//     if (polygonCoordinates.isNotEmpty && polygonCoordinates.length > 1) {
//       mapController?.addLine(
//         LineOptions(
//           geometry: polygonCoordinates, // ใช้ List<LatLng> สำหรับเส้น
//           lineColor: "#0000FF", // สีของเส้น
//           lineWidth: 3.0, // ความกว้างของเส้น
//           lineOpacity: 0.6, // ความโปร่งใสของเส้น
//         ),
//       );
//     } else {
//       print('Error: Not enough coordinates to form a line');
//     }
//   }

//   void _undo() {
//     if (undoStack.isNotEmpty) {
//       redoStack.add(List.from(polygonCoordinates)); // เก็บประวัติใน redoStack
//       setState(() {
//         polygonCoordinates = undoStack.removeLast();
//         selectedPoints = List.from(polygonCoordinates);
//       });
//       _drawPointCircles();
//       _drawPolygon();
//     }
//   }

//   void _redo() {
//     if (redoStack.isNotEmpty) {
//       undoStack.add(List.from(polygonCoordinates)); // เก็บประวัติใน undoStack
//       setState(() {
//         polygonCoordinates = redoStack.removeLast();
//         selectedPoints = List.from(polygonCoordinates);
//       });
//       _drawPointCircles();
//       _drawPolygon();
//     }
//   }

//   LatLng? _findNearestPoint(LatLng tapCoordinates) {
//     double minDistance = double.infinity;
//     LatLng? nearestPoint;
//     for (LatLng point in selectedPoints) {
//       double distance = _calculateDistance(tapCoordinates, point);
//       if (distance < minDistance) {
//         minDistance = distance;
//         nearestPoint = point;
//       }
//     }

//     const double tapThreshold = 0.0005;
//     return (minDistance <= tapThreshold) ? nearestPoint : null;
//   }

//   double _calculateDistance(LatLng p1, LatLng p2) {
//     final double latDiff = p1.latitude - p2.latitude;
//     final double lngDiff = p1.longitude - p2.longitude;
//     return (latDiff * latDiff) + (lngDiff * lngDiff);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         // appBar: AppBar(
//         //   title: Text("Mapbox User Location"),
//         // ),
//         body: Stack(children: [
//       userLocation == null
//           ? Center(child: CircularProgressIndicator())
//           : MapboxMap(
//               accessToken: mapboxAccessToken,
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: CameraPosition(
//                 target: userLocation!,
//                 zoom: 14.0,
//               ),

//               onMapClick: (math.Point<double> point, LatLng coordinates) =>
//                   _onMapTapped(point, coordinates),
//               myLocationEnabled: true, // เปิดใช้งานการแสดงตำแหน่งผู้ใช้
//             ),
//       Positioned(
//           top: 60,
//           left: 16,
//           right: 16,
//           child: Opacity(
//             opacity: 0.8,
//             child: MapSearchBar(),
//           )),
//       AnimatedPositioned(
//         duration: Duration(milliseconds: 50), // กำหนดความเร็วของการเลื่อน
//         bottom: 310,
//         curve: Curves.easeInOut,
//         // left: isAreaSelected ? 10 : -100,
//         child: Column(
//           children: [
//             IconButton(
//               icon: Icon(
//                 Icons.refresh,
//                 color: Color(0xFF699BF7),
//                 size: 30,
//               ),
//               onPressed: () {
//                 setState(() {
//                   selectedPoints.clear();
//                   polygonCoordinates.clear();
//                   mapController?.clearFills();
//                   mapController?.clearCircles();
//                 });
//               },
//             ),
//             IconButton(
//               icon: Icon(
//                 Icons.delete,
//                 color: isDeleteMode ? Color(0xFF699BF7) : Colors.grey,
//                 size: 30,
//               ),
//               onPressed: () {
//                 setState(() {
//                   isDeleteMode = !isDeleteMode;
//                 });
//               },
//             ),
//             SizedBox(height: 10.0),
//             Container(
//               width: 40,
//               decoration: BoxDecoration(
//                 color: (Color(0xFFF3F2F2)),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Column(
//                 children: [
//                   IconButton(
//                     icon: Icon(
//                       Icons.undo,
//                       color: Color(0xFF699BF7),
//                     ),
//                     onPressed: _undo,
//                   ),
//                   Divider(
//                     color: Colors.grey.shade400,
//                     thickness: 1,
//                     indent: 3,
//                     endIndent: 3,
//                   ),
//                   IconButton(
//                     icon: Icon(
//                       Icons.redo,
//                       color: Color(0xFF699BF7),
//                     ),
//                     onPressed: _redo,
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     ]));
//   }
// }

// class MapSearchBar extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerRight, // จัดชิดขวามือ
//       child: Container(
//         constraints: BoxConstraints(
//           minWidth: 300,
//           maxWidth: 350,
//         ),
//         child: Container(
//           constraints: BoxConstraints(
//             maxHeight: 40,
//           ),
//           decoration: BoxDecoration(
//             color: Colors.grey[200],
//             borderRadius: BorderRadius.circular(30),
//           ),
//           child: TextField(
//             textAlignVertical: TextAlignVertical.center,
//             decoration: InputDecoration(
//               filled: true,
//               fillColor: Colors.white.withOpacity(0.8),
//               prefixIcon: Container(
//                 child: Icon(
//                   Icons.search_rounded,
//                   color: Colors.grey,
//                   size: 20,
//                 ),
//               ),
//               hintText: 'ค้นหา',
//               hintStyle: GoogleFonts.prompt(
//                 textStyle: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 14,
//                 ),
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(30), // ขอบมน
//                 borderSide: BorderSide.none, // ไม่มีเส้นขอบ
//               ),
//               contentPadding: EdgeInsets.symmetric(vertical: 11.0),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
