import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geosociomap/screens/map/utils.dart';
import 'package:geosociomap/screens/project_screens/createprojectmobile_screen.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EditProjectPage extends StatefulWidget {
  final Map<String, dynamic> project;
  final List<dynamic> layers;

  const EditProjectPage({
    super.key,
    required this.project,
    required this.layers,
  });

  @override
  _EditProjectPageState createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  late Map<String, dynamic> project;
  late List<dynamic> layers;

  bool isDeleteMode = false;
  bool isInsertMode = false;
  int editMode = 0;
  int _step = 0;

  List<List<Position>> undoStack = [];
  List<List<Position>> redoStack = [];
  List<Position> selectedPoints = [];
  List<geolocator.Position> polygonCoordinates = [];
  Position? firstSelectedPoint;
  Position? secondSelectedPoint;
  PolygonAnnotation? polygonAnnotation;
  PolygonAnnotationManager? polygonAnnotationManager;
  CircleAnnotation? circleAnnotation;
  CircleAnnotationManager? circleAnnotationManager;

  final TextEditingController textController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Position? _userLocation;
  List<String> searchedEmails = [];
  List<String> allEmails = [];
  List<String> filteredUserIds = [];

  MapboxMap? mapboxMap;
  MapboxMap? mapboxMapOffline;
  PolylineAnnotationManager? polylineAnnotationManager;

  final StreamController<double> _stylePackProgress =
      StreamController.broadcast();
  final StreamController<double> _tileRegionLoadProgress =
      StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    project = widget.project;
    layers = widget.layers;

    _fetchEmails();
    filteredUserIds = _getFilteredUserIds();
    selectedPoints = (project['selectedPoints'] as List)
        .map((point) => Position(point['lng'], point['lat']))
        .toList();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Uri getUserEmailUrl() {
    if (Platform.isAndroid) {
      return Uri.parse('https://geosociomap-backend.onrender.com/users/emails');
    } else if (Platform.isIOS) {
      return Uri.parse('https://geosociomap-backend.onrender.com/users/emails');
    } else {
      throw UnsupportedError('This platform is not supported');
    }
  }

  Uri postEditProjectUrl() {
    if (Platform.isAndroid) {
      return Uri.parse(
          'https://geosociomap-backend.onrender.com/update-project');
    } else if (Platform.isIOS) {
      return Uri.parse(
          'https://geosociomap-backend.onrender.com/update-project');
    } else {
      throw UnsupportedError('This platform is not supported');
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

  Future<bool> _checkOfflineStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.none;
    } catch (e) {
      return false; // ถ้าการตรวจสอบล้มเหลวถือว่าไม่ offline
    }
  }

  _downloadStylePack() async {
    final offlineManager = await OfflineManager.create();
    final stylePackLoadOptions = StylePackLoadOptions(
        glyphsRasterizationMode:
            GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
        metadata: {"tag": "test"},
        acceptExpired: false);
    offlineManager.loadStylePack(MapboxStyles.OUTDOORS, stylePackLoadOptions,
        (progress) {
      final percentage =
          progress.completedResourceCount / progress.requiredResourceCount;
      if (!_stylePackProgress.isClosed) {
        _stylePackProgress.sink.add(percentage);
      }
    }).then((value) {
      _stylePackProgress.sink.add(1);
      _stylePackProgress.sink.close();
    });
  }

  _downloadTileRegion() async {
    final tmpDir = await getTemporaryDirectory();
    final tileStore = await TileStore.createAt(tmpDir.uri);
    final tileRegionLoadOptions = TileRegionLoadOptions(
        geometry: Point(coordinates: Position(-80.1263, 25.7845)).toJson(),
        descriptorsOptions: [
          TilesetDescriptorOptions(
              styleURI: MapboxStyles.OUTDOORS, minZoom: 0, maxZoom: 16)
        ],
        acceptExpired: true,
        networkRestriction: NetworkRestriction.NONE);

    tileStore.loadTileRegion("my-tile-region", tileRegionLoadOptions,
        (progress) {
      final percentage =
          progress.completedResourceCount / progress.requiredResourceCount;
      if (!_tileRegionLoadProgress.isClosed) {
        _tileRegionLoadProgress.sink.add(percentage);
      }
    }).then((value) {
      _tileRegionLoadProgress.sink.add(1);
      _tileRegionLoadProgress.sink.close();
    });
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    bool isOffline = await _checkOfflineStatus();

    if (isOffline) {
      this.mapboxMap = mapboxMapOffline;
      await _downloadStylePack();
      await _downloadTileRegion();

      return;
    }

    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );

    // mapboxMap.annotations.createPolylineAnnotationManager().then((value) {
    //   polylineAnnotationManager = value;
    //   createPolylineAnnotation();
    //   final positions = <List<Position>>[];

    //   polylineAnnotationManager?.addOnPolylineAnnotationClickListener(
    //       AnnotationPolylineClickListener());
    // });

    mapboxMap.annotations.createCircleAnnotationManager().then((value) {
      circleAnnotationManager = value;
      List<Position> selectedPoints = (project['selectedPoints'] as List)
          .map((point) => Position(point['lng'], point['lat']))
          .toList();

      for (var position in selectedPoints) {
        final circleOptions = CircleAnnotationOptions(
          geometry: Point(
              coordinates: Position(
            position.lng,
            position.lat,
          )),
          circleColor: 0xFF699BF7, // ใช้โค้ดสีเป็น string
          circleRadius: 7.0,
          circleStrokeColor: 0xFFFFFFFF, // สีขอบวงกลม
          circleStrokeWidth: 2.0,
        );
        circleAnnotationManager?.create(circleOptions).then((circle) {});
      }
      circleAnnotationManager
          ?.addOnCircleAnnotationClickListener(AnnotationCircleClickListener());
    });

    mapboxMap.annotations.createPolygonAnnotationManager().then((value) {
      polygonAnnotationManager = value;
      List<Position> selectedPoints = (project['selectedPoints'] as List)
          .map((point) => Position(point['lng'], point['lat']))
          .toList();
      polygonAnnotationManager?.create(PolygonAnnotationOptions(
          geometry: Polygon(coordinates: [selectedPoints]),
          fillColor: Colors.blue.value,
          fillOpacity: 0.3,
          fillOutlineColor: Colors.blue.value));
      polygonAnnotationManager
          ?.addOnPolygonAnnotationClickListener(AnnotationPolygonClickListener(
        onAnnotationClick: (annotation) => polygonAnnotation = annotation,
      ));
    });

    focusOnSelectedPoints();
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

  void createPolylineAnnotation() {
    List<Position> selectedPoints = (project['selectedPoints'] as List)
        .map((point) => Position(point['lng'], point['lat']))
        .toList();

    selectedPoints.add(selectedPoints.first);

    polylineAnnotationManager
        ?.create(PolylineAnnotationOptions(
          geometry: LineString(coordinates: selectedPoints),
          lineColor: 0xFF699BF7, 
          lineWidth: 4.0, 
        ))
        .then((value) => {});
  }

  Position calculateCenter(List<Position> points) {
    double latSum = 0;
    double lngSum = 0;

    for (var point in points) {
      latSum += point.lat;
      lngSum += point.lng;
    }

    return Position(lngSum / points.length, latSum / points.length);
  }

  void focusOnSelectedPoints() {
    // List<Position> selectedPoints = [];
    List<Position> selectedPoints = (project['selectedPoints'] as List)
        .map((point) => Position(point['lng'], point['lat']))
        .toList();
    print(project['selectedPoints']);

    Position center = calculateCenter(selectedPoints);
    mapboxMap!.setCamera(
      CameraOptions(
        center: Point(coordinates: center),
        zoom: 17,
      ),
    );
    }

  void _updateMapLocation() async {
    print("pass");
    try {
      final Position? pos = await mapboxMap?.style.getPuckPosition();
      if (pos == null) {
        return;
      }
      print(pos);

      setState(() {
        _userLocation = pos;
      });

      print(_userLocation);

      if (_userLocation != null) {
        mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
                coordinates: Position(_userLocation!.lng, _userLocation!.lat)),
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

  void _onTap(MapContentGestureContext context) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Edit Project'),
      // ),
      body: Stack(
      
        children: [
         
          MapWidget(
            onMapCreated: _onMapCreated,
            onTapListener: _onTap,
            styleUri: MapboxStyles.OUTDOORS,
          ),
          Positioned(
            bottom: 270,
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
      
          Positioned(
            bottom: 220,
            right: 10,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                // color: Color(0xFFF3F2F2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: FloatingActionButton(
                onPressed: focusOnSelectedPoints,
                backgroundColor: const Color(0xFFF3F2F2),
                child: const Icon(
                  Icons.hexagon_outlined,
                  color: Color(0xFF699BF7),
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 50), 
            bottom: 220,
            curve: Curves.easeInOut,
            left: _step == 2 ? 10 : -100,
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

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3F2F2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  _buildContent(),
                  const SizedBox(height: 16),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    setState(() {
      if (_step < 2) {
        _step++;
      }
    });
  }

  void _prevStep() {
    setState(() {
      if (_step > 0) {
        _step--;
      }
    });
  }

  List<String> _getFilteredUserIds() {
    final user = FirebaseAuth.instance.currentUser;

    // แปลง userIds เป็น List<String> ก่อน
    List<String> userIds =
        (widget.project['userIds'] as List<dynamic>).cast<String>();

    return userIds
        .where((email) => email.toLowerCase() != user?.email?.toLowerCase())
        .toList();
  }

  Future<void> _fetchEmails() async {
    try {
      final response = await http.get(getUserEmailUrl());

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> emails = jsonResponse['emails'] ?? [];

        setState(() {
          allEmails = List<String>.from(emails.map(
              (email) => email.toLowerCase())); 
          searchedEmails = allEmails; 

          print(searchedEmails);
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching emails: $e');
    }
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // List<String> filteredUserIds = _getFilteredUserIds();

            return FractionallySizedBox(
              heightFactor: 0.75,
              widthFactor: 1.0, 
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F4), 
                  borderRadius: BorderRadius.circular(8.0), 
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                
                    Text(
                      'ค้นหาสมาชิกในโครงการ',
                      style: GoogleFonts.sarabun(
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setModalState(() {
                          searchedEmails = allEmails
                              .where((email) => email
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'ค้นหาด้วยอีเมล',
                        hintStyle: GoogleFonts.sarabun(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFE5E5E6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 20.0,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.cancel_rounded),
                          onPressed: () {
                            setState(() {
                              _searchController.clear(); 
                              searchedEmails = allEmails; 
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),

                    const SizedBox(height: 16),

                
                    Expanded(
                      child: ListView.builder(
                        itemCount: searchedEmails.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Container(
                              height: 36.0,
                              width: 36.0,
                              decoration: const BoxDecoration(
                                color: Color(
                                    0xFF699BF7), 
                                shape: BoxShape.circle, 
                              ),
                              child: const Icon(
                                Icons.person, 
                                color: Colors.white, 
                                size: 25.0, 
                              ),
                            ),
                            title: Text(searchedEmails[index]),
                            onTap: () {
                              setState(() {
                                filteredUserIds.add(searchedEmails[
                                    index]); 
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent() {
    String title = '';
    String hintText = '';

    if (_step == 0) {
      title = 'แก้ไขชื่อโครงการ';
      hintText = 'ชื่อโครงการ';
    } else if (_step == 1) {
      title = 'แก้ไขสมาชิกในโครงการ';
      hintText = 'สมาชิกในโครงการ';
    } else {
      title = 'แก้ไขพื้นที่ของโครงการ';
    }

    List<String> getUniqueFilteredUserIds() {
      return filteredUserIds
          .map((email) => email.toLowerCase()) 
          .toSet() // กรองค่าซ้ำ
          .toList();
    }

   

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
    
        Text(
          title,
          style: GoogleFonts.sarabun(
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          textAlign: TextAlign.left, 
        ),
        const SizedBox(height: 16), 

       
        if (_step == 0)
          TextField(
            controller: _textController
              ..text = project['projectName'], 
            cursorHeight: 16,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.sarabun(
                textStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              filled: true,
              fillColor: const Color(0xFFE5E5E6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 20.0,
              ),
            ),
            style: GoogleFonts.sarabun(
              textStyle: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          )
        else if (_step == 1)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3), 
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  _showSearchModal, 
                              child: Text(
                                'เพิ่มสมาชิก', 
                                style: GoogleFonts.sarabun(
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                textAlign: TextAlign.left, 
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                _showSearchModal,
                            child: Container(
                              height: 36.0,
                              width: 36.0,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(top: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), 
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 8.0, 
                  runSpacing: 4.0, 
                  children: getUniqueFilteredUserIds().isNotEmpty
                      ? getUniqueFilteredUserIds().map((email) {
                          return Chip(
                            label: Text(
                              email.toLowerCase(),
                              style: GoogleFonts.sarabun(
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            deleteIcon: const Icon(
                              Icons.cancel_rounded,
                              color: Colors.grey,
                              size: 20.0,
                            ),
                            onDeleted: () {
                              setState(() {
                                filteredUserIds.remove(email
                                    .toLowerCase()); 
                              });
                            },
                            backgroundColor:
                                Colors.blue[50], 
                            shape: const StadiumBorder(
                              side: BorderSide(
                                  color: Colors.blue, width: 1), 
                            ),
                          );
                        }).toList()
                      : [
                          const Text('ไม่มีสมาชิก')
                        ],
                ),
              ),
            ],
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'คลิกบนแผนที่เพื่อแก้ไขพื้นที่',
              style: GoogleFonts.sarabun(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButtons() {
    if (_step == 0) {
      return Center(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF699BF7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: Text(
              'ต่อไป',
              style: GoogleFonts.sarabun(
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ปุ่มย้อนกลับ
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: ElevatedButton(
              onPressed: _prevStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3E3E4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Text(
                'ย้อนกลับ',
                style: GoogleFonts.sarabun(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff858589),
                  ),
                ),
              ),
            ),
          ),
        
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: ElevatedButton(
              onPressed: _step < 2
                  ? _nextStep
                  : () async {
                      print("123");

                  
                      final user = FirebaseAuth.instance.currentUser;
                      print(user);

                      print("passsss");
                      print(filteredUserIds);

                 
                      final updatedProject = {
                        'projectId': project[
                            '_id'], 
                        'projectName':
                            _textController.text, 
                        'selectedPoints': selectedPoints
                            .map((point) => {
                                  'lat': point.lat,
                                  'lng': point.lng,
                                })
                            .toList(), 
                        'selectedEmails':
                            filteredUserIds,
                        'userId': user?.uid, 
                      };

                      try {
                        final response = await http.post(
                          postEditProjectUrl(), 
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(updatedProject),
                        );

                        if (response.statusCode == 200) {
                          setState(() {
                            project['projectName'] = _textController.text;
                            project['selectedPoints'] = selectedPoints
                                .map((point) => {
                                      'lat': point.lat,
                                      'lng': point.lng,
                                    })
                                .toList();
                            project['userIds'] = [
                              user?.email,
                              ...filteredUserIds
                            ];
                          });
                       

                          print('บันทึกข้อมูลสำเร็จ');
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                         
                        } else {
                        
                          print('เกิดข้อผิดพลาดในการบันทึกข้อมูล');
                        }
                      } catch (e) {
                        print("Error while updating project: $e");
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF699BF7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Text(
                _step < 2 ? 'ต่อไป' : 'บันทึก',
                style: GoogleFonts.sarabun(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
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
}
