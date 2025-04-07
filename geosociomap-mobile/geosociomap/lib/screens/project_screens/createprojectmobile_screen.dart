
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geosociomap/mongodb.dart';
import 'package:geosociomap/screens/home_screen.dart';
import 'package:geosociomap/screens/project_screens/mapSearchBarCreate.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateprojectmobileScreen extends StatefulWidget {
  const CreateprojectmobileScreen({super.key});

  @override
  State<CreateprojectmobileScreen> createState() =>
      _CreateprojectmobileScreenState();
}

class _CreateprojectmobileScreenState extends State<CreateprojectmobileScreen> {
  MapboxMap? mapboxMap;
  geolocator.Position? _userLocation;
  bool isLocationSelected = false;
  bool isAreaSelected = false;
  List<Position> selectedPoints = [];
  Position? firstSelectedPoint;
  Position? secondSelectedPoint;
  List<geolocator.Position> polygonCoordinates = [];
  List<List<Position>> undoStack = [];
  List<List<Position>> redoStack = [];
  final double tapRadius = 0.0005;
  bool isDeleteMode = false;
  bool isInsertMode = false;
  PolygonAnnotation? polygonAnnotation;
  PolygonAnnotationManager? polygonAnnotationManager;
  CircleAnnotation? circleAnnotation;
  CircleAnnotationManager? circleAnnotationManager;

  // LocationData? _userLocation;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initialize() async {
    await _initLocation();
    if (mapboxMap != null) {
      _updateMapLocation();
    }
  }

  Future<void> _initLocation() async {
    bool isGranted = await requestLocationPermission();

    if (isGranted) {
      try {
        geolocator.LocationSettings locationSettings =
            const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          distanceFilter: 100,
        );
        geolocator.Position position =
            await geolocator.Geolocator.getCurrentPosition(
                locationSettings: locationSettings);
        print(position);

        setState(() {
          _userLocation = position;
        });
            } catch (e) {
        print('Error getting last known location: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting last known location: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is not granted')),
      );
    }
  }

  Future<bool> _checkOfflineStatus() async {
  
    try {
    
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  OfflineManager? _offlineManager;
  TileStore? _tileStore;
  void _onMapCreated(MapboxMap mapboxMap) async {
    bool isOnline = await _checkOfflineStatus();

    _offlineManager = await OfflineManager.create();
    _tileStore = await TileStore.createDefault();

    this.mapboxMap = mapboxMap;
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );
    _updateMapLocation();
    mapboxMap.annotations.createPolygonAnnotationManager().then((value) {
      polygonAnnotationManager = value;
      createOneAnnotation();
      var options = <PolygonAnnotationOptions>[];
      polygonAnnotationManager?.createMulti(options);
      polygonAnnotationManager
          ?.addOnPolygonAnnotationClickListener(AnnotationPolygonClickListener(
        onAnnotationClick: (annotation) => polygonAnnotation = annotation,
      ));
    });
    mapboxMap.annotations.createCircleAnnotationManager().then((value) {
      circleAnnotationManager = value;
      var options = <CircleAnnotationOptions>[];
      circleAnnotationManager?.createMulti(options);
      createOneAnnotation();
      circleAnnotationManager
          ?.addOnCircleAnnotationClickListener(AnnotationCircleClickListener());
    });
  }

  void _updateMapLocation() async {
    print("pass");
    try {
      geolocator.LocationSettings locationSettings =
          const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 100,
      );
      geolocator.Position position =
          await geolocator.Geolocator.getCurrentPosition(
              locationSettings: locationSettings);
      setState(() {
        _userLocation = position;
      });

      print(_userLocation);

      if (_userLocation != null) {
        mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
                coordinates: Position(
                    _userLocation!.longitude, _userLocation!.latitude)),
            zoom: 14,
            bearing: 0, 
            pitch: 0, 
          ),
        );
      }
    } catch (e) {
      print('Error getting current position: $e');
    }
  }

  void _onAreaSelectionChanged(bool selected) {
    setState(() {
      isAreaSelected = selected;
    });
  }

  void drawPolygon() async {
    polygonAnnotationManager?.delete(polygonAnnotation!);
    polygonAnnotation = null;
    if (polygonAnnotation != null) {
      var polygon = polygonAnnotation!.geometry;
      var newPolygon = Polygon(
          coordinates: polygon.coordinates
              .map((e) =>
                  e.map((e) => Position(e.lng + 1.0, e.lat + 1.0)).toList())
              .toList());
      polygonAnnotation?.geometry = newPolygon;
      polygonAnnotationManager?.update(polygonAnnotation!);
    }
  }

  void createOneAnnotation() {
    polygonAnnotationManager
        ?.create(PolygonAnnotationOptions(
            geometry: Polygon(coordinates: [selectedPoints]),
            fillColor: Colors.blue.value,
            fillOpacity: 0.3,
            fillOutlineColor: Colors.blue.value))
        .then((value) => polygonAnnotation = value);
  }

  void createCircleAnnotation() {
    circleAnnotationManager!.deleteAll();
    var options = <CircleAnnotationOptions>[];
    for (var i = 0; i < selectedPoints.length; i++) {
      options.add(CircleAnnotationOptions(
        geometry: Point(coordinates: selectedPoints[i]),
        circleColor: (selectedPoints[i] == firstSelectedPoint ||
                selectedPoints[i] == secondSelectedPoint)
            ? Colors.blue.value 
            : Colors.blue.value,
        circleRadius: 6.0,
        circleStrokeColor: (selectedPoints[i] == firstSelectedPoint ||
                selectedPoints[i] == secondSelectedPoint)
            ? Colors.white.value
            : Colors.blue.value,
        circleStrokeWidth: (selectedPoints[i] == firstSelectedPoint ||
                selectedPoints[i] == secondSelectedPoint)
            ? 2.0 
            : 0,
      ));
    }
    circleAnnotationManager?.createMulti(options);
  }

  _onTap(MapContentGestureContext context) {
    setState(() {
      final lng = context.point.coordinates.lng;
      final lat = context.point.coordinates.lat;

      print("OnTap coordinate: {${context.point.coordinates.lng}, ${context.point.coordinates.lat}}" " point: {x: ${context.touchPosition.x}, y: ${context.touchPosition.y}}");

      if (isDeleteMode) {
        final Position? pointToDelete = _findNearestPoint(Position(lng, lat));
        if (pointToDelete != null) {
          undoStack.add(List.from(selectedPoints));
          selectedPoints.remove(pointToDelete);
          polygonAnnotationManager?.deleteAll();
          polygonAnnotation = null;
          createOneAnnotation();
          createCircleAnnotation();
        }
      } else if (isInsertMode) {
        Position? nearestPoint = _findNearestPoint(Position(lng, lat));
        if (nearestPoint != null) {
          if (firstSelectedPoint == null) {
            firstSelectedPoint = nearestPoint;
          } else if (secondSelectedPoint == null) {
            secondSelectedPoint = nearestPoint;
          } else {
            Position newPoint = Position(lng, lat);
            undoStack.add(List.from(selectedPoints));
            if (firstSelectedPoint != null && secondSelectedPoint != null) {
              int firstIndex = selectedPoints.indexOf(firstSelectedPoint!);
              int secondIndex = selectedPoints.indexOf(secondSelectedPoint!);

              if (firstIndex == 0 && secondIndex == selectedPoints.length - 1 ||
                  secondIndex == 0 && firstIndex == selectedPoints.length - 1) {
                if (firstIndex > secondIndex) {
                  selectedPoints.insert(
                      secondIndex, newPoint); 
                } else {
                  selectedPoints.insert(
                      firstIndex, newPoint); 
                }
              } else {
                if (firstIndex < secondIndex) {
                  selectedPoints.insert(
                      secondIndex, newPoint); 
                } else {
                  selectedPoints.insert(
                      firstIndex, newPoint);
                }
              }
            }
            firstSelectedPoint = null;
            secondSelectedPoint = null; 
          }
        }
        createOneAnnotation();
        createCircleAnnotation();
        if (selectedPoints.length >= 2) {
          drawPolygon();
        }
      } else {
        if (selectedPoints.isNotEmpty) {
          undoStack.add(List.from(selectedPoints));
        }
        selectedPoints.add(Position(lng, lat));
        createOneAnnotation();
        createCircleAnnotation();
        if (selectedPoints.length >= 2) {
          drawPolygon();
        }
      }
    });
    print(selectedPoints);
    print(undoStack);
  }

  void _undo() {
    if (undoStack.isNotEmpty) {
      redoStack.add(List.from(selectedPoints));
      selectedPoints = undoStack.removeLast();

      setState(() {
        createCircleAnnotation();
        if (selectedPoints.length < 3) {
          if (polygonAnnotation != null) {
            polygonAnnotationManager?.delete(polygonAnnotation!);
            polygonAnnotation = null;
          }
        } else {
          if (polygonAnnotation != null) {
            polygonAnnotationManager?.delete(polygonAnnotation!);
            polygonAnnotation = null;
            createOneAnnotation();
          }
        }
      });
    }
  }

  void _redo() {
    if (redoStack.isNotEmpty) {
      undoStack.add(List.from(selectedPoints));
      selectedPoints = redoStack.removeLast();

      setState(() {
        createCircleAnnotation();
        if (selectedPoints.length < 3) {
          if (polygonAnnotation != null) {
            polygonAnnotationManager?.delete(polygonAnnotation!);
            polygonAnnotation = null;
          }
        } else {
          if (polygonAnnotation != null) {
            polygonAnnotationManager?.delete(polygonAnnotation!);
            polygonAnnotation = null;
          }
          createOneAnnotation();
          drawPolygon();
        }
      });
    }
  }

  Position? _findNearestPoint(Position tapCoordinates) {
    num minDistance = double.infinity;
    Position? nearestPoint;
    for (Position position in selectedPoints) {
      num distance = _calculateDistance(tapCoordinates, position);
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = position;
      }
    }
    const double tapThreshold = 0.0005;
    return (minDistance <= tapThreshold) ? nearestPoint : null;
  }

  num _calculateDistance(Position p1, Position p2) {
    final num latDiff = p1.lat - p2.lat;
    final num lngDiff = p1.lng - p2.lng;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }

  List<Map<String, dynamic>> searchResults = [];
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) return;

    // setState(() {
    //   isLoading = true;
    // });
    String accessToken = await MapboxOptions.getAccessToken();
    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$accessToken&limit=5";

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
        // isLoading = false;
      });
    } else {
      setState(() {
        // isLoading = false;
      });
      throw Exception("Failed to fetch locations");
    }
  }

  // MapboxMapController? mapController;
  void moveToLocation(double lat, double lng) {
    mapboxMap!.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 12, 
        bearing: 0, 
        pitch: 0, 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            onTapListener: _onTap,
          ),
          Positioned(
            bottom: 290,
            right: 10,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                // color: Color(0xFFF3F2F2),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: FloatingActionButton(
                onPressed: _updateMapLocation,
                backgroundColor: const Color(0xFFF3F2F2),
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF699BF7), 
                ),
              ),
            ),
          ),
          if (isAreaSelected)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50), 
              bottom: 290,
              curve: Curves.easeInOut,
              left: isAreaSelected ? 10 : -100,
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Color(0xFF699BF7),
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedPoints.clear();
                        undoStack.clear();
                        redoStack.clear();
                        polygonCoordinates.clear();
                        polygonAnnotationManager?.deleteAll();
                        polygonAnnotation = null;
                        circleAnnotationManager?.deleteAll();
                        circleAnnotation = null;
                        // mapController?.clearFills();
                        // mapController?.clearCircles();
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: isDeleteMode ? const Color(0xFF699BF7) : Colors.grey,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        isDeleteMode = !isDeleteMode;
                      });
                    },
                  ),
                  const SizedBox(height: 10.0),
                  IconButton(
                    icon: Icon(
                      Icons.create_rounded,
                      color: isInsertMode ? const Color(0xFF699BF7) : Colors.grey,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        isInsertMode = !isInsertMode;
                        if (!isInsertMode) {
                          firstSelectedPoint = null;
                          secondSelectedPoint = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    width: 40,
                    decoration: BoxDecoration(
                      color: (const Color(0xFFF3F2F2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.undo,
                            color: Color(0xFF699BF7),
                          ),
                          onPressed: _undo,
                        ),
                        Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                          indent: 3,
                          endIndent: 3,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.redo,
                            color: Color(0xFF699BF7),
                          ),
                          onPressed: _redo,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: isDeleteMode && isAreaSelected ? 100 : -50,
            left: 20,
            right: 20,
            child: Container(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'คลิกที่จุดที่ต้องการลบ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Opacity(
                opacity: 0.8,
                child: MapSearchBarCreate(onLocationSelected: moveToLocation),
              )),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ProjectNameInput(
                onAreaSelectionChanged: _onAreaSelectionChanged,
                selectedPoints: selectedPoints),
          ),
        ],
      ),
    );
  }
}

class ProjectNameInput extends StatefulWidget {
  final ValueChanged<bool> onAreaSelectionChanged;
  final List<Position> selectedPoints;
  const ProjectNameInput(
      {super.key, required this.onAreaSelectionChanged, required this.selectedPoints});

  @override
  _ProjectNameInputState createState() => _ProjectNameInputState();
}

class _ProjectNameInputState extends State<ProjectNameInput> {
  bool isAreaSelected = false;
  final _formKey = GlobalKey<FormState>();
  final MongoDBService mongoDBService = MongoDBService();
  final TextEditingController _projectnamecontroller = TextEditingController();

  final TextEditingController _memberController = TextEditingController();

  Future<void> _saveProject() async {
    final projectName = _projectnamecontroller.text;
    if (projectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อโปรเจกต์')),
      );
      return;
    }

    try {
      await mongoDBService.createProject(projectName, widget.selectedPoints);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปรเจกต์ถูกบันทึกแล้ว')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกโปรเจกต์')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F2F2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          !isAreaSelected
              ? Container(
                  child: Column(
                    children: [
                      Container(
                          width: double.infinity,
                          alignment: Alignment.centerRight,
                          child: IconButton(
                              icon: Icon(
                                Icons.cancel_rounded,
                                color: Colors.grey[400],
                                size: 30,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              })),
                      const Text(
                        'สร้างโครงการ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _projectnamecontroller,
                          cursorHeight: 16,
                          decoration: InputDecoration(
                            hintText: 'ชื่อโครงการ',
                            hintStyle: GoogleFonts.sarabun(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFE5E5E6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                          ),
                          style: GoogleFonts.sarabun(
                              color: Colors
                                  .black), 
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกข้อมูล (อย่างน้อย 1 ตัวอักษร)';
                            }
                            return null;
                          },
                        ),
                      ),
                      // SizedBox(height: 8.0),
                      // TextFormField(
                      //   controller: _memberController,
                      //   decoration: InputDecoration(
                      //     hintText: 'เพิ่มสมาชิก',
                      //     hintStyle: GoogleFonts.sarabun(color: Colors.grey),
                      //     filled: true,
                      //     fillColor: Color(0xFFE5E5E6),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10.0),
                      //       borderSide: BorderSide.none,
                      //     ),
                      //     contentPadding: EdgeInsets.symmetric(
                      //         vertical: 10.0, horizontal: 20.0),
                      //   ),
                      //   style: TextStyle(color: Colors.black),
                      // ),
                      const SizedBox(height: 20.0),
                      Center(
                          child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              setState(() {
                                isAreaSelected = true;
                              });
                              widget.onAreaSelectionChanged(isAreaSelected);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('กรุณากรอกชื่อโครงการ'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF699BF7),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                            ), 
                          ),
                          child: Text(
                            'เลือกพื้นที่',
                            style: GoogleFonts.sarabun(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.edit, 
                            color: Color(
                                0xFF699BF7), 
                            size: 24.0,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'เลือกพื้นที่',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'คลิกบนแผนที่เพื่อสร้างพื้นที่',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 23),
                      const SizedBox(height: 20),
                      Divider(
                        color: Colors.grey.shade400,
                        thickness: 1,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 9,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isAreaSelected = false;
                                });
                                widget.onAreaSelectionChanged(isAreaSelected);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3E3E4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8.0), 
                                ),
                                padding: const EdgeInsets.symmetric(
                                    // vertical: 12.0,
                                    ),
                              ),
                              child: Text(
                                'ย้อนกลับ',
                                style: GoogleFonts.sarabun(
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff858589)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 9,
                            child: ElevatedButton(
                              onPressed: () {
                                _saveProject();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF699BF7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ), 
                              ),
                              child: Text(
                                'บันทึก',
                                style: GoogleFonts.sarabun(
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                color: isAreaSelected ? Colors.grey : Colors.blue,
                size: 10,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.circle,
                color: isAreaSelected ? Colors.blue : Colors.grey,
                size: 10,
              ),
            ],
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }
}

Future<bool> requestLocationPermission() async {
  final status = await Permission.locationWhenInUse.request();
  if (status.isPermanentlyDenied) {
    openAppSettings();
  }
  return status.isGranted;
}

class AnnotationPolygonClickListener extends OnPolygonAnnotationClickListener {
  AnnotationPolygonClickListener({
    required this.onAnnotationClick,
  });

  final void Function(PolygonAnnotation annotation) onAnnotationClick;

  @override
  void onPolygonAnnotationClick(PolygonAnnotation annotation) {
    print("onAnnotationClick, id: ${annotation.id}");
    onAnnotationClick(annotation);
  }
}

class AnnotationCircleClickListener extends OnCircleAnnotationClickListener {
  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    print("onAnnotationClick, id: ${annotation.id}");
  }
}

// class AnnotationPolygonBuildingClickListener extends OnPolygonAnnotationClickListener {
//   @override
//   void OnPolygonAnnotationClickListener(PolygonAnnotation annotation) {
//     print("onAnnotationClick, id: ${annotation.id}");
//   }
// }

class AnnotationCirclPathClickListener extends OnCircleAnnotationClickListener {
  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    print("onAnnotationClick, id: ${annotation.id}");
  }
}

class AnnotationPolylineClickListener
    extends OnPolylineAnnotationClickListener {
  @override
  void onPolylineAnnotationClick(PolylineAnnotation annotation) {
    print("onAnnotationClick, id: ${annotation.id}");
  }
}

class AnnotationPolylineDashClickListener
    extends OnPolylineAnnotationClickListener {
  @override
  void onPolylineAnnotationClick(PolylineAnnotation annotation) {
    print("onAnnotationClick, id: ${annotation.id}");
  }
}

class AnnotationPolylineSolidClickListener
    extends OnPolylineAnnotationClickListener {
  @override
  void onPolylineAnnotationClick(PolylineAnnotation annotation) {
    print("onAnnotationClick, id: ${annotation.id}");
  }
}

class AnnotationPointClickListener extends OnPointAnnotationClickListener {
  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    print("onAnnotationClick, id: ${annotation.id}");
  }
}
