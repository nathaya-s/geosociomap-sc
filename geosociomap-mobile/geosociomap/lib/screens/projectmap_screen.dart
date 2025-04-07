import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geosociomap/components/buildListTile.dart';
import 'package:geosociomap/components/customBarChart.dart';
import 'package:geosociomap/components/layerDropdown.dart';
import 'package:geosociomap/hive/hiveService.dart';
import 'package:geosociomap/screens/api.dart';
import 'package:geosociomap/screens/map/utils.dart';
import 'package:geosociomap/screens/url.dart';
import 'package:geosociomap/widget/questionWidget.dart';
import 'package:image_picker/image_picker.dart'
    as image_picker; // Import with alias
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:flutter/services.dart'; // สำหรับ rootBundle
import 'package:permission_handler/permission_handler.dart';
// import 'package:realm/realm.dart';
// import 'package:uuid/uuid.dart';
// import 'dart:typed_data';

import 'dart:io';

import 'package:geosociomap/screens/project_screens/createprojectmobile_screen.dart';
// import 'package:geosociomap/screens/projectmap_screen.dart';
// import 'package:geosociomap/screens/usersetting_screen.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:geosociomap/components/components.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart'; // Add this import
import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:fl_chart/fl_chart.dart';

// import 'package:uuid/uuid.dart';
// import 'package:sane_uuid/src/uuid_base.dart' as uuid_base;

import 'dart:async';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

// import 'page.dart';
// import 'utils.dart';

class ProjectMapPage extends StatefulWidget {
  final String id;
  final String? userId;
  final Map<String, dynamic> project;
  final List<dynamic> layers;
  final List<Map<String, dynamic>> buildingsData;
  final List<Ralationship> relationships;
  final List<Location> locations;
  final Map<String, dynamic> note;

  const ProjectMapPage(
      {super.key, required this.id,
      this.userId,
      required this.project,
      required this.layers,
      required this.buildingsData,
      required this.relationships,
      required this.note,
      required this.locations});

  @override
  _ProjectMapPageState createState() => _ProjectMapPageState();
}

class _ProjectMapPageState extends State<ProjectMapPage>
    with TickerProviderStateMixin {
  Position? _userLocation;
  // PolygonAnnotation? polygonAnnotation;
  PolygonAnnotationManager? polygonAnnotationManager;
  PolylineAnnotationManager? polylinedashAnnotationManager;
  PolylineAnnotationManager? polylinesolidAnnotationManager;
  PolylineAnnotation? polylineAnnotation;
  PolylineAnnotationManager? polylineAnnotationManager;
  PolylineAnnotationManager? polylineNavigateAnnotationManager;
  PointAnnotation? pointAnnotation;
  PointAnnotationManager? pointAnnotationManager;
  MapboxMap? mapboxMap;
  Project? projectData;
  bool isLoading = false;
  String? userId;
  List<Map<String, dynamic>> buildingsData = [];
  // List<File> _selectedImage = [];

  Map<int, PointAnnotation?> pointAnnotationsMap = {};

  MapboxMap? mapboxMapOffline;
  final StreamController<double> _stylePackProgress =
      StreamController.broadcast();
  final StreamController<double> _tileRegionLoadProgress =
      StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    print(widget.id);
    print(widget.buildingsData);
    print(widget.locations);
    print(widget.note);
    print(widget.project);
    print(widget.relationships);
    print(widget.layers);
    _initialize();
    // _fetchProjectData();

    relationships = widget.relationships;
    print(relationships);
    print(relationships);
    print(relationships);
    print(relationships);
    print(relationships);
    _locations = widget.locations;

    layers = widget.layers
        .whereType<Map<String, dynamic>>() // กรองเฉพาะที่เป็น Map<String, dynamic>
        .map((layer) => layer)
        .toList();
    userId = widget.userId;
    buildingsData = widget.buildingsData;
    if (widget.project.isNotEmpty) {
      projectData = Project(
        projectId: widget.project['_id'],
        projectName: widget.project['projectName'],
        selectedPoints: (widget.project['selectedPoints'] as List)
            .map((point) => Position(
                  point['lng'],
                  point['lat'],
                ))
            .toList(),
        lastUpdate: widget.project['lastUpdate'],
        createdAt: widget.project['createdAt'],
      );
    }
    // for (var building in buildingsData) {
    //   // Check if the 'data' field is not null and contains instances of 'Answer'
    //   if (building['data'] != null) {
    //     for (var item in building['data']) {
    //       if (item is Answer) {
    //         answersList.add(item);
    //       }
    //     }
    //   }
    // }
    print("----------answersList---------");
    print(answersList);
    print("----------answersList---------");

    if (widget.note.isNotEmpty) {
      _noteController.text = widget.note['mainNote'];
      _selectedImages = widget.note['attachments'];
    }

    _noteController.addListener(() {
     
      _autoSave();
    });
    print("Start map");
  }

  @override
  void dispose() {
    _locations.clear();
    layerNameController.dispose();
    _stylePackProgress.close(); 
    _tileRegionLoadProgress.close(); 
    pointAnnotationManager?.deleteAll();
    relationshipCoordinates.clear();
    topiccontrollers.dispose();
    answersList.clear();
    polygonAnnotationManager?.deleteAll();
    polylineAnnotationManager?.deleteAll();
    polylinedashAnnotationManager?.deleteAll();

    // เรียกฟังก์ชันที่เป็น async แยกออกมา
    _disposeAsyncTasks();

    super.dispose();
  }

  Future<void> _disposeAsyncTasks() async {
    await OfflineSwitch.shared.setMapboxStackConnected(true);
    await _removeTileRegionAndStylePack();
  }

  Future<void> _createPointAnnotation(
      Map<String, dynamic> marker, String color, String iconName) async {
    print(marker);
    print(iconName);
    final ByteData bytes = await rootBundle.load(iconName);
    final dynamic imageData = bytes.buffer.asUint8List();

    final PointAnnotation pointAnnotation =
        await pointAnnotationManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(marker['lng'], marker['lat'])),
      iconSize: 0.2,
      textColor: Colors.red.value,
      image: imageData,
    ));


    marker['pointAnnotation'] = pointAnnotation;

   
    print("Updated Marker: $marker");
  }

  void _createPathAnnotation(Path path) {
    print('_createPathAnnotation passssss');
   
    polylineAnnotationManager
        ?.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: path.points),
      lineColor: path.color?.value,
      lineWidth: path.thickness,
    ))
        .then((polylineAnnotation) {
      path.polylineAnnotation = polylineAnnotation;
    }).catchError((error) {
    
      print("Failed to create polyline: $error");
    });
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return status.isGranted;
  }

  Future<void> _initialize() async {
    await _initLocation();
    if (mapboxMap != null) {
      _updateMapLocation();
    }
  }

  // Future<void> _fetchProjectData() async {
  //   final url = getBaseUrl(widget.id);

  //   try {
  //     // เช็คสถานะออนไลน์
  //     bool isOnline = await _checkOfflineStatus();
  //     print('Is online: $isOnline');

  //     if (!isOnline) {
  //       // ถ้าออฟไลน์ แสดงข้อความหรือจัดการสถานะที่เหมาะสม
  //       setState(() {
  //         isLoading = false; // หยุดโหลด
  //       });
  //       return;
  //     }

  //     // ดึงข้อมูลจาก API เมื่อออนไลน์
  //     final response = await http.get(url);
  //     if (response.statusCode == 200) {
  //       setState(() {
  //         projectData = Project.fromJson(json.decode(response.body));
  //         isLoading = false; // ดึงข้อมูลสำเร็จ
  //       });
  //     } else {
  //       // จัดการกรณีที่สถานะไม่ใช่ 200
  //       setState(() {
  //         isLoading = false; // หยุดโหลดเมื่อมีข้อผิดพลาด
  //       });
  //       throw Exception(
  //           'Failed to fetch project data. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     // จัดการข้อผิดพลาดทั่วไป
  //     print('Error fetching project data: $e');
  //     setState(() {
  //       isLoading = false; // หยุดโหลดเมื่อมีข้อผิดพลาด
  //     });
  //   }
  // }

  Future<void> _initLocation() async {
    bool serviceEnabled =
        await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    geolocator.LocationPermission permission =
        await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) {
        return;
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      return;
    }

   
    _userLocation = await mapboxMap?.style.getPuckPosition();

   
    setState(() {
    
    });

    startListeningToLocationChanges();
  }

  void startListeningToLocationChanges() {
    stopListeningToLocationChanges(); 

    geolocator.Position?
        userLocation;
    _locationSubscription = geolocator.Geolocator.getPositionStream().listen(
      (geolocator.Position newLocation) {
        _userLocationStreamController.add(newLocation);
        userLocation = newLocation; 
            
      },
    );
  }

  Future<bool> _checkOfflineStatus() async {
    try {
      // 
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return false; // 
    }
  }

  OfflineManager? _offlineManager;
  TileStore? _tileStore;
  final _tileRegionId = "my-tile-region";
  _downloadStylePack() async {
    final stylePackLoadOptions = StylePackLoadOptions(
        glyphsRasterizationMode:
            GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
        metadata: {"tag": "test"},
        acceptExpired: false);
    _offlineManager?.loadStylePack(MapboxStyles.OUTDOORS, stylePackLoadOptions,
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
    Position center = calculateCenter(projectData!.selectedPoints);
    final tileRegionLoadOptions = TileRegionLoadOptions(
        geometry: Point(coordinates: center).toJson(),
        descriptorsOptions: [
        
          TilesetDescriptorOptions(
              styleURI: MapboxStyles.OUTDOORS, minZoom: 0, maxZoom: 16)
        ],
        acceptExpired: true,
        networkRestriction: NetworkRestriction.NONE);

    _tileStore?.loadTileRegion(_tileRegionId, tileRegionLoadOptions,
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

  _removeTileRegionAndStylePack() async {
    // Clean up after the example. Typically, you'll have custom business
    // logic to decide when to evict tile regions and style packs

    // Remove the tile region with the tile region ID.
    // Note this will not remove the downloaded tile packs, instead, it will
    // just mark the tileset as not a part of a tile region. The tiles still
    // exists in a predictive cache in the TileStore.
    await _tileStore?.removeRegion(_tileRegionId);

    // Set the disk quota to zero, so that tile regions are fully evicted
    // when removed.
    // This removes the tiles from the predictive cache.
    // _tileStore?.setDiskQuota(0);

    // Remove the style pack with the style uri.
    // Note this will not remove the downloaded style pack, instead, it will
    // just mark the resources as not a part of the existing style pack. The
    // resources still exists in the disk cache.
    await _offlineManager?.removeStylePack(MapboxStyles.SATELLITE_STREETS);
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    bool isOnline = await _checkOfflineStatus();

    _offlineManager = await OfflineManager.create();
    _tileStore = await TileStore.createDefault();

    print(isOnline);

    if (!isOnline) {
      this.mapboxMap = mapboxMap;
      await _downloadStylePack();
      await _downloadTileRegion();

      mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
        ),
      );
    } else {
      this.mapboxMap = mapboxMap;

      mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
        ),
      );
    }

    mapboxMap.annotations.createPolygonAnnotationManager().then((value) {
      polygonAnnotationManager = value;

      print("------------buildingsData-----");
      print(answersList);
      print("------------buildingsData-----");
      polygonAnnotationManager?.deleteAll();

      List<Answer> tempAnswersList =
          []; 

      for (var building in buildingsData) {
        if (building['data'] != null) {
          print(building['data'].length);
          for (var item in building['data']) {
            print(item.answers);
            print(item.buildingId);
            print(item.color);
            print(item.coordinates);
            print(item.layerId);
            print(item.lastModified);

            if (item is Answer) {
              polygonAnnotationManager
                  ?.create(PolygonAnnotationOptions(
                geometry: Polygon(coordinates: [item.coordinates]),
                fillColor: int.parse("0xFF${item.color?.replaceAll('#', '')}"),
              ))
                  .then((polygonannotation) {
                print(
                    "Polygon Annotation created successfully: $polygonannotation");

             
                final newAnswer = Answer(
                  id: item.id,
                  layerId: item.layerId,
                  buildingId: item.buildingId,
                  answers: item.answers,
                  color: item.color,
                  coordinates: item.coordinates,
                  polygonAnnotation: polygonannotation,
                  lastModified: item.lastModified,
                );

                item.polygonAnnotation = polygonannotation;

               
                tempAnswersList.add(newAnswer);

              
                setState(() {
                  answersList =
                      tempAnswersList; 
                  print(answersList);
                });
              });
            }
          }
        }
      }

      print("---------------------------");
      print(answersList); 
      print("---------------------------");

      polygonAnnotationManager
          ?.addOnPolygonAnnotationClickListener(AnnotationPolygonClickListener(
        onAnnotationClick: (annotation) => {},
      ));
    });

    mapboxMap.annotations.createCircleAnnotationManager().then((value) {
      circleAnnotationManager = value;
      // var options = <CircleAnnotationOptions>[];
      // circleAnnotationManager?.createMulti(options);
      // createOneAnnotation();

      for (int index = 0; index < _locations.length; index++) {
        final location = _locations[index];
        final position = Position(
            location.lng, location.lat); 

        final circleOptions = CircleAnnotationOptions(
          geometry: Point(coordinates: position),
          circleColor: Colors.blue.value,
          circleRadius: 10.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        );

        circleAnnotationManager?.create(circleOptions).then((circle) {
          circleAnnotationsMap[index] = circle;
          setState(() {
            location.circleAnnotation = circle;
          });
        });
      }

      circleAnnotationManager
          ?.addOnCircleAnnotationClickListener(AnnotationCircleClickListener());
    });

    mapboxMap.annotations.createCircleAnnotationManager().then((value) {
      circlePathAnnotationManager = value;
      var options = <CircleAnnotationOptions>[];
      circlePathAnnotationManager?.createMulti(options);
      createOneAnnotation();
      circlePathAnnotationManager?.addOnCircleAnnotationClickListener(
          AnnotationCirclPathClickListener());
    });

    mapboxMap.annotations.createPointAnnotationManager().then((value) {
      pointNavigateAnnotationManager = value;
      var options = <CircleAnnotationOptions>[];
      circlePathAnnotationManager?.createMulti(options);
      createOneAnnotation();
      pointNavigateAnnotationManager
          ?.addOnPointAnnotationClickListener(AnnotationPointClickListener());
    });

    mapboxMap.annotations.createPointAnnotationManager().then((value) {
      pointAnnotationManager = value;

      var options = <PointAnnotationOptions>[];
      pointAnnotationManager?.createMulti(options);
      for (var layer in layers) {
       
        if (layer['id'] != null &&
            layer['id'].toString().startsWith('layer-symbol-') &&
            layer['markers'] is List) {
       
          List<dynamic> markers = layer['markers'];

          for (var marker in markers) {
            if (marker is Map<String, dynamic>) {
              _createPointAnnotation(
                  marker, marker['color'], marker['iconName']);
            }
          }
        }
      }
      createOneAnnotation();
      pointAnnotationManager
          ?.addOnPointAnnotationClickListener(AnnotationPointClickListener());
    });

    mapboxMap.annotations.createPolylineAnnotationManager().then((value) {
      polylineAnnotationManager = value;
      // createOneAnnotation();
      // final positions = <List<Position>>[];

      for (var layer in layers) {
        if (layer['id'] != null &&
            layer['id'].toString().startsWith('layer-symbol-')) {
          List<Path> paths = layer['paths'];

          for (var path in paths) {
            _createPathAnnotation(path);
          }
        }
      }

      print(relationships);
      for (Ralationship relationship in relationships) {
        print(relationship);
        if (relationship.type == 'double') {
          polylineAnnotationManager
              ?.create(PolylineAnnotationOptions(
            geometry: LineString(coordinates: relationship.points),
            lineColor: int.parse("0xFF60a5fa"),
            lineWidth: 4,
            lineGapWidth: 1,
          ))
              .then((polylineAnnotation) {
            setState(() {
              relationship.polylineAnnotation = polylineAnnotation;
            });
          }).catchError((error) {
            print('Error creating polyline: $error');
          });
        }

        if (relationship.type == 'solid') {
          polylineAnnotationManager
              ?.create(PolylineAnnotationOptions(
            geometry: LineString(coordinates: relationship.points),
            lineColor: int.parse("0xFF60a5fa"),
            lineWidth: 4,
          ))
              .then((polylineAnnotation) {
            setState(() {
              relationship.polylineAnnotation = polylineAnnotation;
            });
          }).catchError((error) {
            print('Error creating polyline: $error');
          });
        }
      }

      polylineAnnotationManager?.addOnPolylineAnnotationClickListener(
          AnnotationPolylineClickListener());
    });

    mapboxMap.annotations.createPolylineAnnotationManager().then((value) {
      polylineNavigateAnnotationManager = value;
      createOneAnnotation();

      polylineNavigateAnnotationManager?.addOnPolylineAnnotationClickListener(
          AnnotationPolylineDashClickListener());
    });

    mapboxMap.annotations.createPolylineAnnotationManager().then((value) {
      polylinedashAnnotationManager = value;
      print("passsss");

      print(relationships);
      for (Ralationship relationship in relationships) {
        print("123");
        print("passsss");
        print("passsss");
        print(relationship);
        if (relationship.type == 'dashed') {
          polylinedashAnnotationManager
              ?.create(PolylineAnnotationOptions(
            geometry: LineString(coordinates: relationship.points),
            lineColor: int.parse("0xFF60a5fa"),
            lineWidth: 4,
          ))
              .then((polylineAnnotation) {
            polylinedashAnnotationManager?.setLineDasharray([3.0, 1.0]);
            setState(() {
              relationship.polylineAnnotation = polylineAnnotation;
            });
          }).catchError((error) {
            print('Error creating polyline: $error');
          });
        }
      }

      polylinedashAnnotationManager?.addOnPolylineAnnotationClickListener(
          AnnotationPolylineDashClickListener());
    });

    mapboxMap.annotations.createPolylineAnnotationManager().then((value) {
      polylinesolidAnnotationManager = value;
      createOneAnnotation();

      polylinesolidAnnotationManager?.addOnPolylineAnnotationClickListener(
          AnnotationPolylineSolidClickListener());
    });

    mapboxMap.style.addSource(GeoJsonSource(
        id: "source",
        data:
            "https://www.mapbox.com/mapbox-gl-js/assets/earthquakes.geojson"));

    if (projectData != null) {
      _updateMapLocation();
      focusOnSelectedPoints(); 
    }
  }

  void createOneAnnotation() {
    final points = projectData!.selectedPoints
        .map((point) => Position(point.lng, point.lat))
        .toList();

 
    points.add(points.first);

    polylineAnnotationManager
        ?.create(PolylineAnnotationOptions(
          geometry: LineString(coordinates: points),
          lineColor: 0xFF699BF7,
          lineWidth: 4.0, 
        ))
        .then((value) => polylineAnnotation = value);
  }

  void _updateMapLocation() async {
    bool isOnline = await _checkOfflineStatus();
    bool isGranted = await requestLocationPermission();
    print('Is online: $isOnline');

    if (isOnline) {
      if (isGranted && mapboxMap != null) {
        try {
         
          Position? puckPosition = await mapboxMap?.style.getPuckPosition();

          if (puckPosition != null && puckPosition.length >= 2) {
            double longitude = puckPosition.lng.toDouble();
            double latitude = puckPosition.lat.toDouble();

        
            mapboxMap?.setCamera(
              CameraOptions(
                center: Point(
                  coordinates: Position(longitude, latitude),
                ),
                zoom: 16,
                bearing: 0,
                pitch: 0,
              ),
            );
          } else {
            print("Puck position is null or invalid.");
          }
        } catch (e) {
          print("Error updating map location: $e");
        }
      }
    } else {
      geolocator.LocationSettings locationSettings =
          const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 100,
      );
      geolocator.Position position =
          await geolocator.Geolocator.getCurrentPosition(
              locationSettings: locationSettings);
      print(position);

      double longitude = position.longitude.toDouble();
      double latitude = position.latitude.toDouble();

    
      mapboxMap?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(longitude, latitude),
          ),
          zoom: 16,
          bearing: 0,
          pitch: 0,
        ),
      );
    }
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
    if (projectData != null) {
      Position center = calculateCenter(projectData!.selectedPoints);
      mapboxMap!.setCamera(
        CameraOptions(
          center: Point(coordinates: center),
          zoom: 16, 
        ),
      );
    }
  }

  final TextEditingController _noteController = TextEditingController();
  List<Attachment> _selectedImages = []; 
  List<Location> _locations = [];
  List<dynamic> markers = [];
  String? _locationError;
  Map<int, CircleAnnotation?> circleAnnotationsMap = {};
  CircleAnnotation? circleAnnotation;
  CircleAnnotationManager? circleAnnotationManager;
  PointAnnotationManager? pointNavigateAnnotationManager;
  CircleAnnotationManager? circlePathAnnotationManager;

  // late MapboxMap _mapController;

  final image_picker.ImagePicker _picker =
      image_picker.ImagePicker();


  Future<void> _pickImages(int index, StateSetter setModalState) async {
    try {
      final List<image_picker.XFile> pickedFiles =
          await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        print("_pickImages");

       
        for (final file in pickedFiles) {
          final File imageFile = File(file.path);
          final fileStat = await File(file.path).stat();

          final offlinePath = await saveImageLocally(imageFile);

        
          setState(() {
            _locations[index].images?.add(
                  Attachment(
                    name: file.name,
                    type: "image/png", 
                    size: fileStat.size,
                    lastModified: fileStat.modified.millisecondsSinceEpoch,
                    url: '', 
                    offlineurl: offlinePath, 
                  ),
                );
          });

          final items = _locations.map((location) {
            return {
              "type": "position",
              "id": location.id,
              "latitude": location.lat,
              "longitude": location.lng,
              "note": location.note,
              "attachments":
                  location.images?.map((image) => image.toJson()).toList(),
            };
          }).toList();

          final user = FirebaseAuth.instance.currentUser;

          bool isOnline = await _checkOfflineStatus(); 
          print('Is online: $isOnline');
          if (isOnline) {
            for (final file in pickedFiles) {
              final uploadedUrl = await uploadImage(
                File(file.path), 
                postFileUrl(), 
              );

              if (uploadedUrl != null) {
             
                setState(() {
                  final image = _locations[index].images?.firstWhere(
                        (img) => img.name == file.name,
                      );
                  if (image != null) {
                    image.url = uploadedUrl['fileUrl']; 
                  }
                });
                saveLocationToDatabase(
                  items,
                  projectData?.projectId,
                  user?.uid,
                  _noteController.text,
                  _selectedImages.map((image) => image.toJson()).toList(),
                );
              } else {
                print('Failed to upload image: ${file.name}');
              }
            }
          }

       
          final hiveService = HiveService();
          await hiveService.putNote(projectData?.projectId, {
            "projectId": projectData?.projectId,
            "userId": userId,
            "items": items,
            "note": _noteController.text,
            "attachments":
                _selectedImages.map((image) => image.toJson()).toList(),
            "updatedAt": DateTime.now().toUtc().toIso8601String(),
          });
        }

        setModalState(() {});
      }
    } catch (e) {
      print("Error picking images: $e");
    }
  }

  Future<void> saveNoteData(
      String? projectId,
      String? userId,
      List<Map<String, dynamic>> items,
      String note,
      List<Map<String, dynamic>> attachments) async {
    final hiveService = HiveService();

    try {
      print({
        "projectId": projectId,
        "userId": userId,
        "items": items,
        "note": _noteController.text,
        "attachments": attachments,
        "updatedAt": DateTime.now().toUtc().toIso8601String(),
      });
      await hiveService.putNote(projectId, {
        "projectId": projectId,
        "userId": userId,
        "items": items,
        "note": _noteController.text,
        "attachments": attachments,
        "updatedAt": DateTime.now().toUtc().toIso8601String(),
      });

      print("Note saved successfully!");
    } catch (e) {
      print("Error saving note: $e");
    }
  }

  void _autoSave() async {
    String note = _noteController.text;
    bool isOnline = await _checkOfflineStatus();
    print('Is online: $isOnline');

    if (isOnline) {
      saveLocationToDatabase(
          _locations.map((location) {
            return {
              "type": "position",
              "id": location.id,
              "latitude": location.lat,
              "longitude": location.lng,
              "note": location.note,
              "attachments":
                  location.images?.map((image) => image.toJson()).toList(),
            };
          }).toList(),
          projectData?.projectId,
          userId,
          note,
          _selectedImages.map((image) => image.toJson()).toList());
    }

    final hiveService = HiveService();
    List<Map<String, dynamic>> items = _locations.map((location) {
      return {
        "type": "position",
        "id": location.id,
        "latitude": location.lat,
        "longitude": location.lng,
        "note": location.note,
        "attachments": location.images?.map((image) => image.toJson()).toList(),
      };
    }).toList();

    await hiveService.putNote(projectData?.projectId, {
      "projectId": projectData?.projectId,
      "userId": userId,
      "items": items,
      "note": note,
      "attachments": _selectedImages.map((image) => image.toJson()).toList(),
      "updatedAt": DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<String> downloadAndSaveFile(String url, String fileName) async {
    try {

      final response = await http.get(Uri.parse(url));

      final Directory directory = await getApplicationDocumentsDirectory();
      final String folderPath = '${directory.path}/offline_files';
      final String filePath = '$folderPath/$fileName';

      final Directory folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return file.path;
    } catch (e) {
      print("Error downloading image: $e");
      return '';
    }
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    try {

      final List<image_picker.XFile> pickedFiles =
          await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        for (final file in pickedFiles) {
          final File imageFile = File(file.path);


          Map<String, dynamic> uploadedUrl = {};
          bool isOnline = await _checkOfflineStatus();
          if (isOnline) {
            final file = await uploadImage(
              imageFile,
              postFileUrl(),
            );
            setState(() {
              uploadedUrl = file ?? {};
            });
          }

          if (uploadedUrl.isNotEmpty) {
            final fileStat = await imageFile.stat();
            final offlinePath = await downloadAndSaveFile(
                uploadedUrl['fileUrl'],
                fileStat.modified.millisecondsSinceEpoch.toString());
            setModalState(() {
              _selectedImages.add(
                Attachment(
                  name: file.name, 
                  type: "image/png", 
                  size: fileStat.size, 
                  lastModified: fileStat
                      .modified.millisecondsSinceEpoch, 
                  url: uploadedUrl['fileUrl'],
                  offlineurl: offlinePath,
                ),
              );
            });
            final items = _locations.map((location) {
              return {
                "type": "position",
                "id": location.id,
                "latitude": location.lat,
                "longitude": location.lng,
                "note": location.note,
                "attachments":
                    location.images?.map((image) => image.toJson()).toList(),
              };
            }).toList();
            final user = FirebaseAuth.instance.currentUser;
            bool isOnline = await _checkOfflineStatus();
            print('Is online: $isOnline');

            if (isOnline) {
              saveLocationToDatabase(
                  items,
                  projectData?.projectId,
                  user?.uid,
                  _noteController.text,
                  _selectedImages.map((image) => image.toJson()).toList());
            }

            final hiveService = HiveService();
            await hiveService.putNote(projectData?.projectId, {
              "projectId": projectData?.projectId,
              "userId": userId,
              "items": items,
              "note": _noteController.text,
              "attachments":
                  _selectedImages.map((image) => image.toJson()).toList(),
              "updatedAt": DateTime.now().toUtc().toIso8601String(),
            });
          } else {
            final fileStat = await imageFile.stat();
            final offlinePath = await saveImageLocally(imageFile);
            setModalState(() {
              _selectedImages.add(
                Attachment(
                  name: file.name,
                  type: "image/png", 
                  size: fileStat.size,
                  lastModified: fileStat
                      .modified.millisecondsSinceEpoch, 
                  url: "",
                  offlineurl: offlinePath, 
                ),
              );
            });
            final items = _locations.map((location) {
              return {
                "type": "position",
                "id": location.id,
                "latitude": location.lat,
                "longitude": location.lng,
                "note": location.note,
                "attachments":
                    location.images?.map((image) => image.toJson()).toList(),
              };
            }).toList();
            final user = FirebaseAuth.instance.currentUser;
            bool isOnline = await _checkOfflineStatus();
            print('Is online: $isOnline');

            final hiveService = HiveService();
            await hiveService.putNote(projectData?.projectId, {
              "projectId": projectData?.projectId,
              "userId": userId,
              "items": items,
              "note": _noteController.text,
              "attachments":
                  _selectedImages.map((image) => image.toJson()).toList(),
              "updatedAt": DateTime.now().toUtc().toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      print("Error picking images: $e");
    }
  }

  Future<void> _openCamera(Function setModalState) async {
    // final image_picker.ImagePicker _picker = image_picker.ImagePicker();

    final image_picker.XFile? image =
        await _picker.pickImage(source: image_picker.ImageSource.camera);

    bool isOnline = await _checkOfflineStatus();
    if (isOnline) {
      if (image != null) {
        final File imageFile = File(image.path);

       
        final uploadedUrl = await uploadImage(
          imageFile,
          postFileUrl(), 
        );

        if (uploadedUrl != null) {
          print(uploadedUrl);

         
          final fileStat = await imageFile.stat();

          final offlinePath = await downloadAndSaveFile(uploadedUrl['fileUrl'],
              fileStat.modified.millisecondsSinceEpoch.toString());
          setModalState(() {
            _selectedImages.add(
              Attachment(
                name: image.name, 
                type: "image/png", 
                size: fileStat.size, 
                lastModified: fileStat
                    .modified.millisecondsSinceEpoch, 
                url: uploadedUrl['fileUrl'],
                offlineurl: offlinePath,
              ),
            );
          });
          final items = _locations.map((location) {
            return {
              "type": "position",
              "id": location.id,
              "latitude": location.lat,
              "longitude": location.lng,
              "note": location.note,
              "attachments":
                  location.images?.map((image) => image.toJson()).toList(),
            };
          }).toList();
          final user = FirebaseAuth.instance.currentUser;
          bool isOnline = await _checkOfflineStatus();
          print('Is online: $isOnline');

          if (isOnline) {
            saveLocationToDatabase(
                items,
                projectData?.projectId,
                user?.uid,
                _noteController.text,
                _selectedImages.map((image) => image.toJson()).toList());
          }

          final hiveService = HiveService();
          await hiveService.putNote(projectData?.projectId, {
            "projectId": projectData?.projectId,
            "userId": userId,
            "items": items,
            "note": _noteController.text,
            "attachments":
                _selectedImages.map((image) => image.toJson()).toList(),
            "updatedAt": DateTime.now().toUtc().toIso8601String(),
          });
        } else {
          print('Failed to upload image: ${image.name}');
        }
      }
    } else {
      if (image != null) {
        final File imageFile = File(image.path);

      
        final fileStat = await imageFile.stat();

     
        final offlinePath = await saveImageLocally(imageFile);
        setModalState(() {
          _selectedImages.add(
            Attachment(
              name: image.name, 
              type: "image/png", 
              size: fileStat.size, 
              lastModified: fileStat
                  .modified.millisecondsSinceEpoch, 
              url: "",
              offlineurl: offlinePath,
            ),
          );
        });
        final items = _locations.map((location) {
          return {
            "type": "position",
            "id": location.id,
            "latitude": location.lat,
            "longitude": location.lng,
            "note": location.note,
            "attachments":
                location.images?.map((image) => image.toJson()).toList(),
          };
        }).toList();
        final user = FirebaseAuth.instance.currentUser;
        bool isOnline = await _checkOfflineStatus();
        print('Is online: $isOnline');

        final hiveService = HiveService();
        await hiveService.putNote(projectData?.projectId, {
          "projectId": projectData?.projectId,
          "userId": userId,
          "items": items,
          "note": _noteController.text,
          "attachments":
              _selectedImages.map((image) => image.toJson()).toList(),
          "updatedAt": DateTime.now().toUtc().toIso8601String(),
        });
      } else {}
    }
    setModalState(() {});
  }

  Future<void> _openCameraModal(int index, Function setModalState) async {
    final image_picker.XFile? image =
        await _picker.pickImage(source: image_picker.ImageSource.camera);
    final File imageFile = File(image!.path);
    final fileStat = await File(image.path).stat();

    final offlinePath = await saveImageLocally(imageFile);

   
    setState(() {
      _locations[index].images?.add(
            Attachment(
              name: image.name,
              type: "image/png", 
              size: fileStat.size,
              lastModified: fileStat.modified.millisecondsSinceEpoch,
              url: '', 
              offlineurl: offlinePath, 
            ),
          );
    });
    final items = _locations.map((location) {
      return {
        "type": "position",
        "id": location.id,
        "latitude": location.lat,
        "longitude": location.lng,
        "note": location.note,
        "attachments": location.images?.map((image) => image.toJson()).toList(),
      };
    }).toList();

    final user = FirebaseAuth.instance.currentUser;

    bool isOnline = await _checkOfflineStatus(); 
    print('Is online: $isOnline');

    
    if (isOnline) {
      final uploadedUrl = await uploadImage(
        File(image.path),
        postFileUrl(), 
      );

      if (uploadedUrl != null) {
     
        setState(() {
          final img = _locations[index].images?.firstWhere(
                (img) => img.name == image.name,
              );
          if (img != null) {
            img.url = uploadedUrl['fileUrl']; 
          }
        });

      
        saveLocationToDatabase(
          items,
          projectData?.projectId,
          user?.uid,
          _noteController.text,
          _selectedImages.map((image) => image.toJson()).toList(),
        );
      } else {}
    }

   
    final hiveService = HiveService();
    await hiveService.putNote(projectData?.projectId, {
      "projectId": projectData?.projectId,
      "userId": userId,
      "items": items,
      "note": _noteController.text,
      "attachments": _selectedImages.map((image) => image.toJson()).toList(),
      "updatedAt": DateTime.now().toUtc().toIso8601String(),
    });
  }

  //  Future<void> _openCameraSub() async {
  //   final image_picker.XFile? image =
  //       await _picker.pickImage(source: image_picker.ImageSource.camera);

  //   setState(() {
  //     pickedImage = image; // Update the picked image in the state
  //   });
  // }

  Future<String> saveImageLocally(File imageFile) async {
    try {
      final directory =
          await getApplicationDocumentsDirectory(); 
      final path =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';

      
      await imageFile.copy(path);
      return path; 
    } catch (e) {
      print("Error saving image locally: $e");
      return '';
    }
  }


  void _removeImage(
      Attachment image, int locationIndex, StateSetter setModalState) async {
    setState(() {
      _locations[locationIndex]
          .images
          ?.removeWhere((attachment) => attachment.url == image.url);
    });
    setModalState(() {});
    final items = _locations.map((location) {
      return {
        "type": "position",
        "id": location.id,
        "latitude": location.lat,
        "longitude": location.lng,
        "note": location.note,
        "attachments": location.images?.map((image) => image.toJson()).toList(),
      };
    }).toList();
    final user = FirebaseAuth.instance.currentUser;
    // List<String> uploadedUrls = [];

    // // อัปโหลดไฟล์ทั้งหมดใน _selectedImages และเก็บ URL ที่ได้
    // for (var image in _selectedImages) {
    //   final uploadedUrl = await uploadImage(
    //     File(image.url), // ไฟล์ที่ต้องการอัปโหลด
    //     postFileUrl(), // URL สำหรับการอัปโหลด
    //   );

    //   uploadedUrls.add(uploadedUrl?['fileUrl']); // เก็บ URL ที่อัปโหลดแล้ว
    // }
    // for (int i = 0; i < _selectedImages.length; i++) {
    //   _selectedImages[i].url =
    //       uploadedUrls[i]; // ตั้งค่า URL ของไฟล์ใน _selectedImages
    // }

    bool isOnline = await _checkOfflineStatus();
    print('Is online: $isOnline');

    if (isOnline) {
      saveLocationToDatabase(
          items,
          projectData?.projectId,
          user?.uid,
          _noteController.text,
          _selectedImages.map((image) => image.toJson()).toList());
    }

    final hiveService = HiveService();
    await hiveService.putNote(projectData?.projectId, {
      "projectId": projectData?.projectId,
      "userId": userId,
      "items": items,
      "note": _noteController.text,
      "attachments": _selectedImages.map((image) => image.toJson()).toList(),
      "updatedAt": DateTime.now().toUtc().toIso8601String(),
    });
  }


  Future<void> _getCurrentLocation(StateSetter setModalState) async {
    if (_isSymbolLayerModalOpen == true) return;
    try {
      bool serviceEnabled =
          await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "โปรดเปิด GPS เพื่อใช้งาน";
        });
        setModalState(() {});
        return;
      }

      geolocator.LocationPermission permission =
          await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission == geolocator.LocationPermission.denied) {
          setState(() {
            _locationError = "สิทธิ์การใช้งาน GPS ถูกปฏิเสธ";
          });
          setModalState(() {});
          return;
        }
      }

      if (permission == geolocator.LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              "สิทธิ์การใช้งาน GPS ถูกปฏิเสธอย่างถาวร โปรดตั้งค่าใหม่";
        });
        setModalState(() {}); 
        return;
      }

      final Position? position = await mapboxMap?.style.getPuckPosition();

      final index = _locations.length - 1;
      final user = FirebaseAuth.instance.currentUser;
      if (position != null) {
        final circleOptions = CircleAnnotationOptions(
          geometry: Point(coordinates: Position(position.lng, position.lat)),
          circleColor: Colors.blue.value,
          circleRadius: 10.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        );

        circleAnnotationManager?.create(circleOptions).then((circle) async {
          circleAnnotationsMap[index] = circle;
          bool isOnline = await _checkOfflineStatus();
          print('Is online: $isOnline');

          setModalState(() {
            setState(() {
              final id = generateNoteId();
              final newLocation = Location(
                type: "position",
                id: id,
                lat: position.lat.toDouble(),
                lng: position.lng.toDouble(),
                note: '',
                images: [], //
                circleAnnotation: circle,
              );

              _locations.add(newLocation);

              final items = _locations.map((location) {
                return {
                  "type": "position",
                  "id": location.id,
                  "latitude": location.lat,
                  "longitude": location.lng,
                  "note": location.note,
                  "attachments":
                      location.images?.map((image) => image.toJson()).toList(),
                };
              }).toList();

              if (isOnline) {
                saveLocationToDatabase(
                    items,
                    projectData?.projectId,
                    user?.uid,
                    _noteController.text,
                    _selectedImages.map((image) => image.toJson()).toList());
              }

              saveNoteData(
                  projectData?.projectId,
                  user?.uid,
                  items,
                  _noteController.text,
                  _selectedImages.map((image) => image.toJson()).toList());
            });
          });
        });
      }

      // _addMarker(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _locationError = "เกิดข้อผิดพลาด: $e";
      });
      setModalState(() {});
    }
  }


  void _createCircleAnnotation(double latitude, double longitude) {
    if (_isSymbolLayerModalOpen == true) return;
    if (circleAnnotationManager == null) return;

    
    circleAnnotationManager!.deleteAll();
    circleAnnotationsMap.clear();

 
    final circleOptions = CircleAnnotationOptions(
      geometry: Point(coordinates: Position(longitude, latitude)),
      circleColor: Colors.blue.value,
      circleRadius: 10.0,
      circleStrokeColor: Colors.white.value,
      circleStrokeWidth: 2.0,
    );

    circleAnnotationManager?.create(circleOptions).then((circle) {
     
      circleAnnotationsMap[0] = circle; 
    });
  }

  Widget _setFeatureState() {
    return TextButton(
      child: const Text('setFeatureState'),
      onPressed: () {
        mapboxMap?.setFeatureState(
            'source', null, 'point', json.encode({'choose': true}));
      },
    );
  }

  Widget _queryRenderedFeatures() {
    return TextButton(
      child: const Text('queryRenderedFeatures'),
      onPressed: () {
        final screenBox = ScreenBox(
            min: ScreenCoordinate(x: 0.0, y: 0.0),
            max: ScreenCoordinate(x: 150.0, y: 510.0));
        final screenCoordinate = ScreenCoordinate(x: 150.0, y: 510);
        final renderedQueryGeometry = RenderedQueryGeometry(
            value: jsonEncode(screenCoordinate.encode()),
            type: Type.SCREEN_COORDINATE);
        mapboxMap
            ?.queryRenderedFeatures(
                renderedQueryGeometry,
                RenderedQueryOptions(
                    layerIds: ['point', 'custom'], filter: null))
            .then((value) =>
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("queryRenderedFeatures size: ${value.length}"),
                  backgroundColor: Theme.of(context).primaryColor,
                  duration: const Duration(seconds: 2),
                )));
      },
    );
  }

  Widget _getFeatureState() {
    return TextButton(
      child: const Text('getFeatureState'),
      onPressed: () {
        mapboxMap?.getFeatureState('source', null, 'point').then(
            (value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("FeatureState: $value"),
                  backgroundColor: Theme.of(context).primaryColor,
                  duration: const Duration(seconds: 2),
                )));
      },
    );
  }

  void _onMapTapped(MapContentGestureContext context) async {

    if (_isSymbolLayerModalOpen == true && selectedMode == 'เพิ่มสัญลักษณ์') {
      final lng = context.point.coordinates.lng;
      final lat = context.point.coordinates.lat;
      setState(() {
        setState(() {
          Map<String, dynamic>? nearestLocation =
              _findNearestIcon(Position(lng, lat));
          print("nearestLocation");
          print(nearestLocation);

          if (nearestLocation != null) {
            _showMarkerPopup(nearestLocation);
          } else {
            print("No marker nearby.");
            createNewPointAnnotation(Position(lng, lat));
            print(markers);
          }
          print("Tapped coordinates: {lng: $lng, lat: $lat}");
        });
      });
      return;
    }

    if (_isFormLayerModalOpen == true && selectedMode == 'กรอกแบบฟอร์ม') {
      try {
        final screenCoordinate = ScreenCoordinate(
          x: context.touchPosition.x,
          y: context.touchPosition.y,
        );

        print("OnTap coordinate: {${context.point.coordinates.lng}, ${context.point.coordinates.lat}}" " point: {x: ${context.touchPosition.x}, y: ${context.touchPosition.y}}");


        final screenBox =
            ScreenBox(min: screenCoordinate, max: screenCoordinate);
        final renderedQueryGeometry = RenderedQueryGeometry(
          type: Type.SCREEN_BOX,
          value: jsonEncode(screenBox.encode()),
        );

        final features = await mapboxMap?.queryRenderedFeatures(
          renderedQueryGeometry,
          RenderedQueryOptions(
            layerIds: ['building'],
            filter: null,
          ),
        );

        if (features != null) {
          print(features.first?.queriedFeature.feature);
          _showFormPopup(features.first?.queriedFeature.feature);
        }
      } catch (e) {
        debugPrint('Error selecting building: $e');
      }
      return;
    }

    if (_isSymbolLayerModalOpen == true && selectedMode == 'เพิ่มเส้นทาง') {
      final lng = context.point.coordinates.lng;
      final lat = context.point.coordinates.lat;

      const double tolerance = 0.00001; 
      bool isNearExistingPoint = polylineCoordinates.any((coord) =>
          (coord.lat - lat).abs() < tolerance &&
          (coord.lng - lng).abs() < tolerance);

      bool isNearExistingPath = existingPaths.any((path) {
        return path.points.any((coord) =>
            (coord.lat - lat).abs() < tolerance &&
            (coord.lng - lng).abs() < tolerance);
      });
      print('Is near existing point: $isNearExistingPoint');
      print('Is near existing path: $isNearExistingPath');

      setState(() {
        setState(() {
          if (isNearExistingPoint && polylineCoordinates.isNotEmpty) {
            createPolylineFromCoordinates(polylineCoordinates);
            circlePathAnnotationManager?.deleteAll();
          } else if (isNearExistingPoint) {
            final selectedPath = existingPaths.firstWhere((path) => path.points
                .any((coord) =>
                    (coord.lat - lat).abs() < tolerance &&
                    (coord.lng - lng).abs() < tolerance));
            _showPathPopup(selectedPath);
          } else if (isNearExistingPath) {
            final selectedPath = existingPaths.firstWhere((path) => path.points
                .any((coord) =>
                    (coord.lat - lat).abs() < tolerance &&
                    (coord.lng - lng).abs() < tolerance));
            _showPathPopup(selectedPath);
          } else {
            polylineCoordinates.add(Position(lng, lat));
            final circleOptions = CircleAnnotationOptions(
              geometry: Point(coordinates: Position(lng, lat)),
              circleColor: Colors.blue.value,
              circleRadius: 5.0,
              circleStrokeColor: Colors.white.value,
              circleStrokeWidth: 2.0,
            );

            circlePathAnnotationManager?.create(circleOptions).then((circle) {
           
              circleAnnotationsMap[0] = circle; 
            });
          }
        });
      });
      return;
    }
    if (_isRelationshipLayerModalOpen == true &&
        selectedMode == 'เพิ่มความสัมพันธ์') {
      final lng = context.point.coordinates.lng;
      final lat = context.point.coordinates.lat;

      const double tolerance = 0.00001;

      setState(() {
        if (relationshipCoordinates.length > 2) {
          relationshipCoordinates.clear();
        }
        bool isNearExistingPoint = relationshipCoordinates.any((coord) =>
            (coord.lat - lat).abs() < tolerance &&
            (coord.lng - lng).abs() < tolerance);

        bool isNearExistingPath = relationships.any((relationship) {
          for (int i = 0; i < relationship.points.length - 1; i++) {
            final start = relationship.points[i];
            final end = relationship.points[i + 1];

            if (_isPointNearLineSegment(
                Position(lng, lat), start, end, tolerance)) {
              return true;
            }
          }
          return false; 
        });
        if (!isNearExistingPoint && !isNearExistingPath) {
          relationshipCoordinates.add(Position(lng, lat));
        }
        print(relationshipCoordinates);
        if (relationshipCoordinates.length == 2) {
          print(relationshipCoordinates);
          createRelationshipFromCoordinates(relationshipCoordinates);
        } else if (isNearExistingPoint) {
          final selectedPath = relationships.firstWhere((relationship) =>
              relationship.points.any((coord) =>
                  (coord.lat - lat).abs() < tolerance &&
                  (coord.lng - lng).abs() < tolerance));
          _showRelationshipPopup(selectedPath);
        } else if (isNearExistingPath) {
         
          final selectedPath = relationships.firstWhere((relationship) {
            for (int i = 0; i < relationship.points.length - 1; i++) {
              final start = relationship.points[i];
              final end = relationship.points[i + 1];
              if (_isPointNearLineSegment(
                  Position(lng, lat), start, end, tolerance)) {
                return true;
              }
            }
            return false;
          });

          _showRelationshipPopup(selectedPath); 
                }
      });
      return;
    }

    if (_isNavigateLayerModalOpen) {
      final lng = context.point.coordinates.lng;
      final lat = context.point.coordinates.lat;
      polylineNavigateAnnotationManager?.deleteAll();
      pointNavigateAnnotationManager?.deleteAll();
      _navigateToLocation(Position(lng, lat));
      print("_isNavigateLayerModalOpen");
      return;
    }

    setState(() {
      final lng = context.point.coordinates.lng;
      final lat = context.point.coordinates.lat;

      print("Tapped coordinates: {lng: $lng, lat: $lat}");

    
      final Location? nearestLocation = _findNearestPoint(Position(lng, lat));

      if (nearestLocation != null) {
     
        _showPopup(nearestLocation, null, null);
      } else {
        print("No marker nearby.");
        _createNewMarker(Position(lng, lat));
      }
    });
  }

  StreamSubscription<geolocator.Position>? _locationSubscription;
  final StreamController<geolocator.Position> _userLocationStreamController =
      StreamController<geolocator.Position>.broadcast();

 
  Stream<geolocator.Position> get userLocationStream =>
      _userLocationStreamController.stream;

  void stopListeningToLocationChanges() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _navigateToLocation(Position destination) async {
    try {
      String accessToken = await MapboxOptions.getAccessToken();
      final Position? pos = await mapboxMap?.style.getPuckPosition();
      print(pos);

      if (pos == null) {
        print('Current position not available.');
        return;
      }

      final start = await mapboxMap?.style.getPuckPosition();
      if (start == null) {
        return;
      }

      final coordinates =
          await fetchRouteCoordinates(start, destination, accessToken);

      if (coordinates.isNotEmpty) {
        drawRouteLowLevel(coordinates);
        pinDestination(destination);
      } else {
        print('No route coordinates found.');
      }
    } catch (e) {
      print('Error while navigating: $e');
    }
  }

  void pinDestination(Position destination) async {
    final ByteData bytes = await rootBundle.load('assets/symbols/pin.png');
    final dynamic imageData = bytes.buffer.asUint8List();

    pointNavigateAnnotationManager?.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(destination.lng, destination.lat)),
      // iconImage: "airport-15", 
      iconSize: 0.2,
      textColor: Colors.red.value,
      // symbolSortKey: 10,
      iconOffset: [1, -1],
      image: imageData,
    ));
  }

  double _totalDistance = 0.0;
  void drawRouteLowLevel(List<Position> polyline) async {
    try {
      if (polylineNavigateAnnotationManager == null) {
        print('PolylineAnnotationManager is not initialized.');
        return;
      }

      double totalDistance = 0.0;
      for (int i = 0; i < polyline.length - 1; i++) {
        totalDistance += _calculateDist(polyline[i], polyline[i + 1]);
      }
      setState(() {
        _totalDistance = totalDistance;
      });
      print('Total route distance: ${_totalDistance.toStringAsFixed(2)} km');

      final line = LineString(coordinates: polyline);
      print(line.encode());

      polylineNavigateAnnotationManager!.create(PolylineAnnotationOptions(
        geometry: line,
        lineColor: int.parse("0xFF60a5fa"),
        lineBorderColor: int.parse("0xFF5694e1"),
        lineBorderWidth: 2,
        lineWidth: 7,
      ));

      print('Route drawn successfully.');
    } catch (e) {
      print('Error while drawing route: $e');
    }
  }

  double _calculateDist(Position pos1, Position pos2) {
    const double earthRadiusKm = 6371.0;

    double lat1 = pos1.lat.toDouble(); 
    double lon1 = pos1.lng.toDouble(); 
    double lat2 = pos2.lat.toDouble(); 
    double lon2 = pos2.lng.toDouble(); 

    double dLat = _degreeToRadian(lat2 - lat1);
    double dLon = _degreeToRadian(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) *
            cos(_degreeToRadian(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

  bool _isPointNearLineSegment(
      Position point, Position lineStart, Position lineEnd, double tolerance) {
    final double x0 = point.lng.toDouble();
    final double y0 = point.lat.toDouble();
    final double x1 = lineStart.lng.toDouble();
    final double y1 = lineStart.lat.toDouble();
    final double x2 = lineEnd.lng.toDouble();
    final double y2 = lineEnd.lat.toDouble();


    final double dx = x2 - x1;
    final double dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return _distanceBetweenPoints(point, lineStart) <= tolerance;
    }

    final double t = (((x0 - x1) * dx + (y0 - y1) * dy) / (dx * dx + dy * dy))
        .clamp(0.0, 1.0);

    final double closestX = x1 + t * dx;
    final double closestY = y1 + t * dy;

 
    return _distanceBetweenPoints(point, Position(closestX, closestY)) <=
        tolerance;
  }

  double _distanceBetweenPoints(Position p1, Position p2) {
    final double dx = (p1.lng - p2.lng).toDouble();
    final double dy = (p1.lat - p2.lat).toDouble();
    return sqrt(dx * dx + dy * dy);
  }

  void createRelationshipFromCoordinates(List<Position> coordinates) async {
    bool isOnline = await _checkOfflineStatus();
    print(isOnline);
    if (selectedLinePattern == 'เส้นขนาน') {
      polylineAnnotationManager
          ?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: int.parse("0xFF60a5fa"),
        lineWidth: 4,
        lineGapWidth: 1,
      ))
          .then((polylineAnnotation) {
        print(polylineAnnotation);
        final newRelationship = Ralationship(
          id: polylineAnnotation.id, 
          description: "คำอธิบายเส้นทาง",
          layerId: _selectedLayer?['id'],
          type: 'double',
          points: List.from(coordinates),
          polylineAnnotation: polylineAnnotation,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        List<List<num>> pointsList = newRelationship.points
            .map((position) =>
                [position.lng.toDouble(), position.lat.toDouble()])
            .toList();

        List<List<double>> pointsListAsDouble = pointsList
            .map((point) => point.map((e) => e.toDouble()).toList())
            .toList();

        final user = FirebaseAuth.instance.currentUser;
        // bool isOnline = await _checkOfflineStatus();
        if (isOnline) {
          createRelationship(
            id: newRelationship.id,
            layerId: _selectedLayer?['id'],
            points: pointsListAsDouble,
            userId: user?.uid,
            type: newRelationship.type,
            description: newRelationship.description,
            projectId: projectData?.projectId,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          );
        }

        setState(() {
          relationships
              .add(newRelationship);
          relationshipCoordinates.clear(); 
        });

        print(relationships);
        final toHive = {
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false,
        };
       
        uploadtoHive(newRelationship.id, {
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false,
        });
      }).catchError((error) {
        print("Failed to create polyline: $error");
      });
    } else if (selectedLinePattern == 'เส้นทึบ') {
      polylineAnnotationManager
          ?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: int.parse("0xFF60a5fa"),
        lineWidth: 4,
      ))
          .then((polylineAnnotation) async {
        final newRelationship = Ralationship(
          id: polylineAnnotation.id, 
          description: "คำอธิบายเส้นทาง",
          layerId: _selectedLayer?['id'],
          type: 'solid',
          points: List.from(coordinates),
          polylineAnnotation: polylineAnnotation,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
        List<List<num>> pointsList = newRelationship.points
            .map((position) =>
                [position.lng.toDouble(), position.lat.toDouble()])
            .toList();

        List<List<double>> pointsListAsDouble = pointsList
            .map((point) => point.map((e) => e.toDouble()).toList())
            .toList();

        final user = FirebaseAuth.instance.currentUser;

        bool isOnline = await _checkOfflineStatus();
        if (isOnline) {
          createRelationship(
            id: newRelationship.id,
            layerId: _selectedLayer?['id'],
            points: pointsListAsDouble,
            userId: user?.uid,
            type: newRelationship.type,
            description: newRelationship.description,
            projectId: projectData?.projectId,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          );
        }

        setState(() {
          relationships.add(newRelationship);
          relationshipCoordinates.clear();
        });
        print(relationships);
        final toHive = {
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false,
        };
        uploadtoHive(newRelationship.id, {
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false,
        });
      }).catchError((error) {
        print("Failed to create polyline: $error");
      });
    } else if (selectedLinePattern == 'เส้นประ') {
      polylinedashAnnotationManager
          ?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: int.parse("0xFF60a5fa"),
        lineWidth: 4,
      ))
          .then((polylineAnnotation) async {
        polylinedashAnnotationManager?.setLineDasharray([3.0, 1.0]);
        final newRelationship = Ralationship(
          id: polylineAnnotation.id,
          description: "คำอธิบายเส้นทาง",
          layerId: _selectedLayer?['id'],
          type: 'dashed',
          points: List.from(coordinates),
          polylineAnnotation: polylineAnnotation,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
        List<List<num>> pointsList = newRelationship.points
            .map((position) =>
                [position.lng.toDouble(), position.lat.toDouble()])
            .toList();

        List<List<double>> pointsListAsDouble = pointsList
            .map((point) => point.map((e) => e.toDouble()).toList())
            .toList();

        final user = FirebaseAuth.instance.currentUser;

        bool isOnline = await _checkOfflineStatus();
        if (isOnline) {
          createRelationship(
            id: newRelationship.id,
            layerId: _selectedLayer?['id'],
            points: pointsListAsDouble,
            userId: user?.uid,
            type: newRelationship.type,
            description: newRelationship.description,
            projectId: projectData?.projectId,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          );
        }

        setState(() {
          relationships.add(newRelationship);
          relationshipCoordinates.clear();
        });

        final toHive = {
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false,
        };
        print({
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false
        });
        uploadtoHive(newRelationship.id, {
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false
        });
      }).catchError((error) {
        print("Failed to create polyline: $error");
      });
    } else if (selectedLinePattern == 'เส้นซิกแซก') {
      polylinedashAnnotationManager
          ?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: int.parse("0xFF60a5fa"),
        lineWidth: 4,
      ))
          .then((polylineAnnotation) async {
        polylinedashAnnotationManager?.setLineDasharray([3.0, 1.0]);
        final newRelationship = Ralationship(
          id: polylineAnnotation.id,
          description: "คำอธิบายเส้นทาง",
          layerId: _selectedLayer?['id'],
          type: 'zigzag',
          points: List.from(coordinates),
          polylineAnnotation: polylineAnnotation,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
        List<List<num>> pointsList = newRelationship.points
            .map((position) =>
                [position.lng.toDouble(), position.lat.toDouble()])
            .toList();

        List<List<double>> pointsListAsDouble = pointsList
            .map((point) => point.map((e) => e.toDouble()).toList())
            .toList();

        final user = FirebaseAuth.instance.currentUser;
        bool isOnline = await _checkOfflineStatus();
        if (isOnline) {
          createRelationship(
            id: newRelationship.id,
            layerId: _selectedLayer?['id'],
            points: pointsListAsDouble,
            userId: user?.uid,
            type: newRelationship.type,
            description: newRelationship.description,
            projectId: projectData?.projectId,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          );
        }

        setState(() {
          relationships.add(newRelationship);
          relationshipCoordinates.clear();
        });
        print(relationships);

        final toHive = {
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false,
        };
        uploadtoHive(newRelationship.id, {
          'id': newRelationship.id,
          'layerId': _selectedLayer?['id'],
          'points': newRelationship.points
              .map((position) =>
                  [position.lng.toDouble(), position.lat.toDouble()])
              .toList()
              .map((point) => point.map((e) => e.toDouble()).toList())
              .toList(),
          'userId': user?.uid,
          'type': newRelationship.type,
          'projectId': projectData?.projectId,
          'description': newRelationship.description,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'isDelete': false,
        });
      }).catchError((error) {
        print("Failed to create polyline: $error");
      });
    }
  }

  void uploadtoHive(String relationshipId, Map<String, dynamic> toHive) async {
    final hiveService = HiveService();
    await hiveService.putRelationship(relationshipId, toHive);
  }

  Future checkOnline() async {
    bool isOnline = await _checkOfflineStatus();
    print('Is online: $isOnline');
    return isOnline;
  }

  void _showFormPopup(Map<String?, Object?>? form) {
    print("-----------_showFormPopup---------------");
    print(form);
    final featuresDataMap = form as Map<String?, Object?>;

    final geometry = featuresDataMap['geometry'] as Map<Object?, Object?>;
    final coordinates = geometry['coordinates'] as List<Object?>;

    final List<List<Position>> positionCoordinates =
        coordinates.map((coordinateList) {
      return (coordinateList as List<dynamic>).map((coordinate) {
      
        final longitude = coordinate[0] as double;
        final latitude = coordinate[1] as double;
        return Position(longitude, latitude);
      }).toList();
    }).toList();

    int parseHexColor(String hexColor) {
      
      hexColor = hexColor.replaceAll('#', '');
   
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; 
      }
      return int.parse(hexColor, radix: 16);
    }

    final Map<String, dynamic> answers = {};

    if (_selectedLayer?["questions"] != null) {
      for (var question in _selectedLayer!["questions"]) {
        if (question['type'] == 'multiple_choice') {
          answers[question['id'].toString()] =
              ''; 
        } else if (question['type'] == 'checkbox') {
          answers[question['id'].toString()] =
              <String>[];
        } else {
          answers[question['id'].toString()] =
              ''; 
        }
      }
    }

    final buildingId = form["id"].toString();

    final existingAnswer = answersList.firstWhere(
      (a) => a.buildingId == buildingId && a.layerId == _selectedLayer?['id'],
      orElse: () => Answer(
          id: generateBuildingLayerId(),
          layerId: _selectedLayer?['id'], 
          buildingId: buildingId,
          answers: {},
          color: "", 
          coordinates: [], 
          polygonAnnotation: null, 
          lastModified: DateTime.now().toUtc().toIso8601String()),
    );

    print(existingAnswer.answers);

    existingAnswer.answers.forEach((key, value) {
      final questionType = _selectedLayer!["questions"]
          .firstWhere((q) => q['id'] == key.toString())['type'];

      answers[key.toString()] = questionType == 'multiple_choice'
          ? value 
          : questionType == 'checkbox'
              ? value.split(',') 
              : value; 
    });
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Center(
                      child: Text(
                        _selectedLayer?['title'] ?? 'No Title Available',
                        style: GoogleFonts.sarabun(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF699BF7),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedLayer?["questions"] != null)
                              for (var question in _selectedLayer!["questions"])
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            question['label'] ??
                                                'No question text available',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          if (question['showOnMap'] ==
                                              true) 
                                            Text(
                                              '*แสดงบนแผนที่',
                                              style: GoogleFonts.sarabun(
                                                textStyle: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(
                                                      0xFF699BF7), 
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (question['type'] == 'text')
                                        TextField(
                                          onChanged: (value) {
                                            setModalState(() {
                                              answers[question['id']] = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText: question['label'],
                                            hintStyle: GoogleFonts.sarabun(
                                              textStyle: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[
                                                    600],
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 12.0,
                                            ),
                                          ),
                                          style: GoogleFonts.sarabun(
                                           
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              color: Colors
                                                  .black, 
                                            ),
                                          ),
                                        ),
                                      if (question['type'] == 'number')
                                        TextField(
                                          keyboardType: TextInputType
                                              .number,
                                          onChanged: (value) {
                                            setModalState(() {
                                              answers[question['id']] =
                                                  double.tryParse(value) ?? 0;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'กรอกข้อมูลที่นี่',
                                            hintStyle: GoogleFonts.sarabun(
                                              textStyle: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[
                                                    600], 
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: 12.0,
                                            ),
                                          ),
                                          style: GoogleFonts.sarabun(
                                          
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              color: Colors
                                                  .black, 
                                            ),
                                          ),
                                        ),
                                      if (question['type'] ==
                                          'multiple_choice') ...[
                                        Column(
                                          children: question['options']
                                              .asMap()
                                              .entries
                                              .map<Widget>((entry) {
                                            int index = entry.key;
                                            var option = entry.value;

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0.0),
                                              child: RadioListTile<String>(
                                                title: Text(
                                                  option['label'] ??
                                                      'Option $index',
                                                  style: GoogleFonts.sarabun(
                                                   
                                                    textStyle: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                value: option['value']
                                                    .toString(),
                                                groupValue: answers[
                                                        question['id']
                                                            .toString()]
                                                    ?.toString(), 
                                                onChanged: (value) {
                                                  setModalState(() {
                                                    answers[question['id']
                                                        .toString()] = value;
                                                  });
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                      if (question['type'] == 'checkbox') ...[
                                        Column(
                                          children: question['options']
                                              .asMap()
                                              .entries
                                              .map<Widget>((entry) {
                                            int index = entry.key;
                                            var option = entry.value;

                                            return CheckboxListTile(
                                              title: Text(
                                                option['label'] ??
                                                    'Option $index',
                                                style: GoogleFonts.sarabun(
                                                 
                                                  textStyle: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              value: (answers[question['id']
                                                          .toString()] ??
                                                      [])
                                                  .contains(option['value']),
                                              onChanged: (bool? value) {
                                                setModalState(() {
                                                  List<String> selectedOptions =
                                                      List<String>.from(answers[
                                                              question['id']
                                                                  .toString()] ??
                                                          []);
                                                  if (value == true) {
                                                    selectedOptions
                                                        .add(option['value']);
                                                  } else {
                                                    selectedOptions.remove(
                                                        option['value']);
                                                  }
                                                  answers[question['id']
                                                          .toString()] =
                                                      selectedOptions;
                                                });
                                              },
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width *
                              0.44,
                          child: ElevatedButton(
                            onPressed: () {
                              setModalState(() {
                                if (_selectedLayer?["questions"] != null) {
                                  for (var question
                                      in _selectedLayer!["questions"]) {
                            
                                    if (question['type'] == 'text' ||
                                        question['type'] == 'number') {
                                      question['answer'] =
                                          ''; 
                                    }
                                    if (question['type'] == 'multiple_choice') {
                                      question['selectedOption'] =
                                          -1; 
                                    }
                                    if (question['type'] == 'checkbox') {
                                      for (var option
                                          in question['options'] ?? []) {
                                        option['selected'] =
                                            false; 
                                      }
                                    }
                                  }
                                }
                              });
                              Navigator.of(context).pop(); 
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.grey.shade300, 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'ยกเลิก',
                              style: GoogleFonts.sarabun(
                                textStyle: TextStyle(
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width *
                              0.44,
                          child: ElevatedButton(
                            onPressed: () async {
                              String? selectedCircleColor;
                              _selectedLayer?["questions"]?.forEach((question) {
                                if (question['showOnMap'] == true &&
                                    question['type'] == 'multiple_choice') {
                                  dynamic answerValue = answers[question['id']];
                                  print(answerValue);
                                  int? selectedIndex;

                                  if (answerValue != null) {
                                   
                                    for (int i = 0;
                                        i < question['options'].length;
                                        i++) {
                                      if (question['options'][i]['value'] ==
                                          answerValue) {
                                        selectedIndex = i;
                                        selectedCircleColor =
                                            question['options'][selectedIndex]
                                                ['color'];
                                        break;
                                      }
                                    }
                                  }
                                }
                              });
                              final int fillColor = parseHexColor(
                                  selectedCircleColor ??
                                      "#FFFFFF"); 

                              final buildingId =
                                  featuresDataMap["id"].toString();

                            
                              final existingAnswerIndex =
                                  answersList.indexWhere(
                                      (a) => a.buildingId == buildingId);

                              if (existingAnswerIndex != -1) {
                           
                                final existingAnswer =
                                    answersList[existingAnswerIndex];
                                if (existingAnswer.polygonAnnotation != null) {
                                  polygonAnnotationManager?.delete(
                                      existingAnswer.polygonAnnotation!);
                                }
                              }

                              // final user = FirebaseAuth.instance.currentUser;
                              // bool isOnline = await _checkOfflineStatus();

                              // if (isOnline) {
                              //   saveBuildingAnswers(
                              //     layerId: _selectedLayer?["id"],
                              //     buildingId: buildingId,
                              //     buildingAnswers: answers.map<int, String>(
                              //         (key, value) => MapEntry(
                              //             int.parse(key), value.toString())),
                              //     color: selectedCircleColor,
                              //     coordinates: positionCoordinates
                              //         .expand((list) => list)
                              //         .toList()
                              //         .map((position) => [
                              //               position.lng.toDouble(),
                              //               position.lat.toDouble()
                              //             ])
                              //         .toList(),
                              //     userId: user?.uid,
                              //     projectId: projectData?.projectId,
                              //   );

                              //   final url = getBuildingAnswerBaseUrl(
                              //       _selectedLayer?["id"], user?.uid);
                              //   final response = await http.get(url);
                              //   final data = jsonDecode(response.body);
                              //   final List<Map<String, dynamic>>
                              //       buildingAnswer =
                              //       List<Map<String, dynamic>>.from(data);

                              //   final hiveService = HiveService();

                              //   print(buildingAnswer.length);
                              //   hiveService.saveBuildingAnswers(
                              //       _selectedLayer?["id"],
                              //       user?.uid,
                              //       buildingAnswer);

                              // }

                              polygonAnnotationManager
                                  ?.create(PolygonAnnotationOptions(
                                geometry:
                                    Polygon(coordinates: positionCoordinates),
                                fillColor:
                                    fillColor ?? 0xFFFFFFFF, 
                              ))
                                  .then((polygonAnnotation) async {
                                final answer = Answer(
                                    id: existingAnswer.id,
                                    layerId: _selectedLayer?["id"],
                                    buildingId: buildingId,
                                    answers: answers.map<int, String>(
                                        (key, value) => MapEntry(
                                            int.parse(key), value.toString())),
                                    color: selectedCircleColor,
                                    coordinates: positionCoordinates
                                        .expand((list) => list)
                                        .toList(),
                                    polygonAnnotation: polygonAnnotation,
                                    lastModified: DateTime.now()
                                        .toUtc()
                                        .toIso8601String());

                                if (existingAnswerIndex != -1) {
                                
                                  answersList[existingAnswerIndex] = answer;
                                } else {
                               
                                  answersList.add(answer);
                                }
                                final user = FirebaseAuth.instance.currentUser;
                                bool isOnline = await _checkOfflineStatus();

                                if (isOnline) {
                                  saveBuildingAnswers(
                                    layerId: _selectedLayer?["id"],
                                    buildingId: answer.buildingId,
                                    buildingAnswers: answer.answers,
                                    color: answer.color,
                                    coordinates: answer.coordinates
                                        .map((position) => [
                                              position.lng.toDouble(),
                                              position.lat.toDouble()
                                            ])
                                        .toList(),
                                    userId: user?.uid,
                                    projectId: projectData?.projectId,
                                  );

                                  final url = getBuildingAnswerBaseUrl(
                                      _selectedLayer?["id"], user?.uid);
                                  final response = await http.get(url);
                                  final data = jsonDecode(response.body);
                                  final List<Map<String, dynamic>>
                                      buildingAnswer =
                                      List<Map<String, dynamic>>.from(data);

                                  final hiveService = HiveService();

                                  print(buildingAnswer.length);
                                  hiveService.saveBuildingAnswers(
                                      _selectedLayer?["id"],
                                      user?.uid,
                                      buildingAnswer);
                                } else {
                                  final hiveService = HiveService();

                                  final List<Map<String, dynamic>>
                                      selectedAnswers =
                                      answersList.map((answer) {
                                    print(answer.answers);
                                    print(answer.layerId);
                                    print(
                                      form["id"].toString(),
                                    );
                                    print(answer.color);
                                    print(answer.lastModified);
                                    print(answer.coordinates);
                                    return {
                                      '_id': answer.id,
                                      'layerId': answer.layerId,
                                      'buildingId': form["id"].toString(),
                                      'answers': answer.answers,
                                      'color': answer.color,
                                      'lastModified': DateTime.now()
                                          .toUtc()
                                          .toIso8601String(),
                                      'coordinates': [
                                        answer.coordinates
                                            .map((position) => [
                                                  position.lng.toDouble(),
                                                  position.lat.toDouble()
                                                ])
                                            .toList()
                                      ],
                                      'isDelete': false,
                                      'projectId': projectData?.projectId,
                                      'userId': user?.uid,
                                    };
                                  }).toList();

                                  print(_selectedLayer?["id"]);
                                  print(selectedAnswers.length);
                                  print(selectedAnswers);

                                  hiveService.saveBuildingAnswers(
                                      answer.layerId,
                                      user?.uid,
                                      selectedAnswers);
                                }

                                print("answersList");
                                print(answersList);
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF699BF7), 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'บันทึก',
                              style: GoogleFonts.sarabun(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showRelationshipPopup(Ralationship relationship) {
    final TextEditingController descriptionController =
        TextEditingController(text: relationship.description);
    String selectedLinePattern = relationship.type;
    final user = FirebaseAuth.instance.currentUser;

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
              return FractionallySizedBox(
                  heightFactor: 0.6,
                  widthFactor: 1.0, 
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F4), 
                      borderRadius: BorderRadius.circular(8.0), 
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, 
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "เพิ่มสัญลักษณ์",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "รูปแบบ",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(
                                        12.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                selectedLinePattern =
                                                    'solid'; 
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: selectedLinePattern ==
                                                        'solid'
                                                    ? Colors.white
                                                    : Colors
                                                        .transparent,
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                boxShadow: selectedLinePattern ==
                                                        'solid'
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.3),
                                                          blurRadius: 4.0,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 6.0),
                                              child: const Center(
                                                child: Text(
                                                  'เส้นทึบ',
                                                  style:
                                                      TextStyle(fontSize: 14.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2.0),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                selectedLinePattern =
                                                    'dashed';
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: selectedLinePattern ==
                                                        'dashed'
                                                    ? Colors.white
                                                    : Colors
                                                        .transparent,
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                boxShadow: selectedLinePattern ==
                                                        'dashed'
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.3),
                                                          blurRadius: 4.0,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ]
                                                    : [], 
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 6.0),
                                              child: const Center(
                                                child: Text(
                                                  'เส้นประ',
                                                  style:
                                                      TextStyle(fontSize: 14.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2.0),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                selectedLinePattern =
                                                    'double';
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: selectedLinePattern ==
                                                        'double'
                                                    ? Colors.white
                                                    : Colors
                                                        .transparent, 
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                boxShadow: selectedLinePattern ==
                                                        'double'
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.3),
                                                          blurRadius: 4.0,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ]
                                                    : [], 
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 6.0),
                                              child: const Center(
                                                child: Text(
                                                  'เส้นขนาน',
                                                  style:
                                                      TextStyle(fontSize: 14.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2.0),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                selectedLinePattern =
                                                    'zigzag';
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: selectedLinePattern ==
                                                        'zigzag'
                                                    ? Colors.white
                                                    : Colors
                                                        .transparent, 
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                boxShadow: selectedLinePattern ==
                                                        'zigzag'
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.3),
                                                          blurRadius: 4.0,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ]
                                                    : [], 
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 6.0),
                                              child: const Center(
                                                child: Text(
                                                  'เส้นซิกแซก',
                                                  style:
                                                      TextStyle(fontSize: 14.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("คำอธิบาย"),
                        TextField(
                          controller: descriptionController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[300],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                            hintText: 'คำอธิบาย...',
                            hintStyle: GoogleFonts.sarabun(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          style: GoogleFonts.sarabun(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Spacer(),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.start, 
                          children: [
                            Expanded(
                              flex:
                                  9, 
                              child: ElevatedButton(
                                onPressed: () {
                                 
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          'ยืนยันการลบ',
                                          style: GoogleFonts.sarabun(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        content: Text(
                                          'คุณต้องการลบข้อมูลนี้หรือไม่?',
                                          style: GoogleFonts.sarabun(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); 
                                            },
                                            child: const Text('ยกเลิก'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              bool isOnline =
                                                  await _checkOfflineStatus();
                                              print('Is online: $isOnline');
                                              if (isOnline) {
                                                await deleteRelationship(
                                                  relationshipId:
                                                      relationship.id,
                                                  userId: user?.uid,
                                                );
                                                final hiveService =
                                                    HiveService();
                                                await hiveService
                                                    .removeRelationship(
                                                        relationship.id);
                                              } else {
                                                final toHive = {
                                                  'id': relationship.id,
                                                  'layerId':
                                                      _selectedLayer?['id'],
                                                  'points': relationship.points
                                                      .map((position) => [
                                                            position.lng
                                                                .toDouble(),
                                                            position.lat
                                                                .toDouble()
                                                          ])
                                                      .toList()
                                                      .map((point) => point
                                                          .map((e) =>
                                                              e.toDouble())
                                                          .toList())
                                                      .toList(),
                                                  'userId': user?.uid,
                                                  'type': relationship.type,
                                                  'projectId':
                                                      projectData?.projectId,
                                                  'description':
                                                      relationship.description,
                                                  'updatedAt': DateTime.now()
                                                      .toUtc()
                                                      .toIso8601String(),
                                                  'isDelete': true,
                                                };

                                                uploadtoHive(relationship.id, {
                                                  'id': relationship.id,
                                                  'layerId':
                                                      _selectedLayer?['id'],
                                                  'points': relationship.points
                                                      .map((position) => [
                                                            position.lng
                                                                .toDouble(),
                                                            position.lat
                                                                .toDouble()
                                                          ])
                                                      .toList()
                                                      .map((point) => point
                                                          .map((e) =>
                                                              e.toDouble())
                                                          .toList())
                                                      .toList(),
                                                  'userId': user?.uid,
                                                  'type': relationship.type,
                                                  'projectId':
                                                      projectData?.projectId,
                                                  'description':
                                                      relationship.description,
                                                  'updatedAt': DateTime.now()
                                                      .toUtc()
                                                      .toIso8601String(),
                                                  'isDelete': true,
                                                });
                                              }

                                              setState(() {
                                                relationships.removeWhere((r) =>
                                                    r.id == relationship.id);
                                              });

                                              if (relationship.type ==
                                                      'solid' ||
                                                  relationship.type ==
                                                      'double') {
                                                if (relationship
                                                        .polylineAnnotation !=
                                                    null) {
                                                  polylineAnnotationManager
                                                      ?.delete(relationship
                                                          .polylineAnnotation!);
                                                }
                                              } else if (relationship.type ==
                                                  'dashed') {
                                                if (relationship
                                                        .polylineAnnotation !=
                                                    null) {
                                                  polylinedashAnnotationManager
                                                      ?.delete(relationship
                                                          .polylineAnnotation!);
                                                }
                                              }

                                              _selectedLayer?["paths"] =
                                                  existingPaths;

                                              updateSelectedLayer();
                                              // Logic สำหรับการลบ
                                              Navigator.of(context)
                                                  .pop(); // ปิด Dialog
                                              Navigator.of(context)
                                                  .pop(); // ปิด Modal Bottom Sheet
                                            },
                                            child: const Text(
                                              'ลบ',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE57373),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  'ลบ',
                                  style: GoogleFonts.sarabun(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16), 
                            Expanded(
                              flex:
                                  9, 
                              child: ElevatedButton(
                                onPressed: () async {
                                  bool isOnline = await _checkOfflineStatus();
                                  print('Is online: $isOnline');
                                  final newDescription =
                                      descriptionController.text.trim();
                                  
                                  setState(() {
                                    relationship.description = newDescription;

                                    if (relationship.type == 'solid' ||
                                        relationship.type == 'double') {
                                      if (relationship.polylineAnnotation !=
                                          null) {
                                        polylineAnnotationManager?.delete(
                                            relationship.polylineAnnotation!);
                                      }
                                    } else if (relationship.type == 'dashed') {
                                      if (relationship.polylineAnnotation !=
                                          null) {
                                        polylinedashAnnotationManager?.delete(
                                            relationship.polylineAnnotation!);
                                      }
                                    }

                                    if (selectedLinePattern == 'double') {
                                      polylineAnnotationManager
                                          ?.create(PolylineAnnotationOptions(
                                              geometry: LineString(
                                                  coordinates:
                                                      relationship.points),
                                              lineColor:
                                                  int.parse("0xFF60a5fa"),
                                              lineWidth: 4,
                                              lineGapWidth: 1
                                             
                                              ))
                                          .then((polylineAnnotation) {
                                        setState(() {
                                          // relationship.type = selectedLinePattern;
                                          // relationship.description = descriptionController.text;
                                          relationship.polylineAnnotation =
                                              polylineAnnotation;
                                        });
                                      }).catchError((error) {
                                        print(
                                            "Failed to create polyline: $error");
                                      });
                                    } else if (selectedLinePattern == 'solid') {
                                      polylineAnnotationManager
                                          ?.create(PolylineAnnotationOptions(
                                        geometry: LineString(
                                            coordinates: relationship.points),
                                        lineColor: int.parse("0xFF60a5fa"),
                                        lineWidth: 4,
                                      ))
                                          .then((polylineAnnotation) {
                                        relationship.polylineAnnotation =
                                            polylineAnnotation;
                                      }).catchError((error) {
                                        print(
                                            "Failed to create polyline: $error");
                                      });
                                    } else if (selectedLinePattern ==
                                        'dashed') {
                                      polylinedashAnnotationManager
                                          ?.create(PolylineAnnotationOptions(
                                        geometry: LineString(
                                            coordinates: relationship.points),
                                        lineColor: int.parse("0xFF60a5fa"),
                                        lineWidth: 4,
                                      ))
                                          .then((polylineAnnotation) {
                                        polylinedashAnnotationManager
                                            ?.setLineDasharray([3.0, 1.0]);
                                        relationship.polylineAnnotation =
                                            polylineAnnotation;
                                      }).catchError((error) {
                                        print(
                                            "Failed to create polyline: $error");
                                      });
                                    } else if (selectedLinePattern ==
                                        'zigzag') {
                                      polylinedashAnnotationManager
                                          ?.create(PolylineAnnotationOptions(
                                        geometry: LineString(
                                            coordinates: relationship.points),
                                        lineColor: int.parse("0xFF60a5fa"),
                                        lineWidth: 4,
                                      ))
                                          .then((polylineAnnotation) {
                                        polylinedashAnnotationManager
                                            ?.setLineDasharray([3.0, 1.0]);
                                        relationship.polylineAnnotation =
                                            polylineAnnotation;
                                      }).catchError((error) {
                                        print(
                                            "Failed to create polyline: $error");
                                      });
                                    }
                                  });

                                  setState(() {
                                    relationship.type = selectedLinePattern;
                                    relationship.description =
                                        descriptionController.text;
                                  });

                                  print(relationship.id);
                                  if (isOnline) {
                                    updateRelationship(
                                      id: relationship.id,
                                      userId: user?.uid,
                                      type: selectedLinePattern,
                                      description: relationship.description,
                                    );
                                  }
                                  final toHive = {
                                    'id': relationship.id,
                                    'layerId': _selectedLayer?['id'],
                                    'points': relationship.points
                                        .map((position) => [
                                              position.lng.toDouble(),
                                              position.lat.toDouble()
                                            ])
                                        .toList()
                                        .map((point) => point
                                            .map((e) => e.toDouble())
                                            .toList())
                                        .toList(),
                                    'userId': user?.uid,
                                    'type': relationship.type,
                                    'projectId': projectData?.projectId,
                                    'description': relationship.description,
                                    'updatedAt': DateTime.now()
                                        .toUtc()
                                        .toIso8601String(),
                                    'isDelete': false,
                                  };

                                  uploadtoHive(relationship.id, {
                                    'id': relationship.id,
                                    'layerId': _selectedLayer?['id'],
                                    'points': relationship.points
                                        .map((position) => [
                                              position.lng.toDouble(),
                                              position.lat.toDouble()
                                            ])
                                        .toList()
                                        .map((point) => point
                                            .map((e) => e.toDouble())
                                            .toList())
                                        .toList(),
                                    'userId': user?.uid,
                                    'type': relationship.type,
                                    'projectId': projectData?.projectId,
                                    'description': relationship.description,
                                    'updatedAt': DateTime.now()
                                        .toUtc()
                                        .toIso8601String(),
                                    'isDelete': false,
                                  });
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF699BF7), // สีปุ่มบันทึก
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  'บันทึก',
                                  style: GoogleFonts.sarabun(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ));
            },
          );
        });
  }

  void _showPathPopup(Path path) {
    print('Popup for path: $path');
    final TextEditingController nameController =
        TextEditingController(text: path.name);
    final TextEditingController descriptionController =
        TextEditingController(text: path.description);
    double lineWidth = path.thickness;

    Color selectedColor =
        path.color ?? Colors.transparent; 

    final List<String> colors = [
      "#60a5fa", // สีฟ้า
      "#34d399", // สีเขียว
      "#facc15", // สีเหลือง
      "#f87171", // สีแดง
      "#c084fc", // สีม่วง
      "#818cf8", // สีน้ำเงิน
      "#f8fafc", // สีเทา
    ];

    showModalBottomSheet(
        context: context,
        isScrollControlled: true, 
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.0),
          ),
        ),
        builder: (BuildContext context) {
          final screenHeight = MediaQuery.of(context).size.height;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return FractionallySizedBox(
                  widthFactor: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    height: screenHeight * 0.8, 
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F4), 
                      borderRadius: BorderRadius.circular(8.0), 
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "เพิ่มสัญลักษณ์",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "รูปแบบ",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "ความหนาเส้น",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    "ค่าความหนา: ${lineWidth.toStringAsFixed(1)}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: lineWidth,
                                min: 1.0,
                                max: 10.0,
                                divisions: 9, 
                                label: lineWidth.toStringAsFixed(1),
                                activeColor: Colors.blue.shade500,
                                onChanged: (newValue) {
                                  setModalState(() {
                                    lineWidth = newValue; 
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 70,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: GridView.builder(
                                    shrinkWrap:
                                        true, 
                                    itemCount: colors
                                        .length, 
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                      Color color = Color(int.parse(
                                          colors[index]
                                              .replaceFirst('#', '0xFF')));
                                      bool isSelected = color ==
                                          selectedColor; 

                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            selectedColor =
                                                color; 
                                            debugPrint(
                                                'Selected Color: $selectedColor');
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape
                                                .circle, 
                                            border: selectedColor == color
                                                ? Border.all(
                                                    color: Colors.black,
                                                    width: 2)
                                                : null, 
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text("ชื่อเส้นทาง"),
                        TextField(
                          controller: nameController,
                          maxLines: 1,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[300],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                            hintText: 'ชื่อเส้นทาง...',
                            hintStyle: GoogleFonts.sarabun(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          style: GoogleFonts.sarabun(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("คำอธิบาย"),
                        TextField(
                          controller: descriptionController,
                          maxLines: 9,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[300],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                            hintText: 'คำอธิบาย...',
                            hintStyle: GoogleFonts.sarabun(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          style: GoogleFonts.sarabun(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Spacer(),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.start, // จัดตำแหน่งให้ซ้าย
                          children: [
                            Expanded(
                              flex:
                                  9, // กำหนดให้ปุ่มแรกมีความกว้าง 45% ของทั้งหมด
                              child: ElevatedButton(
                                onPressed: () {
                                  // Logic สำหรับลบ
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          'ยืนยันการลบ',
                                          style: GoogleFonts.sarabun(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        content: Text(
                                          'คุณต้องการลบข้อมูลนี้หรือไม่?',
                                          style: GoogleFonts.sarabun(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // ปิด Dialog
                                            },
                                            child: const Text('ยกเลิก'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                existingPaths.removeWhere(
                                                    (p) => p.id == path.id);
                                                if (path.polylineAnnotation !=
                                                    null) {
                                                  polylineAnnotationManager
                                                      ?.delete(path
                                                          .polylineAnnotation!);
                                                }

                                                _selectedLayer?["paths"] =
                                                    existingPaths;
                                              });

                                              updateSelectedLayer();
                                              final user = FirebaseAuth
                                                  .instance.currentUser;
                                              handleUpdateLayer(
                                                  _selectedLayer?['id'],
                                                  userId,
                                                  _selectedLayer!);

                                            
                                              Navigator.of(context)
                                                  .pop(); 
                                              Navigator.of(context)
                                                  .pop(); 
                                            },
                                            child: const Text(
                                              'ลบ',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE57373), 
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  'ลบ',
                                  style: GoogleFonts.sarabun(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16), 
                            Expanded(
                              flex:
                                  9, 
                              child: ElevatedButton(
                                onPressed: () async {
                                  final newName = nameController.text.trim();
                                  final newDescription =
                                      descriptionController.text.trim();
                               
                                  setState(() {
                                    path.name = newName;
                                    path.description = newDescription;
                                    path.thickness = lineWidth;
                                    path.color = selectedColor;

                                    path.polylineAnnotation?.lineWidth =
                                        lineWidth;
                                    path.polylineAnnotation?.lineColor =
                                        selectedColor.value;
                                    if (path.polylineAnnotation != null) {
                                      polylineAnnotationManager
                                          ?.update(path.polylineAnnotation!);
                                    }
                                  });

                                  final layerId = _selectedLayer?['id'];
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (layerId != null) {
                                    await sendUpdatedLayer(
                                        layerId, userId, _selectedLayer!);
                                  }

                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF699BF7), 
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  'บันทึก',
                                  style: GoogleFonts.sarabun(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ));
            },
          );
        });
  }

  void createPolylineFromCoordinates(List<Position> coordinates) async {
    try {
      final polylineAnnotation = await polylineAnnotationManager?.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: coordinates),
          lineColor: int.parse("0xFF60a5fa"),
          lineWidth: 4,
        ),
      );

      if (polylineAnnotation != null) {
        final newPath = Path(
          id: polylineAnnotation.id, 
          name: "เส้นทางใหม่",
          description: "คำอธิบายเส้นทาง",
          points: List.from(coordinates),
          thickness: 4,
          color: const Color(0xFF60a5fa),
          polylineAnnotation: polylineAnnotation,
        );

      
        setState(() {
          existingPaths.add(newPath);
          _selectedLayer?["paths"] =
              existingPaths; 
        });

        final layerId = _selectedLayer?['id'];
        final user = FirebaseAuth.instance.currentUser;
        if (layerId != null) {
          await sendUpdatedLayer(layerId, userId, _selectedLayer!);
          print("Updated layer with new path sent to backend.");
        }

        print("New polyline added: $newPath");
      }
    } catch (error) {
      print("Failed to create polyline: $error");
    } finally {
      polylineCoordinates.clear(); 
    }
  }

  void createNewPointAnnotation(Position position) async {
    try {
  
      final ByteData bytes = await rootBundle
          .load('assets/symbols/LocationOnIcon/LocationOnIcon-#60a5fa.PNG');
      final dynamic imageData = bytes.buffer.asUint8List();

      final pointAnnotation = await pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(position.lng, position.lat)),
          iconSize: 0.2,
          textColor: Colors.red.value,
          image: imageData,
        ),
      );

      if (pointAnnotation != null) {
        
        setState(() {
          markers.add({
            'id': pointAnnotation.id ?? '', 
            'lat': position.lat,
            'lng': position.lng,
            'name': 'ไม่มีชื่อ',
            'description': '',
            'color': '#60a5fa',
            'iconName':
                'assets/symbols/LocationOnIcon/LocationOnIcon-#60a5fa.PNG',
            'imageUrls': [],
            'pointAnnotation': pointAnnotation,
          });

         
          if (_selectedLayer != null) {
            _selectedLayer!['markers'] = markers;
          }
        });

       
        final layerId = _selectedLayer?['id'];
        final user = FirebaseAuth.instance.currentUser;
        if (layerId != null && user != null) {
          await sendUpdatedLayer(layerId, user.uid, _selectedLayer!);
          print("Updated layer sent to backend successfully.");
        } else {
          print("Error: layerId or user is null.");
        }
      }

      print("New PointAnnotation created at: ${position.lng}, ${position.lat}");
    } catch (e) {
      print("Error creating PointAnnotation: $e");
    }
  }

  void _createNewMarker(Position position) {
    final index = _locations.length - 1;
    final circleOptions = CircleAnnotationOptions(
      geometry: Point(coordinates: Position(position.lng, position.lat)),
      circleColor: Colors.blue.value,
      circleRadius: 10.0,
      circleStrokeColor: Colors.white.value,
      circleStrokeWidth: 2.0,
    );
    circleAnnotationManager?.create(circleOptions).then((circle) async {
      circleAnnotationsMap[index] = circle;
      final id = generateNoteId();
      final newMarker = Location(
          id: id,
          type: 'position',
          lat: position.lat.toDouble(),
          lng: position.lng.toDouble(),
          note: "",
          images: [],
          circleAnnotation: circle);

      _showPopup(newMarker, position, circle);
    });
  }

  Map<String, dynamic>? _findNearestIcon(Position tapCoordinates) {
    num minDistance = double.infinity;
    Map<String, dynamic>? nearestLocation;

    for (final location in markers) {
      final position = Position(location['lng'], location['lat']);
      num distance = _calculateDistance(tapCoordinates, position);
      if (distance < minDistance) {
        minDistance = distance;
        nearestLocation = location;
      }
    }

    const double tapThreshold = 0.00000001;
    return (minDistance <= tapThreshold) ? nearestLocation : null;
  }

  Location? _findNearestPoint(Position tapCoordinates) {
    num minDistance = double.infinity;
    Location? nearestLocation;

    for (final location in _locations) {
      final position = Position(location.lng, location.lat);
      num distance = _calculateDistance(tapCoordinates, position);
      if (distance < minDistance) {
        minDistance = distance;
        nearestLocation = location;
      }
    }

    const double tapThreshold = 0.00000001; 
    return (minDistance <= tapThreshold) ? nearestLocation : null;
  }

  num _calculateDistance(Position p1, Position p2) {
    final num latDiff = p1.lat - p2.lat;
    final num lngDiff = p1.lng - p2.lng;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }

  void _deleteMarker(String id) {
    setState(() {
      markers.removeWhere((marker) => marker['id'] == id);
    });
  }

  Future<void> sendUpdatedLayer(String layerId, String? userId,
      Map<String, dynamic> selectedLayer) async {
    print("=============sendUpdatedLayer==============");
    print(selectedLayer);

    List<Map<String, dynamic>> filteredMarkers =
        selectedLayer["markers"].map<Map<String, dynamic>>((marker) {
      print(marker);
      String iconName = marker["iconName"];
      RegExp regExp = RegExp(r'\/([^\/]+)-');
      Match? match = regExp.firstMatch(iconName);
      String iconNameSubstring = match != null ? match.group(1) ?? '' : '';

      return {
        "lat": marker["lat"],
        "lng": marker["lng"],
        "name": marker["name"],
        "description": marker["description"],
        "color": marker["color"],
        "iconName": iconNameSubstring, 
        "imageUrls": marker["imageUrls"],
      };
    }).toList();

    print("===========filteredMarkers============");
    print(filteredMarkers);

    List<Map<String, dynamic>> filteredPaths =
        selectedLayer["paths"].map<Map<String, dynamic>>((path) {
     
      List<Map<String, double>> transformedPoints =
          (path.points as List<Position>).map((point) {
        return {
          'lat': point.lat.toDouble(),
          'lng': point.lng.toDouble(),
        };
      }).toList();

      return {
        "id": path.id,
        "points": transformedPoints, 
        "color": colorToHex(path.color),
        "thickness": path.thickness,
        "name": path.name,
        "description": path.description,
      };
    }).toList();

    print(filteredPaths);

    final user = FirebaseAuth.instance.currentUser;
    final Map<String, dynamic> layerData = {
      "id": selectedLayer['id'],
      "title": selectedLayer["title"],
      "description": selectedLayer["description"],
      "imageUrl": selectedLayer["imageUrl"],
      "visible": selectedLayer["visible"],
      "order": selectedLayer["order"],
      "paths": filteredPaths,
      "markers": filteredMarkers,
      "questions": selectedLayer["questions"],
      "userId": user?.uid,
      "sharedWith": selectedLayer["sharedWith"],
      "projectId": projectData?.projectId,
      "isDeleted": false,
      'lastUpdate': DateTime.now().toUtc().toIso8601String(),
    };

    print(userId);
    bool isOnline = await _checkOfflineStatus();

    print('Is online: $isOnline');

    if (isOnline) {
      await updateLayer(layerId, userId, {
        "id": selectedLayer['id'],
        "title": selectedLayer["title"],
        "description": selectedLayer["description"],
        "imageUrl": selectedLayer["imageUrl"],
        "visible": selectedLayer["visible"],
        "order": selectedLayer["order"],
        "paths": filteredPaths,
        "markers": filteredMarkers,
        "questions": selectedLayer["questions"],
        "userId": selectedLayer["userId"],
        "sharedWith": selectedLayer["sharedWith"],
        "projectId": projectData?.projectId,
        "isDeleted": false,
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
      });
      final hiveService = HiveService();

      hiveService.putLayer(selectedLayer["projectId"], selectedLayer["id"], {
        "id": selectedLayer['id'],
        "title": selectedLayer["title"],
        "description": selectedLayer["description"],
        "imageUrl": selectedLayer["imageUrl"],
        "visible": selectedLayer["visible"],
        "order": selectedLayer["order"],
        "paths": filteredPaths,
        "markers": filteredMarkers,
        "questions": selectedLayer["questions"],
        "userId": user?.uid,
        "sharedWith": selectedLayer["sharedWith"],
        "projectId": projectData?.projectId,
        "isDeleted": false,
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      final hiveService = HiveService();
      print("=============sendUpdatedLayer==============");
      print(selectedLayer);

      List<Map<String, dynamic>> filteredMarkers =
          selectedLayer["markers"].map<Map<String, dynamic>>((marker) {
        print(marker);
        String iconName = marker["iconName"];
        RegExp regExp = RegExp(r'\/([^\/]+)-');
        Match? match = regExp.firstMatch(iconName);
        String iconNameSubstring = match != null ? match.group(1) ?? '' : '';

        return {
          "lat": marker["lat"],
          "lng": marker["lng"],
          "name": marker["name"],
          "description": marker["description"],
          "color": marker["color"],
          "iconName": iconNameSubstring,
          "imageUrls": marker["imageUrls"],
        };
      }).toList();

      print("===========filteredMarkers============");
      print(filteredMarkers);

      List<Map<String, dynamic>> filteredPaths =
          selectedLayer["paths"].map<Map<String, dynamic>>((path) {
        
        List<Map<String, double>> transformedPoints =
            (path.points as List<Position>).map((point) {
          return {
            'lat': point.lat.toDouble(),
            'lng': point.lng.toDouble(),
          };
        }).toList();

        return {
          "id": path.id,
          "points": transformedPoints, 
          "color": colorToHex(path.color),
          "thickness": path.thickness,
          "name": path.name,
          "description": path.description,
        };
      }).toList();

      print(filteredPaths);

      final user = FirebaseAuth.instance.currentUser;
      final Map<String, dynamic> layerData = {
        "id": selectedLayer['id'],
        "title": selectedLayer["title"],
        "description": selectedLayer["description"],
        "imageUrl": selectedLayer["imageUrl"],
        "visible": selectedLayer["visible"],
        "order": selectedLayer["order"],
        "paths": filteredPaths,
        "markers": filteredMarkers,
        "questions": selectedLayer["questions"],
        "userId": user?.uid,
        "sharedWith": selectedLayer["sharedWith"],
        "projectId": projectData?.projectId,
        "isDeleted": false,
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
      };

      hiveService.putLayer(projectData?.projectId, layerId, {
        "id": selectedLayer['id'],
        "title": selectedLayer["title"],
        "description": selectedLayer["description"],
        "imageUrl": selectedLayer["imageUrl"],
        "visible": selectedLayer["visible"],
        "order": selectedLayer["order"],
        "paths": filteredPaths,
        "markers": filteredMarkers,
        "questions": selectedLayer["questions"],
        "userId": user?.uid,
        "sharedWith": selectedLayer["sharedWith"],
        "projectId": projectData?.projectId,
        "isDeleted": false,
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  void _showMarkerPopup(Map<String, dynamic> location) {
    final TextEditingController nameController =
        TextEditingController(text: location["name"]);
    final TextEditingController descriptionController =
        TextEditingController(text: location["description"]);

    Color selectedColor =
        Color(int.parse(location["color"].replaceFirst('#', '0xFF')));
    String colorHex =
        selectedColor.value.toRadixString(16).substring(2); 
    int? selectedIndex;
    String? selectedImagePath = location["iconName"];

    final List<String> colors = [
      "#60a5fa", // สีฟ้า
      "#34d399", // สีเขียว
      "#facc15", // สีเหลือง
      "#f87171", // สีแดง
      "#c084fc", // สีม่วง
      "#818cf8", // สีน้ำเงิน
      "#a8a29e", // สีเทา
    ];

    showModalBottomSheet(
        context: context,
        isScrollControlled: true, 
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.0),
          ),
        ),
        builder: (BuildContext context) {
          final screenHeight = MediaQuery.of(context).size.height;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return FractionallySizedBox(
                  widthFactor: 1.0, 
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    height: screenHeight * 0.8, 
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F4), 
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, 
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "เพิ่มสัญลักษณ์",
                            style: GoogleFonts.sarabun(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "รูปแบบ",
                                style: GoogleFonts.sarabun(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 170,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: GridView.builder(
                                    itemCount: 23,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                   
                                      String imagePath;
                                      switch (index) {
                                        case 0:
                                          imagePath =
                                              'assets/symbols/LocationOnIcon/LocationOnIcon-#$colorHex.PNG';
                                          break;
                                        case 1:
                                          imagePath =
                                              'assets/symbols/LocationCityIcon/LocationCityIcon-#$colorHex.PNG';
                                          break;
                                        case 2:
                                          imagePath =
                                              'assets/symbols/DirectionsCarFilledIcon/DirectionsCarFilledIcon-#$colorHex.PNG';
                                          break;
                                        case 3:
                                          imagePath =
                                              'assets/symbols/AccountBalanceIcon/AccountBalanceIcon-#$colorHex.PNG';
                                          break;
                                        case 4:
                                          imagePath =
                                              'assets/symbols/HomeRepairServiceIcon/HomeRepairServiceIcon-#$colorHex.PNG';
                                          break;
                                        case 5:
                                          imagePath =
                                              'assets/symbols/LocalConvenienceStoreIcon/LocalConvenienceStoreIcon-#$colorHex.PNG';
                                          break;
                                        case 6:
                                          imagePath =
                                              'assets/symbols/LocalHospitalIcon/LocalHospitalIcon-#$colorHex.PNG';
                                          break;
                                        case 7:
                                          imagePath =
                                              'assets/symbols/MedicalServicesIcon/MedicalServicesIcon-#$colorHex.PNG';
                                          break;

                                        case 8:
                                          imagePath =
                                              'assets/symbols/MovieCreationIcon/MovieCreationIcon-#$colorHex.PNG';
                                          break;
                                        case 9:
                                          imagePath =
                                              'assets/symbols/MosqueIcon/MosqueIcon-#$colorHex.PNG';
                                          break;
                                        case 10:
                                          imagePath =
                                              'assets/symbols/ChurchIcon/ChurchIcon-#$colorHex.PNG';
                                          break;
                                        case 11:
                                          imagePath =
                                              'assets/symbols/CoffeeIcon/CoffeeIcon-#$colorHex.PNG';
                                          break;
                                        case 12:
                                          imagePath =
                                              'assets/symbols/FastfoodIcon/FastfoodIcon-#$colorHex.PNG';
                                          break;
                                        case 13:
                                          imagePath =
                                              'assets/symbols/ForestIcon/ForestIcon-#$colorHex.PNG';
                                          break;
                                        case 14:
                                          imagePath =
                                              'assets/symbols/GrassIcon/GrassIcon-#$colorHex.PNG';
                                          break;
                                        case 15:
                                          imagePath =
                                              'assets/symbols/HotelIcon/HotelIcon-#$colorHex.PNG';
                                          break;
                                        case 16:
                                          imagePath =
                                              'assets/symbols/HouseboatIcon/HouseboatIcon-#$colorHex.PNG';
                                          break;
                                        case 17:
                                          imagePath =
                                              'assets/symbols/LandslideIcon/LandslideIcon-#$colorHex.PNG';
                                          break;
                                        case 18:
                                          imagePath =
                                              'assets/symbols/LocalFloristIcon/LocalFloristIcon-#$colorHex.PNG';
                                          break;
                                        case 19:
                                          imagePath =
                                              'assets/symbols/SailingIcon/SailingIcon-#$colorHex.PNG';
                                          break;
                                        case 20:
                                          imagePath =
                                              'assets/symbols/SmokeFreeIcon/SmokeFreeIcon-#$colorHex.PNG';
                                          break;
                                        case 21:
                                          imagePath =
                                              'assets/symbols/WarehouseIcon/WarehouseIcon-#$colorHex.PNG';
                                          break;
                                        case 22:
                                          imagePath =
                                              'assets/symbols/ShoppingBagIcon/ShoppingBagIcon-#$colorHex.PNG';
                                          break;

                                        case 23:
                                          imagePath =
                                              'assets/symbols/CircleIconIcon/CircleIconIcon-#$colorHex.PNG';
                                          break;
                                        default:
                                          imagePath =
                                              'assets/symbols/default/default-#$colorHex.PNG'; // รูปภาพ default
                                      }

                                      return GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              selectedIndex =
                                                  index; // อัปเดตตำแหน่งที่เลือก
                                              selectedImagePath =
                                                  imagePath; // เก็บ imagePath
                                              print(selectedImagePath);
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2F2F2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: selectedIndex == index
                                                    ? Colors
                                                        .blue 
                                                    : Colors
                                                        .transparent, 
                                                width: 2,
                                              ),
                                            
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                  8.0), 
                                              child: Image.asset(
                                                imagePath,
                                                fit: BoxFit
                                                    .contain, 
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(
                                                    Icons
                                                        .error,
                                                    color: Colors.red,
                                                  );
                                                },
                                              ),
                                            ),
                                          ));
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 70,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: GridView.builder(
                                    shrinkWrap:
                                        true, 
                                    itemCount: colors
                                        .length, 
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7, 
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                      Color color = Color(int.parse(
                                          colors[index]
                                              .replaceFirst('#', '0xFF')));
                                      bool isSelected = color ==
                                          selectedColor; 

                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            selectedColor =
                                                color; 
                                            colorHex = selectedColor.value
                                                .toRadixString(16)
                                                .substring(2);
                                            selectedImagePath =
                                                selectedImagePath!.replaceFirst(
                                                    RegExp(r'-.+\.PNG'),
                                                    '-#$colorHex.PNG');
                                            // selectedImagePath =  selectedImagePath.;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape
                                                .circle,
                                            border: isSelected
                                                ? Border.all(
                                                    color: Colors.black,
                                                    width: 2)
                                                : null, 
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text("ชื่อสถานที่"),
                        TextField(
                          controller: nameController,
                          maxLines: 1,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[300],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                            hintText: 'ชื่อสถานที่...',
                            hintStyle: GoogleFonts.sarabun(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          style: GoogleFonts.sarabun(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("คำอธิบาย"),
                        TextField(
                          controller: descriptionController,
                          maxLines: 1,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[300], 
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none, 
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                            hintText: 'คำอธิบาย...',
                            hintStyle: GoogleFonts.sarabun(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          style: GoogleFonts.sarabun(
                            fontSize: 16,
                            color: Colors.black, 
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Spacer(),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.start, 
                          children: [
                            Expanded(
                              flex: 9,
                              child: ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('ยืนยันการลบ'),
                                        content: const Text(
                                            'คุณต้องการลบข้อมูลนี้หรือไม่?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); 
                                            },
                                            child: const Text('ยกเลิก'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              setState(() {
                                                markers.removeWhere((m) =>
                                                    m["id"] == location["id"]);
                                                _selectedLayer?['markers'] =
                                                    markers;
                                                updateSelectedLayer();
                                                pointAnnotationManager?.delete(
                                                    location[
                                                        "pointAnnotation"]);
                                              });

                                              final user = FirebaseAuth
                                                  .instance.currentUser;
                                              handleUpdateLayer(
                                                  _selectedLayer?['id'],
                                                  userId,
                                                  _selectedLayer!);
                                              Navigator.of(context)
                                                  .pop(); 
                                              Navigator.of(context)
                                                  .pop();
                                            },
                                            child: const Text(
                                              'ลบ',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE57373), 
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  'ลบ',
                                  style: GoogleFonts.sarabun(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex:
                                  9, 
                              child: ElevatedButton(
                                onPressed: () async {
                                  final newName = nameController.text.trim();
                                  final newDescription =
                                      descriptionController.text.trim();

                               
                                  final locationIndex = markers.indexWhere(
                                      (marker) =>
                                          marker["id"] == location["id"]);

                                  if (locationIndex != -1) {
                                    try {
                                     
                                      final ByteData bytes = await rootBundle
                                          .load(selectedImagePath!);
                                      final dynamic imageData =
                                          bytes.buffer.asUint8List();

                                      setModalState(() {
                                     
                                        markers[locationIndex]["name"] =
                                            newName;
                                        markers[locationIndex]["description"] =
                                            newDescription;
                                        markers[locationIndex]["color"] =
                                            "#${selectedColor.value.toRadixString(16).substring(2)}";

                                        markers[locationIndex]["iconName"] =
                                            selectedImagePath;
                                        markers[locationIndex]
                                                ["pointAnnotation"]
                                            .image = imageData;

                                     
                                        location["name"] = newName;
                                        location["description"] =
                                            newDescription;
                                        location["color"] =
                                            "#${selectedColor.value.toRadixString(16).substring(2)}";

                                        location["iconName"] =
                                            selectedImagePath;
                                        location["pointAnnotation"].image =
                                            imageData;

                                        debugPrint(
                                            "Updated location: ${markers[locationIndex]}");
                                      });
                                      setState(() {
                                        final pointAnnotation =
                                            markers[locationIndex]
                                                ["pointAnnotation"];
                                        if (pointAnnotation != null) {
                                          pointAnnotationManager
                                              ?.delete(pointAnnotation);

                                          pointAnnotationManager
                                              ?.create(PointAnnotationOptions(
                                                geometry: Point(
                                                    coordinates: Position(
                                                        location["lng"],
                                                        location["lat"])),
                                                // iconImage: "airport-15", 
                                                iconSize: 0.2,
                                                textColor: Colors.red.value,
                                                // symbolSortKey: 10,
                                                image: imageData,
                                              ))
                                              .then((pointAnnotation) => {
                                                    markers[locationIndex][
                                                            'pointAnnotation'] =
                                                        pointAnnotation
                                                  });
                                        } else {
                                          print("nulllllll");
                                        }

                                        markers[locationIndex]["name"] =
                                            newName;
                                        markers[locationIndex]["description"] =
                                            newDescription;
                                        markers[locationIndex]["color"] =
                                            "#${selectedColor.value.toRadixString(16).substring(2)}";

                                        markers[locationIndex]["iconName"] =
                                            selectedImagePath;
                                        markers[locationIndex]
                                                ["pointAnnotation"]
                                            .image = imageData;

                                     
                                        location["name"] = newName;
                                        location["description"] =
                                            newDescription;
                                        location["color"] =
                                            "#${selectedColor.value.toRadixString(16).substring(2)}";

                                        location["iconName"] =
                                            selectedImagePath;

                                        _selectedLayer?['markers'] = markers;
                                        for (var layer in layers) {
                                          if (layer['id'] ==
                                              _selectedLayer?['id']) {
                                            layer['markers'] = markers;
                                          }
                                        }
                                      });

                                      _selectedLayer?['isDeleted'] = false;
                                      _selectedLayer?['lastUpdate'] =
                                          DateTime.now()
                                              .toUtc()
                                              .toIso8601String();

                                
                                      final layerId = _selectedLayer?['id'];
                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      if (layerId != null) {
                                        await sendUpdatedLayer(
                                            layerId, userId, _selectedLayer!);
                                      }

                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      debugPrint("Error updating location: $e");

                                 
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Error"),
                                          content: Text(
                                              "ไม่สามารถอัปเดตข้อมูลได้: $e"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text("OK"),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } else {
                                    debugPrint(
                                        "Location not found in _markers");

                                    
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Error"),
                                        content: const Text(
                                            "ไม่พบ location ที่ต้องการอัปเดต"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF699BF7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  'บันทึก',
                                  style: GoogleFonts.sarabun(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ));
            },
          );
        });
  }

  void updateSelectedLayer() {
    if (_selectedLayer != null && _selectedLayer?['id'] != null) {
      
      final index =
          layers.indexWhere((layer) => layer['id'] == _selectedLayer?['id']);

      if (index != -1) {
       
        layers[index] = {
          ...layers[index],
          ..._selectedLayer!, 
          'lastUpdate': DateTime.now().toUtc().toIso8601String(),
        };

       
        setState(() {
          layers = List.from(layers);
        });
        print('Layer updated successfully: ${layers[index]}');
      } else {
        print('Layer with id ${_selectedLayer?['id']} not found in layers.');
      }
    } else {
      print('Selected layer or id is null.');
    }
  }

  void handleUpdateLayer(String layerId, String? userId,
      Map<String, dynamic> selectedLayer) async {
    await sendUpdatedLayer(
      layerId,
      userId,
      selectedLayer,
    );
  }

  image_picker.XFile? pickedImage;

  void _showPopup(
      Location? location, Position? position, CircleAnnotation? circle) {
    final TextEditingController smallNote =
        TextEditingController(text: location?.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "เพิ่มบันทึก",
          style: GoogleFonts.sarabun(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            TextField(
              controller: smallNote,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0), 
                  borderSide: BorderSide.none, 
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0), 
                  borderSide: BorderSide.none, 
                ),
              ),
              style: GoogleFonts.sarabun(fontSize: 14),
            ),
            const SizedBox(height: 16.0),
           
            if (pickedImage != null)
              SizedBox(
                width: MediaQuery.of(context).size.width -
                    32.0, 
                child: Image.file(
                  File(pickedImage!.path),
                  height: 150.0, 
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16.0),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // IconButton(
                //   icon: Icon(
                //     Icons.attach_file,
                //     size: 25.0,
                //     color: Colors.blue,
                //   ),
                //   onPressed: () {
                //     // Handle image attachment if needed
                //   },
                // ),
                // SizedBox(width: 16),
                // IconButton(
                //   icon: Icon(
                //     Icons.camera_alt,
                //     size: 25.0,
                //     color: Colors.blue,
                //   ),
                //   onPressed: () async {
                //     // Open the camera and pick an image
                //     // _openCameraSub();

                //   },
                // ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (circleAnnotationsMap.isNotEmpty) {
                circleAnnotationsMap.remove(circleAnnotationsMap.keys.last);
              }
              if (circle != null) {
                circleAnnotationManager?.delete(circle);
              }
              Navigator.of(context).pop(); 
            },
            child: Text(
              "ยกเลิก",
              style: GoogleFonts.sarabun(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              bool isOnline = await _checkOfflineStatus();
              setState(() {
                _locations.add(Location(
                  id: location!.id,
                  lat: location.lat,
                  lng: location.lng,
                  type: "position",
                  note: smallNote.text,
                  images: location.images,
                  circleAnnotation: circle,
                ));

                final items = _locations.map((location) {
                  return {
                    "type": "position",
                    "id": location.id,
                    "latitude": location.lat,
                    "longitude": location.lng,
                    "note": location.note,
                    "attachments": location.images,
                  };
                }).toList();
                final user = FirebaseAuth.instance.currentUser;

                if (isOnline) {
                  saveLocationToDatabase(
                      items,
                      projectData?.projectId,
                      user?.uid,
                      smallNote.text,
                      _selectedImages.map((image) => image.toJson()).toList());
                }

                final itemHive = _locations.map((location) {
                  return {
                    "type": "position",
                    "id": location.id,
                    "latitude": location.lat,
                    "longitude": location.lng,
                    "note": location.note,
                    "attachments": location.images
                        ?.map((image) => image.toJson())
                        .toList(),
                  };
                }).toList();

                saveNoteData(
                    projectData?.projectId,
                    user?.uid,
                    itemHive,
                    smallNote.text,
                    _selectedImages.map((image) => image.toJson()).toList());
              });
              Navigator.of(context).pop(); 
            },
            child: Text(
              "บันทึก",
              style: GoogleFonts.sarabun(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _showPopup(
  //     Location? location, Position? position, CircleAnnotation? circle) {
  //   final TextEditingController smallNote =
  //       TextEditingController(text: location?.note ?? '');

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text("เพิ่มบันทึก"),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text("Latitude: ${location!.lat}"),
  //           Text("Longitude: ${location.lng}"),
  //           SizedBox(height: 8.0),
  //           Text("บันทึกข้อความ"),
  //           TextField(
  //             controller: smallNote,
  //             maxLines: null,
  //             decoration: InputDecoration(
  //               hintText: 'พิมพ์ข้อความ...',
  //               border: OutlineInputBorder(),
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             if (circleAnnotationsMap.isNotEmpty) {
  //               circleAnnotationsMap.remove(circleAnnotationsMap.keys.last);
  //             }
  //             if (circle != null) {
  //               circleAnnotationManager?.delete(circle);
  //             }

  //             Navigator.of(context).pop();
  //           },
  //           child: Text("ยกเลิก"),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             bool isOnline = await _checkOfflineStatus();
  //             setState(() {
  //               _locations.add(Location(
  //                 id: location.id,
  //                 lat: location.lat,
  //                 lng: location.lng,
  //                 type: "position",
  //                 note: smallNote.text,
  //                 images: location.images,
  //                 circleAnnotation: circle,
  //               ));

  //               final items = _locations.map((location) {
  //                 return {
  //                   "type": "position",
  //                   "id": location.id,
  //                   "latitude": location.lat,
  //                   "longitude": location.lng,
  //                   "note": location.note,
  //                   "attachments": location.images,
  //                 };
  //               }).toList();
  //               final user = FirebaseAuth.instance.currentUser;

  //               if (isOnline) {
  //                 saveLocationToDatabase(
  //                     items,
  //                     projectData?.projectId,
  //                     user?.uid,
  //                     smallNote.text,
  //                     _selectedImages.map((image) => image.toJson()).toList());
  //               }

  //               final itemHive = _locations.map((location) {
  //                 return {
  //                   "type": "position",
  //                   "id": location.id,
  //                   "latitude": location.lat,
  //                   "longitude": location.lng,
  //                   "note": location.note,
  //                   "attachments": location.images
  //                       ?.map((image) => image.toJson())
  //                       .toList(),
  //                 };
  //               }).toList();

  //               saveNoteData(
  //                   projectData?.projectId,
  //                   user?.uid,
  //                   itemHive,
  //                   smallNote.text,
  //                   _selectedImages.map((image) => image.toJson()).toList());
  //             });
  //             Navigator.of(context).pop(); // ปิด popup
  //           },
  //           child: Text("บันทึก"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _removeLocation(Map<String, double> location) {
    setState(() {
      _locations.remove(location);
    });
  }

  bool _showMarkers = true;

  final List<String> _listItems = [
    'เลเยอร์สัญลักษณ์',
    'เลเยอร์ความสัมพันธ์',
    'ข้อมูลส่วนบุคคลทั่วไป',
    'ข้อมูลสาธารณูปโภคและสิ่งอำนวยความสะดวก',
    'ปัญหาของชุมชน',
    'ความสามารถในการออมทรัพย์ของครัวเรือน',
    'ด้านการท่องเที่ยวของชุมชน',
    'ด้านสุขภาพ',
    'กำหนดเอง',
  ];

  final List<String> _specificItems = [
    'ข้อมูลส่วนบุคคลทั่วไป',
    'ข้อมูลสาธารณูปโภคและสิ่งอำนวยความสะดวก',
    'ปัญหาของชุมชน',
    'ความสามารถในการออมทรัพย์ของครัวเรือน',
    'ด้านการท่องเที่ยวของชุมชน',
    'ด้านสุขภาพ',
    'กำหนดเอง',
  ];

  final List<Map<String, String>> dataList = [
    {"value": "personal_info", "label": "ข้อมูลส่วนบุคคลทั่วไป"},
    {
      "value": "utilities_info",
      "label": "ข้อมูลสาธารณูปโภคและสิ่งอำนวยความสะดวก"
    },
    {"value": "community_issues", "label": "ปัญหาของชุมชน"},
    {
      "value": "financial_info",
      "label": "ความสามารถในการออมทรัพย์ของครัวเรือน"
    },
    {"value": "tourism", "label": "ด้านการท่องเที่ยวของชุมชน"},
    {"value": "health", "label": "ด้านสุขภาพ"},
    {"value": "custom", "label": "กำหนดเอง"},
  ];

  String? getValueFromLabel(String label) {
    final result = dataList.firstWhere(
      (item) => item['label'] == label,
      orElse: () => {}, 
    );
    return result.isNotEmpty ? result['value'] : null;
  }

 
  final Map<String, dynamic> formQuestions = {
    "personal_info": [
      {
        "id": "1",
        "label": "ผู้ให้ข้อมูล",
        "type": "text",
        'showOnMap': false,
      },
      {
        "id": "2",
        "label": "วัน/เดือน/ปีเกิด",
        "type": "text",
        'showOnMap': false,
      },
      {
        "id": "3",
        "label": "อายุ",
        "type": "number",
        'showOnMap': false,
      },
      {
        "id": "4",
        "label": "ศาสนา",
        "type": "multiple_choice",
        'showOnMap': false,
        "options": [
          {"label": "พุทธ", "value": "buddhism"},
          {"label": "คริสต์", "value": "christian"},
          {"label": "อิสลาม", "value": "islam"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "5",
        "label": "สถานภาพ",
        "type": "multiple_choice",
        'showOnMap': false,
        "options": [
          {"label": "โสด", "value": "single"},
          {"label": "สมรส", "value": "married"},
          {"label": "หย่าร้าง", "value": "divorced"},
          {"label": "หม้าย", "value": "widowed"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "6",
        "label": "โรคประจำตัว",
        "type": "text",
        'showOnMap': false,
      },
      {
        "id": "7",
        "label": "การเลือกรับบริการรักษาพยาบาล",
        "type": "multiple_choice",
        'showOnMap': false,
        "options": [
          {
            "label": "โรงพยาบาลส่งเสริมสุขภาพตำบล/อนามัย",
            "value": "health_promotion_hospital"
          },
          {
            "label": "โรงพยาบาลประจำอำเภอ/จังหวัด",
            "value": "district_provincial_hospital"
          },
          {"label": "ซื้อยากินเอง", "value": "self_medication"},
          {"label": "คลินิกเอกชน", "value": "private_clinic"},
          {"label": "โรงพยาบาลเอกชน", "value": "private_hospital"},
          {"label": "สถานพยาบาลอื่น ๆ", "value": "other_healthcare"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "8",
        "label": "สิทธิด้านการรักษาพยาบาล",
        "type": "multiple_choice",
        'showOnMap': false,
        "options": [
          {
            "label": "สิทธิหลักประกันสุขภาพ/สิทธิ 30 บาท/สิทธิบัตรทอง",
            "value": "universal_healthcare"
          },
          {"label": "สิทธิประกันสังคม", "value": "social_security"},
          {
            "label": "สิทธิเบิกจ่ายตรงข้าราชการ",
            "value": "government_reimbursement"
          },
        ],
        "showMapToggle": true,
      },
      {
        "id": "9",
        "label": "ระดับการศึกษา",
        "type": "multiple_choice",
        'showOnMap': false,
        "options": [
          {"label": "ต่ำกว่าประถมศึกษา", "value": "below_primary"},
          {"label": "ประถมศึกษา", "value": "primary"},
          {"label": "มัธยมศึกษาตอนต้น", "value": "lower_secondary"},
          {
            "label": "มัธยมศึกษาตอนปลาย/ปวช.",
            "value": "upper_secondary_or_vocational"
          },
          {"label": "ปวส.หรือเทียบเท่า", "value": "vocational_certificate"},
          {"label": "ปริญญาตรี", "value": "bachelors"},
          {"label": "สูงกว่าปริญญาตรี", "value": "postgraduate"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "10",
        "label": "อาชีพ",
        "type": "multiple_choice",
        'showOnMap': false,
        "options": [
          {"label": "ทำไร่/ทำนา/ทำสวน", "value": "farmer"},
          {"label": "รับราชการ", "value": "government_employee"},
          {"label": "เจ้าหน้าที่ของรัฐ", "value": "state_officer"},
          {"label": "พนักงานบริษัท/ลูกจ้างเอกชน", "value": "private_employee"},
          {"label": "รับจ้างทั่วไป", "value": "freelancer"},
          {"label": "ค้าขาย", "value": "merchant"},
          {"label": "กำลังศึกษา", "value": "student"},
          {"label": "เด็กอยู่ในความปกครอง", "value": "under_guardianship"},
          {"label": "อื่น ๆ ระบุ", "value": "other"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "11",
        "label": "รายได้ครัวเรือนต่อปี",
        "type": "multiple_choice",
        'showOnMap': false,
        "options": [
          {"label": "พอใช้จ่ายในครัวเรือน", "value": "sufficient"},
          {"label": "เหลือเก็บ", "value": "surplus"},
          {"label": "เป็นหนี้", "value": "debt"},
        ],
        "showMapToggle": true,
      },
    ],
    "community_issues": [
      {
        "id": "1",
        "label": "ปัญหาของชุมชน ทั้งปัจจุบันและคาดการณ์อนาคต",
        "type": "checkbox",
        'showOnMap': false,
        "options": [
          {"label": "โครงสร้างพื้นฐานสาธารณูปโภค", "value": "infrastructure"},
          {"label": "อาชีพ รายได้", "value": "income_jobs"},
          {
            "label": "ทรัพยากรธรรมชาติ ดิน นา ป่า",
            "value": "natural_resources"
          },
          {"label": "สิ่งแวดล้อม มลพิษ", "value": "environment_pollution"},
          {"label": "ยาเสพติด", "value": "drugs"},
          {"label": "ภัยพิบัติ", "value": "disasters"},
          {"label": "ศิลปะ วัฒนธรรม ประเพณี", "value": "culture_traditions"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "2",
        'showOnMap': false,
        "label":
            "ความต้องการต่อชุมชนในอนาคต ครอบครัวของท่านอยากให้ชุมชน/หมู่บ้านที่อาศัยอยู่เป็นอย่างไรในอนาคต",
        "type": "text",
      },
    ],
    "utilities_info": [
      {
        "id": "1",
        "label": "ไฟฟ้า",
        "type": "multiple_choice",
        "options": [
          {"label": "มี", "value": "has_electricity"},
          {"label": "ไม่มี", "value": "no_electricity"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "2",
        "label": "น้ำสะอาดดื่มทั้งปี",
        "type": "multiple_choice",
        "options": [
          {"label": "มี", "value": "has_clean_drinking_water"},
          {"label": "ไม่มี", "value": "no_clean_drinking_water"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "3",
        "label": "ครัวเรือนน้ำใช้พอเพียงทั้งปี",
        "type": "multiple_choice",
        "options": [
          {"label": "มี", "value": "has_sufficient_water"},
          {"label": "ไม่มี", "value": "no_sufficient_water"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "4",
        "label": "แหล่งน้ำดื่มในครัวเรือน",
        "type": "multiple_choice",
        "options": [
          {"label": "น้ำประปาหมู่บ้าน", "value": "village_water_supply"},
          {"label": "น้ำฝน", "value": "rain_water"},
          {"label": "น้ำบ่อตื้น", "value": "shallow_well"},
          {"label": "น้ำบาดาล", "value": "groundwater"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "5",
        "label": "น้ำที่เอามาดื่มผ่านการทำความสะอาดหรือไม่",
        "type": "multiple_choice",
        "options": [
          {"label": "ผ่านการทำความสะอาด", "value": "cleaned"},
          {"label": "ไม่ผ่านการทำความสะอาด", "value": "not_cleaned"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "6",
        "label": "วิธีการทำความสะอาดน้ำดื่ม",
        "type": "multiple_choice",
        "options": [
          {"label": "ต้ม", "value": "boil"},
          {"label": "กรอง", "value": "filter"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "7",
        "label": "แหล่งน้ำใช้ในครัวเรือน",
        "type": "multiple_choice",
        "options": [
          {"label": "น้ำประปาหมู่บ้าน", "value": "village_water_supply"},
          {"label": "น้ำฝน", "value": "rain_water"},
          {"label": "น้ำบ่อตื้น", "value": "shallow_well"},
          {"label": "น้ำบาดาล", "value": "groundwater"},
          {"label": "น้ำสระ บึง หนอง", "value": "lake_pond"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "8",
        "label": "น้ำที่เอามาใช้ผ่านการทำความสะอาดหรือไม่",
        "type": "multiple_choice",
        "options": [
          {"label": "ผ่านการทำความสะอาด", "value": "cleaned"},
          {"label": "ไม่ผ่านการทำความสะอาด", "value": "not_cleaned"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "9",
        "label": "วิธีการทำความสะอาดน้ำใช้",
        "type": "multiple_choice",
        "options": [
          {"label": "เติมคลอรีน", "value": "chlorine"},
          {"label": "แกว่งสารส้ม", "value": "alum"},
          {"label": "กรอง", "value": "filter"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "10",
        "label": "โทรศัพท์บ้าน/โทรศัพท์เคลื่อนที่",
        "type": "multiple_choice",
        "options": [
          {"label": "มี", "value": "has_phone"},
          {"label": "ไม่มี", "value": "no_phone"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "11",
        "label": "ในครัวเรือนมียานพาหนะที่ใช้ในการเดินทางหรือไม่",
        "type": "multiple_choice",
        "options": [
          {"label": "มี", "value": "has_vehicle"},
          {"label": "ไม่มี", "value": "no_vehicle"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "12",
        "label": "ประเภทยานพาหนะ",
        "type": "checkbox",
        "options": [
          {"label": "รถยนต์(กระบะ/เก๋ง)", "value": "car"},
          {"label": "รถทางการเกษตร เช่น รถไถ", "value": "agricultural_vehicle"},
          {"label": "รถจักรยานยนต์", "value": "motorcycle"},
          {"label": "รถจักรยาน", "value": "bicycle"},
          {"label": "อื่น ๆ", "value": "other_vehicle"},
        ],
      },
      {
        "id": "13",
        "label": "การสวมหมวกกันน็อก/รัดเข็มขัดนิรภัย",
        "type": "multiple_choice",
        "options": [
          {"label": "ไม่เคยใช้เลย", "value": "never"},
          {"label": "ใช้บางครั้ง", "value": "sometimes"},
          {"label": "ใช้ทุกครั้ง", "value": "always"},
        ],
        "showMapToggle": true,
      },
    ],
    "financial_info": [
      {
        "id": "1",
        "label": "ความสามารถในการออมทรัพย์ของครัวเรือน",
        "type": "number",
      },
      {
        "id": "2",
        "label": "จำนวนหนี้สินนอกระบบ (ที่อยู่อาศัย)",
        "type": "number",
      },
      {
        "id": "3",
        "label": "จำนวนหนี้สินนอกระบบ (อาชีพ)",
        "type": "number",
      },
      {
        "id": "4",
        "label": "จำนวนหนี้สินนอกระบบ (อื่น ๆ)",
        "type": "number",
      },
      {
        "id": "5",
        "label": "จำนวนหนี้สินในระบบ (ที่อยู่อาศัย)",
        "type": "number",
      },
      {
        "id": "6",
        "label": "จำนวนหนี้สินในระบบ (อาชีพ)",
        "type": "number",
      },
      {
        "id": "7",
        "label": "จำนวนหนี้สินในระบบ (อื่น ๆ)",
        "type": "number",
      },
    ],
    "tourism": [
      {"id": "1", "label": "ชื่อแหล่งท่องเที่ยว", "type": "text"},
      {"id": "2", "label": "ที่ตั้ง", "type": "text"},
      {"id": "3", "label": "พิกัด GPS", "type": "text"},
      {"id": "4", "label": "ความเป็นมาของแหล่งท่องเที่ยว", "type": "text"},
      {"id": "5", "label": "จุดเด่นของแหล่งท่องเที่ยว", "type": "text"},
      {
        "id": "6",
        "label": "รูปแบบและการท่องเที่ยว",
        "type": "multiple_choice",
        "options": [
          {
            "label": "รูปแบบการท่องเที่ยวในแหล่งธรรมชาติ",
            "value": "nature_tourism"
          },
          {
            "label": "รูปแบบการท่องเที่ยวในแหล่งวัฒนธรรม",
            "value": "cultural_tourism"
          },
          {
            "label": "รูปแบบการท่องเที่ยวเชิงสิ่งก่อสร้าง",
            "value": "construction_tourism"
          },
          {"label": "รูปแบบการท่องเที่ยวอื่น ๆ", "value": "other_tourism"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "7",
        "label": "ความพร้อมในการให้บริการ",
        "type": "multiple_choice",
        "options": [
          {
            "label": "ระดับ 3 มีความพร้อมด้านสาธารณูปโภคครบถ้วน",
            "value": "level_3"
          },
          {
            "label": "ระดับ 2 มีความพร้อมด้านสาธารณูปโภคปานกลาง",
            "value": "level_2"
          },
          {
            "label": "ระดับ 1 มีความพร้อมด้านสาธารณูปโภคน้อย",
            "value": "level_1"
          },
        ],
        "showMapToggle": true,
      },
      {
        "id": "8",
        "label": "สิ่งอำนวยความสะดวก",
        "type": "checkbox",
        "options": [
          {"label": "ห้องน้ำ", "value": "restroom"},
          {"label": "ไฟส่องสว่าง", "value": "lighting"},
          {"label": "สัญญาณอินเตอร์เน็ต", "value": "internet_signal"},
          {"label": "ถนน", "value": "road"},
          {"label": "ป้ายบอกทาง", "value": "direction_sign"},
          {"label": "มัคคุเทศก์", "value": "guide"},
          {"label": "ที่พัก", "value": "accommodation"},
          {"label": "ร้านอาหาร", "value": "restaurant"},
          {"label": "ของที่ระลึก", "value": "souvenirs"},
          {"label": "กฎระเบียบ", "value": "regulations"},
        ],
        "showMapToggle": true,
      },
      {"id": "9", "label": "ต้องการเพิ่มเติม (ระบุ)", "type": "text"},
    ],
    "health": [
      {
        "id": "1",
        "label": "โรคประจำตัว",
        "type": "multiple_choice",
        "options": [
          {"label": "เบาหวาน", "value": "diabetes"},
          {"label": "ความดันโลหิตสูง", "value": "hypertension"},
          {"label": "โรคหัวใจ", "value": "heart_disease"},
          {"label": "โรคปอด", "value": "lung_disease"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "2",
        "label": "ในครัวเรือนมีการรับประทานอาหารแบบสุก ๆ ดิบ ๆ หรือไม่",
        "type": "multiple_choice",
        "options": [
          {"label": "รับประทาน", "value": "eat_raw_cooked"},
          {"label": "ไม่รับประทาน", "value": "no_raw_cooked"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "3",
        "label": "ในครัวเรือนมีการบริโภคผงชูรส",
        "type": "multiple_choice",
        "options": [
          {"label": "รับประทาน", "value": "eat_msg"},
          {"label": "ไม่รับประทาน", "value": "no_msg"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "4",
        "label": "สมาชิกในครัวเรือนมีคนดื่มสุรา/เบียร์",
        "type": "multiple_choice",
        "options": [
          {"label": "ดื่ม", "value": "drinks_alcohol"},
          {"label": "ไม่ดื่ม", "value": "no_alcohol"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "5",
        "label": "สมาชิกในครัวเรือนมีคนสูบบุหรี่/ยาเส้น",
        "type": "multiple_choice",
        "options": [
          {"label": "สูบ", "value": "smokes_tobacco"},
          {"label": "ไม่สูบ", "value": "no_tobacco"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "6",
        "label": "สมาชิกในครัวเรือนมีการใช้ยาเสพติดหรือไม่",
        "type": "multiple_choice",
        "options": [
          {"label": "มี", "value": "uses_drugs"},
          {"label": "ไม่มี", "value": "no_drugs"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "7",
        "label": "สมาชิกในครัวเรือนมีการตรวจสุขภาพประจำปีหรือไม่",
        "type": "multiple_choice",
        "options": [
          {"label": "มี", "value": "annual_health_check"},
          {"label": "ไม่มี", "value": "no_health_check"},
        ],
        "showMapToggle": true,
      },
      {
        "id": "8",
        "label": "สมาชิกในครัวเรือนมีการออกกำลังกายเป็นประจำหรือไม่",
        "type": "multiple_choice",
        "options": [
          {"label": "ออกเป็นประจำ", "value": "exercises_regularly"},
          {"label": "ไม่ออกเป็นประจำ", "value": "no_regular_exercise"},
        ],
        "showMapToggle": true,
      },
    ],
    "custom": [
      {
        "id": "1",
        "label": "กำหนดเอง",
        "type": "text",
        'showOnMap': false,
      },
    ],
  };

  // ตัวแปรเก็บฟอร์มคำถามที่เลือก
  List<Map<String, dynamic>>? selectedForm;

  bool _showClipRRect = true; // ควบคุมการแสดง ClipRRect

  void _onItemSelected(String? item) {
    setState(() {
      if (item != null) {
        selectedForm = formQuestions[getValueFromLabel(item)];
        // หากเลือกไอเท็มที่อยู่ใน _specificItems ให้ล้าง ClipRRect
        if (_specificItems.contains(item)) {
          _showClipRRect = false;
        } else {
          _showClipRRect = true;
        }
      } else {
        // Handle resetting logic when item is null
        selectedForm = null;
        _showClipRRect = true;
      }
    });
  }

  late List<Map<String, dynamic>> layers = [];

  bool _isModalOpen = false;
  final bool _isStatisticModalOpen = false;
  bool _isLayerModalOpen = false;
  bool _isSymbolLayerModalOpen = false; // ตัวแปรสำหรับควบคุมสถานะการเปิด modal
  bool _isFormLayerModalOpen = false; // ตัวแปรสำหรับควบคุมสถานะการเปิด modal
  bool _isRelationshipLayerModalOpen = false;
  bool _isNavigateLayerModalOpen = false;
  List<Map<String, dynamic>> updatedQuestions = [];
  Map<String, dynamic>? _selectedLayer; // เก็บข้อมูลของ layer ที่เลือก
  String selectedMode = 'เพิ่มเส้นทาง';
  List<Position> polylineCoordinates = [];
  List<Position> relationshipCoordinates = [];
  List<Path> existingPaths = [];
  List<Ralationship> relationships = [];
  List<Answer> answersList = [];
  bool isSelected = false;
  String? selectedLinePattern;
  final TextEditingController layerNameController = TextEditingController();

  void _addAllMarkers() {
    if (circleAnnotationManager != null && _locations.isNotEmpty) {
      for (var location in _locations) {
       
        circleAnnotationManager
            ?.create(CircleAnnotationOptions(
              geometry:
                  Point(coordinates: Position(location.lng, location.lat)),
              circleColor: Colors.blue.value,
              circleRadius: 10.0,
              circleStrokeColor: Colors.white.value,
              circleStrokeWidth: 2.0,
            ))
            .then((value) => {
                  setState(() {
                    location.circleAnnotation = value;
                  })
                });
      }
    }
  }

  void _removeAllMarkers() {
    if (circleAnnotationManager != null) {
      circleAnnotationManager?.deleteAll();
    }
  }

  String generateSymbolLayerId() {
    const prefix = "layer-symbol-";
    final random = Random();
    final uuid =
        List.generate(8, (index) => random.nextInt(16).toRadixString(16))
            .join();

    return '$prefix$uuid';
  }

  String generateNoteId() {
    const prefix = "position-";
    final random = Random();
    final uuid =
        List.generate(8, (index) => random.nextInt(16).toRadixString(16))
            .join();

    return '$prefix$uuid';
  }

  String generateFromLayerId() {
    const prefix = "layer-form-";
    final random = Random();
    final uuid =
        List.generate(8, (index) => random.nextInt(16).toRadixString(16))
            .join();

    return '$prefix$uuid';
  }

  String generateRelationshipLayerId() {
    const prefix = "layer-relationship-";
    final random = Random();
    final uuid =
        List.generate(8, (index) => random.nextInt(16).toRadixString(16))
            .join();
    return '$prefix$uuid';
  }

  String generateBuildingLayerId() {
 
    final random = Random();

   
    final numericId = List.generate(
            8,
            (index) =>
                random.nextInt(10).toString())
        .join();

    return numericId;
  }

  Future<void> _updateMarkersVisibility(
      Map<String, dynamic> layer, bool visible) async {
    for (var marker in layer['markers']) {
      if (!visible) {
       
        pointAnnotationManager?.delete(marker['pointAnnotation']);
      } else {
        final pointAnnotation = marker["pointAnnotation"];
        if (pointAnnotation != null) {
        
          final ByteData bytes = await rootBundle.load(marker['iconName']);
          final dynamic imageData = bytes.buffer.asUint8List();

       
          pointAnnotationManager
              ?.create(PointAnnotationOptions(
            geometry:
                Point(coordinates: Position(marker["lng"], marker["lat"])),
            iconSize: 0.2,
            textColor: Colors.red.value,
            image: imageData,
          ))
              .then((newPointAnnotation) {
            marker['pointAnnotation'] = newPointAnnotation;
          });
        }
      }
    }
  }

  Future<void> _updateFormVisibility(
      Map<String, dynamic> layer, bool visible) async {
    print("------_updateFormVisibility--------");
    print(layer);
    print(answersList);
    print(answersList.length);
 
    for (var item in answersList) {
      print(item.answers);
      print(item.buildingId);
      print(item.color);
      print(item.coordinates);
      print(item.layerId);
      print(item.lastModified);
      print(item.polygonAnnotation);
    
      if (item.layerId == layer['id']) {
        if (!visible) {
        
          if (item.polygonAnnotation != null) {
            polygonAnnotationManager?.delete(item.polygonAnnotation!);
            setState(() {
              item.polygonAnnotation = null;
            });
          }
        } else {
          String? hexColor = item.color; 
          hexColor = hexColor?.replaceFirst('#', ''); 
          int fillColor = int.parse('FF$hexColor',
              radix: 16); 
          if (item.polygonAnnotation != null) {
            polygonAnnotationManager?.delete(item.polygonAnnotation!);
          }

         
          polygonAnnotationManager
              ?.create(PolygonAnnotationOptions(
            geometry: Polygon(coordinates: [item.coordinates]),
            fillColor: item.color != null
                ? fillColor | 0xFF000000
                : Colors.white.value, 
          ))
              .then((newPolygonAnnotation) {
         
            item.polygonAnnotation = newPolygonAnnotation;
            setState(() {
              item.polygonAnnotation = newPolygonAnnotation;
            });
          });
        }
      }
    }
  }


  Future<void> _updatePathsVisibility(
      Map<String, dynamic> layer, bool visible) async {
    for (var path in layer['paths']) {
      if (!visible) {
       
        polylineAnnotationManager?.delete(path.polylineAnnotation);
      } else {
        final polylineAnnotation = path.polylineAnnotation;
        if (polylineAnnotation != null) {
          try {
            polylineAnnotationManager
                ?.create(PolylineAnnotationOptions(
              geometry: LineString(coordinates: path.points),
              lineColor: path.color.value,
              lineWidth: path.thickness,
            ))
                .then((newPolylineAnnotation) {
           
              path.polylineAnnotation = newPolylineAnnotation;
            });
          } catch (e) {
            print('Error processing path coordinates: $e');
          }
        }
      }
    }
  }

  Future<void> _updateRelationshipVisibility(
      Map<String, dynamic> layer, bool visible) async {
    final relationship = relationships
        .where((relationship) => relationship.layerId == layer['id'])
        .toList();
    for (var relationship in relationship) {
      if (!visible) {
        if (relationship.type == 'solid' || relationship.type == 'double') {
          if (relationship.polylineAnnotation != null) {
            polylineAnnotationManager?.delete(relationship.polylineAnnotation!);
          }
        } else if (relationship.type == 'dashed') {
          if (relationship.polylineAnnotation != null) {
            polylinedashAnnotationManager
                ?.delete(relationship.polylineAnnotation!);
          }
        }
      } else {
        final polylineAnnotation = relationship.polylineAnnotation;

        if (relationship.type == 'solid') {
          try {
            polylineAnnotationManager
                ?.create(PolylineAnnotationOptions(
              geometry: LineString(coordinates: relationship.points),
              lineColor: int.parse("0xFF60a5fa"),
              lineWidth: 4,
            ))
                .then((newPolylineAnnotation) {
            
              relationship.polylineAnnotation = newPolylineAnnotation;
            });
          } catch (e) {
            print('Error processing path coordinates: $e');
          }
        } else if (relationship.type == 'double') {
          try {
            polylineAnnotationManager
                ?.create(PolylineAnnotationOptions(
                    geometry: LineString(coordinates: relationship.points),
                    lineColor: int.parse("0xFF60a5fa"),
                    lineWidth: 4,
                    lineGapWidth: 1))
                .then((newPolylineAnnotation) {
            
              relationship.polylineAnnotation = newPolylineAnnotation;
            });
          } catch (e) {
            print('Error processing path coordinates: $e');
          }
        } else if (relationship.type == 'dashed') {
          try {
            polylinedashAnnotationManager
                ?.create(PolylineAnnotationOptions(
              geometry: LineString(coordinates: relationship.points),
              lineColor: int.parse("0xFF60a5fa"),
              lineWidth: 4,
            ))
                .then((newPolylineAnnotation) {
            
              relationship.polylineAnnotation = newPolylineAnnotation;
            });
          } catch (e) {
            print('Error processing path coordinates: $e');
          }
        }
      }
    }
  }

  IconData _getIconForRelationshipType(String? type) {
    switch (type) {
      case 'solid':
        return Icons.timeline; 
      case 'dashed':
        return Icons.timeline; 
      case 'double':
        return Icons.timeline; 
      case 'zigzag':
        return Icons.timeline; 
      default:
        return Icons.help_outline;
    }
  }

  void _onMapClick(MapContentGestureContext context) async {
    try {
      final screenCoordinate = ScreenCoordinate(
        x: context.touchPosition.x,
        y: context.touchPosition.y,
      );

      print("OnTap coordinate: {${context.point.coordinates.lng}, ${context.point.coordinates.lat}}" " point: {x: ${context.touchPosition.x}, y: ${context.touchPosition.y}}");

   
      final screenBox = ScreenBox(min: screenCoordinate, max: screenCoordinate);
      final renderedQueryGeometry = RenderedQueryGeometry(
        type: Type.SCREEN_BOX,
        value: jsonEncode(screenBox.encode()),
      );

      final features = await mapboxMap?.queryRenderedFeatures(
        renderedQueryGeometry,
        RenderedQueryOptions(
          layerIds: ['building'],
          filter: null, 
        ),
      );

      if (features != null) {
        print(features.first?.queriedFeature.feature);
        final featuresData = features.first?.queriedFeature.feature;
        final featuresDataMap = featuresData as Map<String?, Object?>;

        final geometry = featuresDataMap['geometry'] as Map<Object?, Object?>;
        final coordinates = geometry['coordinates'] as List<Object?>;

        final List<List<Position>> positionCoordinates =
            coordinates.map((coordinateList) {
          return (coordinateList as List<dynamic>).map((coordinate) {
            final longitude = coordinate[0] as double;
            final latitude = coordinate[1] as double;
            return Position(longitude, latitude);
          }).toList();
        }).toList();

        polygonAnnotationManager
            ?.create(PolygonAnnotationOptions(
                geometry: Polygon(coordinates: positionCoordinates),
                fillColor: Colors.red.value,
                fillOutlineColor: Colors.purple.value))
            .then((value) => {});
      }
    } catch (e) {
      debugPrint('Error selecting building: $e');
    }
  }

  final double _slideOffset = 0.0;
  void _deleteLayer(Map<String, dynamic> layer) async {
    final hiveService = HiveService();
    setState(() {
      layers.remove(layer); 
    });
    bool isOnline = await _checkOfflineStatus();
    if (isOnline) {
      print(layer['id']);
      await deleteLayer(layer['id']);
      print(layer['id']);
      await hiveService.deleteLayer(projectData?.projectId, layer['id']);
      print(layer['id']);
    } else {
      print("=============sendDeleteLayer==============");
      List<Map<String, dynamic>> filteredMarkers =
          layer["markers"].map<Map<String, dynamic>>((marker) {
        print(marker);
        String iconName = marker["iconName"];
        RegExp regExp = RegExp(r'\/([^\/]+)-');
        Match? match = regExp.firstMatch(iconName);
        String iconNameSubstring = match != null ? match.group(1) ?? '' : '';

        return {
          "lat": marker["lat"],
          "lng": marker["lng"],
          "name": marker["name"],
          "description": marker["description"],
          "color": marker["color"],
          "iconName": iconNameSubstring,
          "imageUrls": marker["imageUrls"],
        };
      }).toList();

      print("===========filteredMarkers============");
      print(filteredMarkers);

      List<Map<String, dynamic>> filteredPaths =
          layer["paths"].map<Map<String, dynamic>>((path) {
        List<Map<String, double>> transformedPoints =
            (path.points as List<Position>).map((point) {
          return {
            'lat': point.lat.toDouble(),
            'lng': point.lng.toDouble(),
          };
        }).toList();

        return {
          "id": path.id,
          "points": transformedPoints, 
          "color": colorToHex(path.color),
          "thickness": path.thickness,
          "name": path.name,
          "description": path.description,
        };
      }).toList();

      print(filteredPaths);

      final user = FirebaseAuth.instance.currentUser;
      final Map<String, dynamic> layerData = {
        "id": layer['id'],
        "title": layer["title"],
        "description": layer["description"],
        "imageUrl": layer["imageUrl"],
        "visible": layer["visible"],
        "order": layer["order"],
        "paths": filteredPaths,
        "markers": filteredMarkers,
        "questions": layer["questions"],
        "userId": user?.uid,
        "sharedWith": layer["sharedWith"],
        "projectId": projectData?.projectId,
        "isDeleted": false,
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
      };
      // final hiveService = HiveService();
      // print(selectedLayer);
      hiveService.putLayer(layer["projectId"], layer["id"], {
        "id": layer['id'],
        "title": layer["title"],
        "description": layer["description"],
        "imageUrl": layer["imageUrl"],
        "visible": layer["visible"],
        "order": layer["order"],
        "paths": filteredPaths,
        "markers": filteredMarkers,
        "questions": layer["questions"],
        "userId": user?.uid,
        "sharedWith": layer["sharedWith"],
        "projectId": projectData?.projectId,
        "isDeleted": true,
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
      });
      // await hiveService.deleteLayer(layer['id']);
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, Map<String, dynamic> layer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'ยืนยันการลบ',
            style: GoogleFonts.sarabun(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF699BF7),
            ),
          ),
          content: Text(
            'ต้องการลบเลเยอร์นี้หรือไม่',
            style: GoogleFonts.sarabun(
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.sarabun(
                  fontSize: 14,
               
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteLayer(layer);
                Navigator.of(context).pop(); 
              },
              child: Text(
                'ตกลง',
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  // color: Colors.green,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> createDeepCopy(Map<dynamic, dynamic> original) {
    return Map<String, dynamic>.fromEntries(
      original.entries.map((entry) {
        final key = entry.key as String;
        final value = entry.value;
        if (value is Map) {
          return MapEntry(key, createDeepCopy(value));
        } else if (value is List) {
          return MapEntry(
              key,
              value
                  .map((item) => item is Map
                      ? createDeepCopy(item)
                      : item)
                  .toList());
        } else {
          return MapEntry(key, value);
        }
      }),
    );
  }

  List<TextEditingController> questioncontrollers = [];
  TextEditingController topiccontrollers = TextEditingController();
  void _showEditLayer(BuildContext context, Map<String, dynamic> layer) {
    Map<String, dynamic> editedLayer = createDeepCopy(layer);

    topiccontrollers.text = layer['title'] ?? 'No Title Available';
    questioncontrollers = List.generate(
      editedLayer["questions"].length,
      (index) =>
          TextEditingController(text: editedLayer["questions"][index]["label"]),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        // Map<String, dynamic> editedLayer = createDeepCopy(layer);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.75,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F4),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: TextField(
                        controller: topiccontrollers,
                        onChanged: (value) {
                          setState(() {
                            editedLayer['title'] =
                                value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "แก้ไขชื่อเลเยอร์",
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                        ),
                        style: GoogleFonts.sarabun(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF699BF7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: SingleChildScrollView(
                        child: editedLayer["questions"] != null &&
                                editedLayer["questions"].isNotEmpty
                            ? Column(
                                children: [
                                  Column(
                                    children: editedLayer["questions"]
                                        .asMap()
                                        .entries
                                        .map<Widget>((entry) {
                                      int index = entry.key;
                                      var question = entry.value;

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 6.0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                           
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'คำถาม ${index + 1}',
                                                  style: GoogleFonts.sarabun(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (question['showOnMap'] ==
                                                    true)
                                                  Text(
                                                    '*แสดงบนแผนที่',
                                                    style: GoogleFonts.sarabun(
                                                      fontSize: 16,
                                                      fontStyle: FontStyle
                                                          .italic,
                                                      color: Colors
                                                          .blue, 
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8.0),
                                            TextField(
                                              controller:
                                                  questioncontrollers[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  question["label"] = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: "แก้ไขคำถาม",
                                                filled: true,
                                                fillColor:
                                                    const Color(0xFFF9F9F9),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: GoogleFonts.sarabun(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if (question['type'] == 'text' ||
                                                question['type'] == 'number')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: TextField(
                                                  enabled: false,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        question['type'] ==
                                                                'text'
                                                            ? "ตัวอย่างข้อความ"
                                                            : "ตัวอย่างตัวเลข",
                                                    filled: true,
                                                    fillColor:
                                                        const Color(0xFFF0F0F0),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      vertical: 12.0,
                                                      horizontal: 16.0,
                                                    ),
                                                  ),
                                                  style: GoogleFonts.sarabun(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            if (question['type'] ==
                                                    'checkbox' ||
                                                question['type'] ==
                                                    'multiple_choice')
                                              Column(
                                                children: List<Widget>.from(
                                                  question['options']
                                                      .asMap()
                                                      .entries
                                                      .map(
                                                    (entry) {
                                                      int index = entry.key;
                                                      var option = entry.value;

                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                top: 4.0),
                                                        child: Row(
                                                          children: [
                                                          
                                                            if (question[
                                                                    'type'] ==
                                                                'checkbox')
                                                              Container(
                                                                width:
                                                                    15.0, 
                                                                height:
                                                                    15.0, 
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .grey), 
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              2.0), 
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    option['label'] ??
                                                                        'No label', 
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center, 
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                ),
                                                              ),
                                                            const SizedBox(width: 8),

                                                           
                                                            if (question[
                                                                    'type'] ==
                                                                'multiple_choice')
                                                              Radio(
                                                                value: option[
                                                                    'value'],
                                                                groupValue:
                                                                    question[
                                                                        'selectedValue'],
                                                                onChanged:
                                                                    (value) {
                                                                  setModalState(
                                                                      () {
                                                                    question[
                                                                            'selectedValue'] =
                                                                        value;
                                                                  });
                                                                },
                                                              ),
                                                        
                                                            Expanded(
                                                              child: TextField(
                                                                controller:
                                                                    TextEditingController(
                                                                  text: option[
                                                                          'label'] ??
                                                                      '',
                                                                ),
                                                                onChanged:
                                                                    (value) {
                                                                  setModalState(
                                                                      () {
                                                                    option['label'] =
                                                                        value;
                                                                  });
                                                                },
                                                                style: GoogleFonts
                                                                    .sarabun(), 
                                                                decoration:
                                                                    InputDecoration(
                                                                  hintText:
                                                                      'แก้ไขตัวเลือก',
                                                                  border:
                                                                      OutlineInputBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                    borderSide:
                                                                        BorderSide
                                                                            .none,
                                                                  ),
                                                                  filled: true,
                                                                  fillColor: const Color(
                                                                      0xFFF9F9F9),
                                                                  contentPadding:
                                                                      const EdgeInsets
                                                                          .symmetric(
                                                                    vertical:
                                                                        10.0,
                                                                    horizontal:
                                                                        12.0,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (question[
                                                                    'showOnMap'] ==
                                                                true)
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .only(
                                                                        left:
                                                                            8.0),
                                                                child:
                                                                    Container(
                                                                  width: 24,
                                                                  height: 24,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: option['color'] !=
                                                                            null
                                                                        ? Color(int.parse(
                                                                            'FF' +
                                                                                option['color'].replaceAll('#',
                                                                                    ''),
                                                                            radix:
                                                                                16))
                                                                        : Colors
                                                                            .transparent,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: Colors
                                                                          .black,
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )..add(
                                                    Padding(
                                                      padding: const EdgeInsets.only(
                                                          top: 10.0),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFF699BF7),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        child: InkWell(
                                                          onTap: () {
                                                            setModalState(() {
                                                           
                                                              int optionCount =
                                                                  question[
                                                                          'options']
                                                                      .length;
                                                              String
                                                                  optionValue =
                                                                  'option_${optionCount + 1}'; 

                                                            
                                                              question[
                                                                      'options']
                                                                  .add({
                                                                'label': '',
                                                                'value':
                                                                    optionValue,
                                                              });
                                                            });
                                                          },
                                                          child: Padding(
                                                            padding: const EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        12.0,
                                                                    horizontal:
                                                                        20.0),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                const Icon(Icons.add,
                                                                    color: Colors
                                                                        .white),
                                                                const SizedBox(
                                                                    width: 8),
                                                                Text(
                                                                  'เพิ่มตัวเลือก',
                                                                  style: GoogleFonts
                                                                      .sarabun(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: index > 0
                                                          ? () {
                                                              setModalState(() {
                                                                var temp =
                                                                    editedLayer[
                                                                            "questions"]
                                                                        [index];
                                                                editedLayer["questions"]
                                                                        [
                                                                        index] =
                                                                    editedLayer[
                                                                            "questions"]
                                                                        [index -
                                                                            1];
                                                                editedLayer[
                                                                        "questions"]
                                                                    [index -
                                                                        1] = temp;
                                                              });
                                                            }
                                                          : null,
                                                      icon: Icon(
                                                          Icons
                                                              .arrow_drop_up_rounded,
                                                          color: index > 0
                                                              ? const Color(
                                                                  0xFF699BF7)
                                                              : Colors.grey),
                                                    ),
                                                    IconButton(
                                                      onPressed: index <
                                                              layer["questions"]
                                                                      .length -
                                                                  1
                                                          ? () {
                                                              setModalState(() {
                                                                var temp =
                                                                    editedLayer[
                                                                            "questions"]
                                                                        [index];
                                                                editedLayer["questions"]
                                                                        [
                                                                        index] =
                                                                    editedLayer[
                                                                            "questions"]
                                                                        [index +
                                                                            1];
                                                                editedLayer[
                                                                        "questions"]
                                                                    [index +
                                                                        1] = temp;
                                                              });
                                                            }
                                                          : null,
                                                      icon: Icon(
                                                          Icons
                                                              .arrow_drop_down_rounded,
                                                          color: index <
                                                                  editedLayer["questions"]
                                                                          .length -
                                                                      1
                                                              ? Colors.blue
                                                              : Colors.grey),
                                                    ),
                                                    if (question['showOnMap'] ==
                                                        false)
                                                      IconButton(
                                                        onPressed: () {
                                                          setModalState(() {
                                                            editedLayer[
                                                                    "questions"]
                                                                .removeAt(
                                                                    index);
                                                          });
                                                        },
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Color(
                                                              0xFF699BF7),
                                                        ),
                                                      )
                                                    else
                                                      IconButton(
                                                        onPressed: () {},
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(
                                    width: double
                                        .infinity, 
                                    child: ElevatedButton(
                                      onPressed: () => _addQuestionDialog(
                                          context, setModalState, editedLayer),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF699BF7),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      child: Text(
                                        'เพิ่มคำถาม',
                                        style: GoogleFonts.sarabun(
                                          textStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )
                            : Center(
                                child: Text(
                                  "ไม่มีคำถามในเลเยอร์นี้",
                                  style: GoogleFonts.sarabun(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'ยกเลิก',
                              style: GoogleFonts.sarabun(
                                textStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                layer.clear();
                                layer.addAll(editedLayer);
                              });

                              final layerId = editedLayer['id'];
                              final user = FirebaseAuth.instance.currentUser;
                              print(layerId);
                              print(editedLayer);
                              if (layerId != null) {
                                await sendUpdatedLayer(
                                    layerId, user?.uid, editedLayer);
                              }

                              Navigator.pop(context, layer);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF699BF7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'บันทึก',
                              style: GoogleFonts.sarabun(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _addQuestionDialog(BuildContext context, StateSetter setModalState,
      Map<String, dynamic> editedLayer) {
    String type = ''; 
    TextEditingController labelController =
        TextEditingController(); 

    if (editedLayer['questions'] == null) {
      editedLayer['questions'] = [];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เลือกประเภทคำถาม'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('ข้อความ'),
                value: 'text',
                groupValue: type,
                onChanged: (String? value) {
                  setModalState(() {
                    type = value!;
                  });
                  Navigator.of(context).pop(); 
                },
              ),
              RadioListTile<String>(
                title: const Text('ตัวเลข'),
                value: 'number',
                groupValue: type,
                onChanged: (String? value) {
                  setModalState(() {
                    type = value!;
                  });
                  Navigator.of(context).pop(); 
                },
              ),
              RadioListTile<String>(
                title: const Text('คำถามตัวเลือก'),
                value: 'multiple_choice',
                groupValue: type,
                onChanged: (String? value) {
                  setModalState(() {
                    type = value!;
                  });
                  Navigator.of(context).pop(); 
                },
              ),
              RadioListTile<String>(
                title: const Text('คำถามเลือกได้หลายคำตอบ'),
                value: 'checkbox',
                groupValue: type,
                onChanged: (String? value) {
                  setModalState(() {
                    type = value!;
                  });
                  Navigator.of(context).pop(); 
                },
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (type.isNotEmpty) {
     
        String id = (editedLayer['questions'].length + 1).toString();

        var newQuestion = <String, Object>{
          'id': id, 
          'label': labelController.text.isNotEmpty
              ? labelController.text
              : '', 
          'type': type, 
          'showOnMap': false, 
        };
        if (type == 'multiple_choice' || type == 'checkbox') {
          newQuestion['options'] = [];
        }

        editedLayer['questions'].add(newQuestion);

        questioncontrollers = List.generate(
          editedLayer["questions"].length,
          (index) => TextEditingController(
            text: editedLayer["questions"][index]["label"],
          ),
        );

        setModalState(() {
        });

        print(editedLayer['questions']);
      }
    });
  }

  void _showStatisticModal(BuildContext context) {
    String? selectedLayerTitle;
    String? selectedLayerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F4),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'สถิติ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF699BF7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เลือกเลเยอร์',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          layers.isNotEmpty
                              ? LayerDropdown(
                                  layers: layers, // ส่งรายการ layers
                                  onSelected: (String id, String title) {
                                    setState(() {
                                      selectedLayerId = id;
                                      selectedLayerTitle = title;
                                    });

                                    print(
                                        'Selected Layer: id = $id, title = $title');
                                  },
                                )
                              : const Center(
                                  child: Text('ไม่มีเลเยอร์ที่พร้อมใช้งาน'),
                                ),

                          if (selectedLayerId != null)
                            Expanded(
                              child:
                                  FutureBuilder<Map<String, Map<String, int>>>(
                                future: _getChartData(selectedLayerId!),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data!.isNotEmpty) {
                                    final questionEntries =
                                        snapshot.data!.entries.toList();
                                    return ListView.builder(
                                      itemCount: questionEntries.length,
                                      itemBuilder: (context, index) {
                                        final entry = questionEntries[index];
                                        final questionText = entry.key;
                                        final data = entry.value;

                                        if (data.isEmpty) {
                                          return const SizedBox
                                              .shrink();
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  blurRadius: 6.0,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'คำถาม: $questionText',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 20.0),
                                                Center(
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 32.0),
                                                    child: SizedBox(
                                                      width: double
                                                          .infinity,

                                                      child: CustomBarChart(
                                                          data: data),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    return const Center(
                                        child: Text('ไม่มีข้อมูลสำหรับแสดงผล'));
                                  }
                                },
                              ),
                            ),
                          if (selectedLayerId != null)
                            Expanded(
                              child: FutureBuilder<
                                  Map<String, Map<String, dynamic>>>(
                                future: _getStatisticData(
                                    selectedLayerId), 
                                builder: (context, snapshot) {
                                  var chartData = snapshot.data ?? {};

                              
                                  return ListView(
                                    children: chartData.entries.map((entry) {
                                      String questionText = entry.key;
                                      Map<String, dynamic> stats = entry.value;

                                      return Card(
                                        color: Colors.white,
                                        margin:
                                            const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                questionText,
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 8.0),
                                              Text("Mean: ${stats["mean"]}"),
                                              Text(
                                                  "Median: ${stats["median"]}"),
                                              Text(
                                                  "Standard Deviation: ${stats["stdDev"]}"),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),

                          // const SizedBox(height: 16.0),
                          // if (selectedLayerId != null)
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, Map<String, int>>> _getChartData(String? layerId) async {
    Map<String, Map<String, int>> chartData = {};

    try {
      if (layerId == null) {
        return chartData; 
      }

  
      var selectedLayer = layers.firstWhere(
        (layer) => layer['id'] == layerId,
        orElse: () => {},
      );

      if (selectedLayer.isEmpty) {
        return chartData;
      }

      List<Map<String, dynamic>> questions =
          (selectedLayer["questions"] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .cast<Map<String, dynamic>>()
              .toList();

   
      for (var question in questions) {
      
        if (question["type"] == "multiple_choice" ||
            question["type"] == "checkbox") {
          int questionId = int.tryParse(question["id"].toString()) ?? -1;
          String questionText = question["label"];

          chartData.putIfAbsent(questionText, () => {});
          for (var answer in answersList) {
            print(answer);
            if (answer.layerId == layerId) {
              dynamic answerValue = answer.answers[questionId];
              if (answerValue == "") {
                continue;
              }

              String optionLabel = "";
              try {
                optionLabel = question["options"].firstWhere((opt) =>
                    opt['value'] == answer.answers[questionId])['label'];
              } catch (e) {
                optionLabel =
                    "Unknown Option"; 
              }

           
              if (question["type"] == "multiple_choice") {
                chartData[questionText]![optionLabel] =
                    (chartData[questionText]![optionLabel] ?? 0) + 1;

                chartData[questionText]![question["options"].firstWhere((opt) =>
                    opt['value'] != answer.answers[questionId])['label']] = 0;
              } else if (question["type"] == "checkbox") {
                String label = answerValue == 1 ? "Checked" : "Unchecked";
                chartData[questionText]![label] =
                    (chartData[questionText]![label] ?? 0) + 1;
              }
            }
          }
        }
      }
    } catch (e) {
    
      print("Error occurred: $e");
    
      return chartData;
    }

  
    return chartData;
  }

  Future<Map<String, Map<String, dynamic>>> _getStatisticData(
      String? layerId) async {
    Map<String, Map<String, dynamic>> chartData = {};

    try {
      if (layerId == null) {
        return chartData; 
      }

      var selectedLayer = layers.firstWhere(
        (layer) => layer['id'] == layerId,
        orElse: () => {},
      );

      if (selectedLayer.isEmpty) {
        return chartData; 
      }

      List<Map<String, dynamic>> questions = selectedLayer["questions"] ?? [];
      if (questions.isEmpty) {
        return chartData;
      }

   
      for (var question in questions) {
    
        if (question["type"] == "number") {
        
          List<double> numbers = [];
          int questionId = int.tryParse(question["id"].toString()) ?? -1;
          String questionText = question["label"] ?? "Unknown Question";

      
          for (var answer in answersList) {
            if (answer.layerId == layerId) {
              dynamic answerValue = answer.answers[questionId];
              double? numericValue = double.tryParse(answerValue.toString());
              if (numericValue != null) {
                numbers.add(numericValue);
              } else {
              
                print("Invalid number: $answerValue");
              }
            }
          }

          if (numbers.isNotEmpty) {
          
            double mean = numbers.reduce((a, b) => a + b) / numbers.length;

       
            numbers.sort();
            double median = numbers.length % 2 == 0
                ? (numbers[numbers.length ~/ 2 - 1] +
                        numbers[numbers.length ~/ 2]) /
                    2
                : numbers[numbers.length ~/ 2].toDouble();

        
            double variance =
                numbers.map((e) => pow(e - mean, 2)).reduce((a, b) => a + b) /
                    numbers.length;
            double stdDev = sqrt(variance);

          
            chartData.putIfAbsent(questionText, () => {});
            chartData[questionText]!["mean"] = mean;
            chartData[questionText]!["median"] = median;
            chartData[questionText]!["stdDev"] = stdDev;
          }
        }
      }
    } catch (e) {
    
      print("Error occurred: $e");
    
      return chartData;
    }

    print(chartData);
 
    return chartData;
  }

  void _showHeatMapModal(BuildContext context) {
    String? selectedLayerTitle;
    String? selectedLayerId;

    
    final filteredLayers = layers.where((layer) {
      return layer['id'].startsWith('layer-form-');
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9, 

          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F4),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'แผนที่ความหนาแน่น',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF699BF7),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'เลือกเลเยอร์',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8.0),
                LayerDropdown(
                  layers: filteredLayers, 
                  onSelected: (String id, String title) {
                    selectedLayerId = id;
                    selectedLayerTitle = title;

                    print('Selected Layer: id = $id, title = $title');
                  },
                ),
                const SizedBox(height: 16.0),
                if (selectedLayerId != null) ...[
                  // Text(
                  //   'คุณเลือกเลเยอร์: $selectedLayerTitle',
                  //   style: TextStyle(
                  //     fontSize: 14.0,
                  //     color: Colors.black54,
                  //   ),
                  // ),
                ],
                const SizedBox(height: 16.0),
                if (selectedLayerId != null)
                  Expanded(
                    child: ListView.builder(
                      itemCount: layers.length,
                      itemBuilder: (context, index) {
                        final layer = layers.firstWhere(
                            (layer) => layer['id'] == selectedLayerId);
                        if (layer['questions'] == null) {
                          return const Center(
                              child: Text('ไม่มีข้อมูลคำถามในเลเยอร์นี้'));
                        }

                        List questions = layer['questions'];
                        List filteredQuestions = questions.where((q) {
                          return q['type'] == 'multiple_choice' ||
                              q['type'] == 'checkbox';
                        }).toList();

                        if (filteredQuestions.isEmpty) {
                          return const Center(
                              child: Text(
                                  'ไม่มีคำถามประเภท multiple_choice หรือ checkbox'));
                        }

                        return ListView.builder(
                          itemCount: filteredQuestions.length,
                          shrinkWrap:
                              true,
                          physics:
                              const NeverScrollableScrollPhysics(), 
                          itemBuilder: (context, questionIndex) {
                            final question = filteredQuestions[questionIndex];
                            final questionText =
                                question['label'] ?? 'ไม่มีข้อความคำถาม';
                            final options = question['options'] ?? [];

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white, 
                                  borderRadius:
                                      BorderRadius.circular(10.0), 
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3), 
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(
                                    12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'คำถาม: $questionText',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    if (options.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: List.generate(options.length,
                                            (optionIndex) {
                                          final option = options[optionIndex];
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value:
                                                      false, 
                                                  onChanged: (bool? value) {
                                                  
                                                  },
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'ตัวเลือก ${optionIndex + 1}: ${option['label']}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                  ],
                                ),
                              ),
                            );
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
  }

  void _showSelectMapModal(BuildContext context) {
    String? selectedLayerTitle;
    String? selectedLayerId;
    final filteredLayers = layers.where((layer) {
      return layer['id'].startsWith('layer-form-');
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5, 

          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F4),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'เลือกแผนที่',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF699BF7),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
             
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _styleUri = MapboxStyles.OUTDOORS;
                          mapboxMap?.style.setStyleURI(_styleUri);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              width: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.black,
                                image: const DecorationImage(
                                  image: AssetImage(
                                      'assets/images/map3.png'), 
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            const Text(
                              'Outdoors',
                              style: TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 16.0), 
                    GestureDetector(
                      onTap: () {
                        // print(_styleUri);
                        setState(() {
                          _styleUri = MapboxStyles.SATELLITE;
                          mapboxMap?.style.setStyleURI(_styleUri);
                        });
                        print(_styleUri);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              width: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.black,
                                image: const DecorationImage(
                                  image: AssetImage(
                                      'assets/images/map2.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            const Text(
                              'Satellite',
                              style: TextStyle(
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // void HeatMap() async {
  //   mapboxMap?.style.addSource(GeoJsonSource(
  //       id: "source",
  //       data:
  //           "https://www.mapbox.com/mapbox-gl-js/assets/earthquakes.geojson"));

  //   await mapboxMap?.style.addLayer(HeatmapLayer(
  //     id: 'layer',
  //     sourceId: 'source',
  //     // visibility: ,
  //     minZoom: 1.0,
  //     maxZoom: 20.0,
  //     slot: LayerSlot.BOTTOM,
  //     heatmapColor: Colors.red.value,
  //     heatmapIntensity: 1.0,
  //     heatmapOpacity: 1.0,
  //     heatmapRadius: 1.0,
  //     heatmapWeight: 1.0,
  //   ));
  //   var layer = await mapboxMap?.style.getLayer('layer') as HeatmapLayer;
  // }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  AnimationController? controller;
  Animation<double>? animation;
  Timer? timer;
  var trackLocation = true;
  var showAnnotations = false;
  void _addRouteLineLayerAndSource() async {
    await mapboxMap?.style.addLayer(LineLayer(
      id: 'layer',
      sourceId: 'source',
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
      lineBlur: 1.0,
      lineColor: Colors.deepOrangeAccent.value,
      lineDasharray: [1.0, 2.0],
      lineWidth: 5.0,
  
      lineGradientExpression: [
        "interpolate",
        ["linear"],
        ["line-progress"],
        0.0,
        ["rgb", 255, 0, 0],
        0.4,
        ["rgb", 0, 255, 0],
        1.0,
        ["rgb", 0, 0, 255]
      ],
    ));

    await mapboxMap?.style
        .addSource(GeoJsonSource(id: "source", lineMetrics: true));
  }

  refreshTrackLocation() async {
    timer?.cancel();
    if (trackLocation) {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        try {
          final position = await mapboxMap?.style.getPuckPosition();
          if (position != null) {
          
          }
        } catch (e) {
          print(e);
        }
      });
    }
  }

  String _styleUri = MapboxStyles.OUTDOORS;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MapWidget(
                  onMapCreated: _onMapCreated,
                  onTapListener: _onMapTapped,
                  styleUri: _styleUri,
                ),
                // Positioned(
                //   bottom: 10,
                //   right: 20,
                //   child: Container(
                //     width: 35,
                //     height: 35,
                //     decoration: BoxDecoration(
                //       // color: Color(0xFFF3F2F2),
                //       borderRadius: BorderRadius.circular(30),
                //     ),
                //     child: _getFeatureState(),
                //   ),
                // ),
                // Positioned(
                //   bottom: 140,
                //   right: 20,
                //   child: Container(
                //     width: 35,
                //     height: 35,
                //     decoration: BoxDecoration(
                //       // color: Color(0xFFF3F2F2),
                //       borderRadius: BorderRadius.circular(30),
                //     ),
                //     child: _setFeatureState(),
                //   ),
                // ),
                // Positioned(
                //   bottom: 60,
                //   right: 20,
                //   child: Container(
                //     width: 35,
                //     height: 35,
                //     decoration: BoxDecoration(
                //       // color: Color(0xFFF3F2F2),
                //       borderRadius: BorderRadius.circular(30),
                //     ),
                //     child: _queryRenderedFeatures(),
                //   ),
                // ),
                Positioned(
                  bottom: 40,
                  right: 10,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      // color: Color(0xFFF3F2F2),
                      borderRadius: BorderRadius.circular(30),
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
                  bottom: 90,
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
                Positioned(
                  top: 170,
                  right: 14,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2F2),
                
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: FloatingActionButton(
                      onPressed: () {
                        _showStatisticModal(context);
                      },
                      backgroundColor: const Color(0xFFF3F2F2),
                      elevation: 0,
                      highlightElevation: 0.0,
                      child: const Icon(
                        Icons.insert_chart_outlined_outlined,
                        color: Color(0xFF699BF7),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(
                      milliseconds: 50),
                  top: 50,
                  curve: Curves.easeInOut,
                  right: 10,
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      color: (const Color(0xFFF3F2F2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.map,
                            color: Color(0xFF699BF7),
                          ),
                          onPressed: () {
                            setState(() {
                              _isModalOpen = true; 
                            });
                          },
                        ),
                        Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                          indent: 3,
                          endIndent: 3,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.note_alt_rounded,
                            color: Color(0xFF699BF7),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled:
                                  true, 
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20.0),
                                ),
                              ),
                              builder: (BuildContext context) {
                                final screenHeight =
                                    MediaQuery.of(context).size.height;
                                return StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setModalState) {
                                    return FractionallySizedBox(
                                      widthFactor: 1.0, 
                                      child: Container(
                                        padding: const EdgeInsets.all(16.0),
                                        height: screenHeight *
                                            0.9,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              0xFFF5F5F4),
                                          borderRadius: BorderRadius.circular(
                                              8.0),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'บันทึก',
                                              style: TextStyle(
                                                fontSize: 20.0,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF699BF7),
                                              ),
                                            ),

                                            const SizedBox(height: 10.0),
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                children: [
                                                
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .all(
                                                        4.0), 
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                    width: double.infinity,
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextField(
                                                            controller:
                                                                _noteController,
                                                            maxLines: 4,
                                                            decoration:
                                                                const InputDecoration(
                                                              hintText:
                                                                  'พิมพ์ข้อความ...',
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          8.0),
                                                            ),
                                                            style: GoogleFonts
                                                                .sarabun(
                                                                    fontSize:
                                                                        16),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .end,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .camera_alt_rounded, 
                                                          color: Color(
                                                              0xFF699BF7), 
                                                        ),
                                                        onPressed: () async {
                                                          await _openCamera(
                                                              setModalState); 
                                                          setState(() {});
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.attach_file,
                                                          color: Color(
                                                              0xFF699BF7), 
                                                        ),
                                                        onPressed: () async {
                                                          await _pickImage(
                                                              setModalState); 
                                                          setState(() {});
                                                        },
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 8.0),
                                                  
                                                  if (_selectedImages
                                                      .isNotEmpty)
                                                    Expanded(
                                                      child: GridView.builder(
                                                        gridDelegate:
                                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount:
                                                              3,
                                                          crossAxisSpacing: 8.0,
                                                          mainAxisSpacing: 8.0,
                                                        ),
                                                        itemCount:
                                                            _selectedImages
                                                                .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final imageFile =
                                                              _selectedImages[
                                                                  index];
                                                          return Stack(
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return Dialog(
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12.0),
                                                                          child:
                                                                              Image.file(
                                                                            File(imageFile.offlineurl),
                                                                            fit:
                                                                                BoxFit.contain, 
                                                                            width:
                                                                                double.infinity,
                                                                            height:
                                                                                double.infinity,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12.0),
                                                                  child: Image
                                                                      .file(
                                                                    File(imageFile
                                                                        .offlineurl), 
                                                                    fit: BoxFit
                                                                        .cover, 
                                                                    width: double
                                                                        .infinity,
                                                                    height: double
                                                                        .infinity,
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                top: 4,
                                                                right: 4,
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      _selectedImages
                                                                          .removeAt(
                                                                              index);
                                                                    });
                                                                  },
                                                                  child:
                                                                      const CircleAvatar(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .grey,
                                                                    radius: 12,
                                                                    child: Icon(
                                                                      Icons
                                                                          .close,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 16,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 10.0),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .end,
                                              children: [
                                                const Text(
                                                  'แสดงบนแผนที่',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Color(
                                                        0xFF699BF7), 
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width:
                                                        8), 
                                                Switch(
                                                  value: _showMarkers,
                                                  activeColor: const Color(
                                                      0xFF699BF7), 
                                                  inactiveThumbColor: const Color(
                                                          0xFF699BF7)
                                                      .withOpacity(
                                                          0.5), 
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _showMarkers =
                                                          value; 
                                                    });
                                                    setModalState(() {
                                                      _showMarkers = value;
                                                    });
                                                    if (_showMarkers) {
                                                  
                                                      _addAllMarkers();
                                                    } else {
                                                  
                                                      _removeAllMarkers();
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),

                                         

                                            Expanded(
                                              flex:
                                                  2, 
                                              child: Container(
                                                padding: const EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: _locations
                                                        .asMap()
                                                        .entries
                                                        .map((entry) {
                                                      int index = entry.key;
                                                      Location location =
                                                          entry.value;

                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 8.0),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                  8.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            border: Border.all(
                                                              color:
                                                                  Colors.grey,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                          ),
                                                          child:
                                                              IntrinsicHeight(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .location_on,
                                                                      color: Color(
                                                                          0xFF699BF7),
                                                                      size: 20,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8.0),
                                                                    Text(
                                                                      'ละติจูด: ${location.lat.toStringAsFixed(5)}, '
                                                                      'ลองจิจูด: ${location.lng.toStringAsFixed(5)}',
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            16.0,
                                                                        color: Color(
                                                                            0xFF699BF7),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        8.0),
                                                                TextField(
                                                                  maxLines:
                                                                      null,
                                                                  style: GoogleFonts
                                                                      .sarabun(),
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    hintText:
                                                                        'พิมพ์ข้อความ...',
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets
                                                                            .symmetric(
                                                                      horizontal:
                                                                          12.0,
                                                                      vertical:
                                                                          8.0,
                                                                    ),
                                                                  ),
                                                                  controller:
                                                                      TextEditingController(
                                                                    text: location
                                                                        .note,
                                                                  ),
                                                                  onChanged:
                                                                      (value) async {
                                                                    bool
                                                                        isOnline =
                                                                        await _checkOfflineStatus();
                                                                    print(
                                                                        'Is online: $isOnline');
                                                                    setState(
                                                                        () {
                                                                      _locations[index]
                                                                              .note =
                                                                          value; 
                                                                    });
                                                                    final items =
                                                                        _locations
                                                                            .map((location) {
                                                                      return {
                                                                        "type":
                                                                            "position",
                                                                        "id": location
                                                                            .id,
                                                                        "latitude":
                                                                            location.lat,
                                                                        "longitude":
                                                                            location.lng,
                                                                        "note":
                                                                            location.note,
                                                                        "attachments": location
                                                                            .images
                                                                            ?.map((image) =>
                                                                                image.toJson())
                                                                            .toList(),
                                                                      };
                                                                    }).toList();
                                                                    final user =
                                                                        FirebaseAuth
                                                                            .instance
                                                                            .currentUser;

                                                                    if (isOnline) {
                                                                      saveLocationToDatabase(
                                                                          items,
                                                                          projectData
                                                                              ?.projectId,
                                                                          user
                                                                              ?.uid,
                                                                          _noteController
                                                                              .text,
                                                                          _selectedImages
                                                                              .map((image) => image.toJson())
                                                                              .toList());
                                                                    }

                                                                    saveNoteData(
                                                                        projectData
                                                                            ?.projectId,
                                                                        user
                                                                            ?.uid,
                                                                        items,
                                                                        _noteController
                                                                            .text,
                                                                        _selectedImages
                                                                            .map((image) =>
                                                                                image.toJson())
                                                                            .toList());
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        8.0),
                                                                Wrap(
                                                                  spacing: 8.0,
                                                                  runSpacing:
                                                                      8.0,
                                                                  children: (location
                                                                              .images ??
                                                                          [])
                                                                      .map<Widget>(
                                                                          (image) {
                                                                    return GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (BuildContext context) {
                                                                            return Dialog(
                                                                              child: ClipRRect(
                                                                                borderRadius: BorderRadius.circular(12.0),
                                                                                child: Image.file(
                                                                                  File(image.offlineurl),
                                                                                  fit: BoxFit.contain, 
                                                                                  width: double.infinity,
                                                                                  height: double.infinity,
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      child:
                                                                          Stack(
                                                                        alignment:
                                                                            Alignment.topRight,
                                                                        children: [
                                                                          ClipRRect(
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                            child:
                                                                                Image.file(
                                                                              File(image.offlineurl),
                                                                              width: 100,
                                                                              height: 100,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                          Positioned(
                                                                            right:
                                                                                0,
                                                                            top:
                                                                                0,
                                                                            child:
                                                                                GestureDetector(
                                                                              onTap: () {
                                                                                _removeImage(image, index, setModalState);
                                                                              },
                                                                              child: Container(
                                                                                decoration: BoxDecoration(
                                                                                  shape: BoxShape.circle,
                                                                                  color: Colors.grey[400],
                                                                                ),
                                                                                padding: const EdgeInsets.all(4),
                                                                                child: const Icon(
                                                                                  Icons.close,
                                                                                  color: Colors.white,
                                                                                  size: 18,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),

                                                                const SizedBox(
                                                                    height:
                                                                        8.0),
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .bottomRight,
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      IconButton(
                                                                        onPressed:
                                                                            () async {
                                                                          final user = FirebaseAuth
                                                                              .instance
                                                                              .currentUser;

                                                                          bool
                                                                              isOnline =
                                                                              await _checkOfflineStatus();
                                                                          setModalState(
                                                                              () {
                                                                            setState(() {
                                                                          
                                                                              // if (circleAnnotationsMap.containsKey(index)) {
                                                                              //   circleAnnotationManager?.delete(_locations[index]["circleAnnotation"]!);
                                                                              //   // circleAnnotationsMap.remove(index);
                                                                              print(_locations);
                                                                              if (_locations[index].circleAnnotation != null) {
                                                                                circleAnnotationManager?.delete(_locations[index].circleAnnotation!);
                                                                              }

                                                                              print(_locations);
                                                                           
                                                                              _locations.removeAt(index);
                                                                              final items = _locations.map((location) {
                                                                                return {
                                                                                  "type": "position",
                                                                                  "id": location.id,
                                                                                  "latitude": location.lat,
                                                                                  "longitude": location.lng,
                                                                                  "note": location.note,
                                                                                  "attachments": location.images?.map((image) => image.toJson()).toList(),
                                                                                };
                                                                              }).toList();

                                                                              if (isOnline) {
                                                                                saveLocationToDatabase(items, projectData?.projectId, user?.uid, _noteController.text, _selectedImages.map((image) => image.toJson()).toList());
                                                                              }

                                                                              saveNoteData(projectData?.projectId, user?.uid, items, _noteController.text, _selectedImages.map((image) => image.toJson()).toList());
                                                                            });
                                                                          });
                                                                        },
                                                                        icon:
                                                                            const Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                      ),
                                                                      IconButton(
                                                                        icon:
                                                                            const Icon(
                                                                          Icons
                                                                              .camera_alt_rounded, 
                                                                          color:
                                                                              Color(0xFF699BF7),
                                                                        ),
                                                                        onPressed:
                                                                            () async {
                                                                          await _openCameraModal(
                                                                              index,
                                                                              setModalState); 
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                      ),
                                                                      IconButton(
                                                                        onPressed:
                                                                            () async {
                                                                          await _pickImages(
                                                                              index,
                                                                              setModalState);
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        icon:
                                                                            const Icon(
                                                                          Icons
                                                                              .attach_file,
                                                                          color:
                                                                              Color(0xFF699BF7),
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
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 10.0),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.45, 
                                                  child: ElevatedButton.icon(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    icon:
                                                        const Icon(Icons.map_rounded),
                                                    label: Text(
                                                      'เลือกตำแหน่งเอง',
                                                      style:
                                                          GoogleFonts.sarabun(
                                                        fontSize: 12.0,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor: const Color(
                                                          0xFF699BF7),
                                                      foregroundColor: Colors
                                                          .white, 
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8.0), 
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.45, 
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      await _getCurrentLocation(
                                                          setModalState);
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                    },
                                                    icon:
                                                        const Icon(Icons.location_on),
                                                    label: Text(
                                                      'เพิ่มตำแหน่งปัจจุบัน',
                                                      style:
                                                          GoogleFonts.sarabun(
                                                        fontSize: 12.0,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor: const Color(
                                                          0xFF699BF7), 
                                                      foregroundColor: Colors
                                                          .white, 
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8.0), 
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )

                                          
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isModalOpen)
                  DraggableScrollableSheet(
                      initialChildSize: 0.5, 
                      minChildSize: 0.2, 
                      maxChildSize: 0.5, 
                      builder: (BuildContext context,
                          ScrollController scrollController) {
                        return NotificationListener<
                            DraggableScrollableNotification>(
                          onNotification: (notification) {
                          
                            if (notification.extent == notification.minExtent) {
                              setState(() {
                                _isModalOpen = false;
                              });
                            }
                            return true;
                          },
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4F2F2),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                            ),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Column(
                                children: <Widget>[
                                  const SizedBox(height: 15.0),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            16.0),
                                    child: Align(
                                      alignment: Alignment
                                          .centerLeft, 
                                      child: Text(
                                        'เลือกแผนที่',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 0),
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      // mainAxisAlignment:
                                      //     MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isLayerModalOpen =
                                                    true; 
                                              });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.2),
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 100,
                                                    width: 160,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5.0),
                                                      color: Colors.black,
                                                      image:
                                                          const DecorationImage(
                                                        image: AssetImage(
                                                            'assets/images/map6.jpg'),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  const Text(
                                                    'เลเยอร์',
                                                    style: TextStyle(
                                                      fontSize: 14.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                        // GestureDetector(
                                        //     onTap: () {
                                        //       _showHeatMapModal(context);
                                        //     },
                                        //     child: Container(
                                        //       padding:
                                        //           const EdgeInsets.all(8.0),
                                        //       decoration: BoxDecoration(
                                        //         borderRadius:
                                        //             BorderRadius.circular(10.0),
                                        //         color: Colors.white,
                                        //         boxShadow: [
                                        //           BoxShadow(
                                        //             color: Colors.grey
                                        //                 .withOpacity(0.2),
                                        //             blurRadius: 5,
                                        //           ),
                                        //         ],
                                        //       ),
                                        //       child: Column(
                                        //         crossAxisAlignment:
                                        //             CrossAxisAlignment.start,
                                        //         children: [
                                        //           Container(
                                        //             height: 100,
                                        //             width: 160,
                                        //             decoration: BoxDecoration(
                                        //               borderRadius:
                                        //                   BorderRadius.circular(
                                        //                       5.0),
                                        //               color: Colors.black,
                                        //               image:
                                        //                   const DecorationImage(
                                        //                 image: AssetImage(
                                        //                     'assets/images/map.png'), // Replace with your asset
                                        //                 fit: BoxFit.cover,
                                        //               ),
                                        //             ),
                                        //           ),
                                        //           const SizedBox(height: 8.0),
                                        //           const Text(
                                        //             'แผนที่ความหนาแน่น',
                                        //             style: TextStyle(
                                        //               fontSize: 14.0,
                                        //             ),
                                        //           ),
                                        //         ],
                                        //       ),
                                        //     )),
                                        GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isNavigateLayerModalOpen =
                                                    true;

                                                _isModalOpen = false;
                                              });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.2),
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 100,
                                                    width: 160,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5.0),
                                                      color: Colors.black,
                                                      image:
                                                          const DecorationImage(
                                                        image: AssetImage(
                                                            'assets/images/map4.jpg'), 
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  const Text(
                                                    'เส้นทาง',
                                                    style: TextStyle(
                                                      fontSize: 14.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                        GestureDetector(
                                            onTap: () {
                                              _showSelectMapModal(context);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.2),
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 100,
                                                    width: 160,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5.0),
                                                      color: Colors.black,
                                                      image:
                                                          const DecorationImage(
                                                        image: AssetImage(
                                                            'assets/images/map7.jpg'), 
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  const Text(
                                                    'เลือกแผนที่',
                                                    style: TextStyle(
                                                      fontSize: 14.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                if (_isLayerModalOpen)
                  DraggableScrollableSheet(
                      initialChildSize: 0.5,
                      minChildSize: 0.2, //
                      maxChildSize: 0.5, //
                      builder: (BuildContext context,
                          ScrollController scrollController) {
                        return NotificationListener<
                                DraggableScrollableNotification>(
                            onNotification: (notification) {
                   
                              if (notification.extent ==
                                  notification.minExtent) {
                                setState(() {
                                  _isLayerModalOpen =
                                      false; 
                                  _isModalOpen = true;
                                });
                              }
                              return true;
                            },
                            child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF4F2F2),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  child: Column(
                                    children: <Widget>[
                                      const SizedBox(height: 15.0),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'เลเยอร์',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isDismissible: false,
                                                    isScrollControlled:
                                                        true, 
                                                    shape:
                                                        const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            20.0),
                                                      ),
                                                    ),
                                                    barrierColor:
                                                        Colors.transparent,
                                                    //  backgroundColor: Colors.grey[300],
                                                    builder:
                                                        (BuildContext context) {
                                                      return FractionallySizedBox(
                                                          heightFactor:
                                                              0.9, 
                                                          widthFactor:
                                                              1.0, 
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                    16.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                      .grey[
                                                                  200], 
                                                              borderRadius:
                                                                  const BorderRadius
                                                                      .vertical(
                                                                top: Radius
                                                                    .circular(
                                                                        20.0),
                                                              ),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                             
                                                                Expanded(
                                                                  child:
                                                                      Container(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                            10.0),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                              .grey[
                                                                          200], 
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .vertical(
                                                                        top: Radius.circular(
                                                                            20.0),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        const Center(
                                                                          child:
                                                                              Text(
                                                                            'เพิ่มเลเยอร์',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 18.0,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                20.0),
                                                                        const Text(
                                                                          'ชื่อเลเยอร์',
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                16.0,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                8.0),
                                                                        TextField(
                                                                          controller:
                                                                              layerNameController,
                                                                          decoration:
                                                                              InputDecoration(
                                                                            filled:
                                                                                true,
                                                                            fillColor:
                                                                                Colors.grey[300], 
                                                                            border:
                                                                                OutlineInputBorder(
                                                                              borderRadius: BorderRadius.circular(8.0),
                                                                              borderSide: BorderSide.none, // ซ่อนขอบ
                                                                            ),
                                                                            contentPadding:
                                                                                const EdgeInsets.symmetric(
                                                                              vertical: 8.0,
                                                                              horizontal: 12.0,
                                                                            ),
                                                                            hintText:
                                                                                'ชื่อเลเยอร์',
                                                                          ),
                                                                          style:
                                                                              GoogleFonts.sarabun(
                                                                            fontSize:
                                                                                16, 
                                                                            fontWeight:
                                                                                FontWeight.normal, 
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                20.0),
                                                                        const Text(
                                                                          'เลือกแบบฟอร์ม',
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                16.0,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                10.0),
                                                                        Expanded(
                                                                          child:
                                                                              StatefulBuilder(
                                                                            builder:
                                                                                (BuildContext context, StateSetter setModalState) {
                                                                              return Container(
                                                                                decoration: BoxDecoration(
                                                                                  color: Colors.white,
                                                                                  borderRadius: BorderRadius.circular(12.0),
                                                                                ),
                                                                                child: _showClipRRect
                                                                                    ? ClipRRect(
                                                                                        borderRadius: BorderRadius.circular(12.0), 
                                                                                        child: ListView(
                                                                                          children: [
                                                                                            const SizedBox(height: 10.0),
                                                                                            for (var item in _listItems)
                                                                                              Column(
                                                                                                children: [
                                                                                                  buildListTile(item, () async {
                                                                                                    print('Selected: $item');
                                                                                                    _onItemSelected(item);
                                                                                                    late Map<String, dynamic> newLayer;
                                                                                                    late Map<String, dynamic> save;
                                                                                                    setModalState(() {
                                                                                                      int nextOrder = (layers.isNotEmpty ? layers.map((layer) => layer['order'] as int).reduce((a, b) => a > b ? a : b) : 0) + 1;

                                                                                                      String newLayerId;
                                                                                                    
                                                                                                      if (item == "เลเยอร์สัญลักษณ์") {
                                                                                                      
                                                                                                        newLayerId = generateSymbolLayerId();
                                                                                                        newLayer = {
                                                                                                          "id": newLayerId,
                                                                                                          "title": layerNameController.text.isNotEmpty ? layerNameController.text : "เลเยอร์สัญลักษณ์",
                                                                                                          "description": "เพิ่มสัญลักษณ์หรือเส้นทางที่ต้องการบนแผนที่",
                                                                                                          "imageUrl": "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
                                                                                                          "visible": true,
                                                                                                          "order": nextOrder,
                                                                                                          "paths": <Path>[],
                                                                                                          "markers": [],
                                                                                                          "questions": [],
                                                                                                          "userId": userId,
                                                                                                          "sharedWith": [],
                                                                                                          "projectId": projectData?.projectId,
                                                                                                          "isDeleted": false,
                                                                                                          "lastUpdate": DateTime.now().toUtc().toIso8601String(),
                                                                                                        };

                                                                                                        save = {
                                                                                                          "id": newLayerId,
                                                                                                          "title": layerNameController.text.isNotEmpty ? layerNameController.text : "เลเยอร์สัญลักษณ์",
                                                                                                          "description": "เพิ่มสัญลักษณ์หรือเส้นทางที่ต้องการบนแผนที่",
                                                                                                          "imageUrl": "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
                                                                                                          "visible": true,
                                                                                                          "order": nextOrder,
                                                                                                          "paths": [],
                                                                                                          "markers": [],
                                                                                                          "questions": [],
                                                                                                          "userId": userId,
                                                                                                          "sharedWith": [],
                                                                                                          "projectId": projectData?.projectId,
                                                                                                          "isDeleted": false,
                                                                                                          "lastUpdate": DateTime.now().toUtc().toIso8601String(),
                                                                                                        };
                                                                                                        setState(() {
                                                                                                          // print(DateTime.now().toUtc());
                                                                                                          layers.add(newLayer);
                                                                                                        });

                                                                                                        Navigator.of(context).pop(); 
                                                                                                      } else if (item == "เลเยอร์ความสัมพันธ์") {
                                                                                                        newLayerId = generateRelationshipLayerId();
                                                                                                        newLayer = {
                                                                                                          "id": newLayerId,
                                                                                                          "title": layerNameController.text.isNotEmpty ? layerNameController.text : "เลเยอร์ความสัมพันธ์",
                                                                                                          "description": "เพิ่มความสัมพันธ์ที่ต้องการบนแผนที่",
                                                                                                          "imageUrl": "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
                                                                                                          "visible": true,
                                                                                                          "order": nextOrder,
                                                                                                          "paths": <Path>[],
                                                                                                          "markers": [],
                                                                                                          "questions": [],
                                                                                                          "userId": userId,
                                                                                                          "sharedWith": [],
                                                                                                          "projectId": projectData?.projectId,
                                                                                                          "isDeleted": false,
                                                                                                          "lastUpdate": DateTime.now().toUtc().toIso8601String(),
                                                                                                        };
                                                                                                        save = {
                                                                                                          "id": newLayerId,
                                                                                                          "title": layerNameController.text.isNotEmpty ? layerNameController.text : "เลเยอร์ความสัมพันธ์",
                                                                                                          "description": "เพิ่มความสัมพันธ์ที่ต้องการบนแผนที่",
                                                                                                          "imageUrl": "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
                                                                                                          "visible": true,
                                                                                                          "order": nextOrder,
                                                                                                          "paths": [],
                                                                                                          "markers": [],
                                                                                                          "questions": [],
                                                                                                          "userId": userId,
                                                                                                          "sharedWith": [],
                                                                                                          "projectId": projectData?.projectId,
                                                                                                          "isDeleted": false,
                                                                                                          "lastUpdate": DateTime.now().toUtc().toIso8601String(),
                                                                                                        };

                                                                                                        setState(() {
                                                                                                          layers.add(newLayer);
                                                                                                        });
                                                                                                        layerNameController.clear();
                                                                                                        Navigator.of(context).pop(); 
                                                                                                      }
                                                                                                    });
                                                                                                    bool isOnline = await _checkOfflineStatus();
                                                                                                    if (isOnline) {
                                                                                                      if (item == "เลเยอร์สัญลักษณ์" || item == "เลเยอร์ความสัมพันธ์") {
                                                                                                        {
                                                                                                          try {
                                                                                                            final response = await http.post(
                                                                                                              postLayerUrl(),
                                                                                                              headers: {
                                                                                                                'Content-Type': 'application/json',
                                                                                                              },
                                                                                                              body: jsonEncode({
                                                                                                                "projectId": projectData?.projectId,
                                                                                                                "layer": newLayer,
                                                                                                              }),
                                                                                                            );

                                                                                                            if (response.statusCode == 200) {
                                                                                                              print("Layer successfully saved!");
                                                                                                            } else {
                                                                                                              print("Failed to save layer. Error: ${response.body}");
                                                                                                            }
                                                                                                          } catch (e) {
                                                                                                            print("Error while saving layer: $e");
                                                                                                          }
                                                                                                        }
                                                                                                      }
                                                                                                    }

                                                                                                    final hiveService = HiveService();
                                                                                                    List<Map<String, dynamic>> filteredMarkers = newLayer["markers"].map<Map<String, dynamic>>((marker) {
                                                                                                      String iconName = marker["iconName"];
                                                                                                      RegExp regExp = RegExp(r'\/([^\/]+)-');
                                                                                                      Match? match = regExp.firstMatch(iconName);
                                                                                                      String iconNameSubstring = match != null ? match.group(1) ?? '' : '';

                                                                                                      return {
                                                                                                        "lat": marker["lat"],
                                                                                                        "lng": marker["lng"],
                                                                                                        "name": marker["name"],
                                                                                                        "description": marker["description"],
                                                                                                        "color": marker["color"],
                                                                                                        "iconName": iconNameSubstring, 
                                                                                                        "imageUrls": marker["imageUrls"],
                                                                                                      };
                                                                                                    }).toList();

                                                                                                    List<Map<String, dynamic>> filteredPaths = newLayer["paths"].map<Map<String, dynamic>>((path) {
                                                                                                      List<Map<String, double>> transformedPoints = (path.points as List<Position>).map((point) {
                                                                                                        return {
                                                                                                          'lat': point.lat.toDouble(),
                                                                                                          'lng': point.lng.toDouble(),
                                                                                                        };
                                                                                                      }).toList();

                                                                                                      return {
                                                                                                        "id": path.id,
                                                                                                        "points": transformedPoints, 
                                                                                                        "color": colorToHex(path.color),
                                                                                                        "thickness": path.thickness,
                                                                                                        "name": path.name,
                                                                                                        "description": path.description,
                                                                                                      };
                                                                                                    }).toList();

                                                                                                    print(filteredPaths);

                                                                                                    final Map<String, dynamic> layerData = {
                                                                                                      "id": newLayer['id'],
                                                                                                      "title": newLayer["title"],
                                                                                                      "description": newLayer["description"],
                                                                                                      "imageUrl": newLayer["imageUrl"],
                                                                                                      "visible": newLayer["visible"],
                                                                                                      "order": newLayer["order"],
                                                                                                      "paths": filteredPaths,
                                                                                                      "markers": filteredMarkers,
                                                                                                      "questions": newLayer["questions"],
                                                                                                      "userId": newLayer["userId"],
                                                                                                      "sharedWith": newLayer["sharedWith"],
                                                                                                      "projectId": newLayer["projectId"],
                                                                                                      "isDeleted": false,
                                                                                                      'lastUpdate': DateTime.now().toUtc().toIso8601String(),
                                                                                                    };

                                                                                                    await hiveService.addLayer(projectData?.projectId, {
                                                                                                      "id": newLayer['id'],
                                                                                                      "title": newLayer["title"],
                                                                                                      "description": newLayer["description"],
                                                                                                      "imageUrl": newLayer["imageUrl"],
                                                                                                      "visible": newLayer["visible"],
                                                                                                      "order": newLayer["order"],
                                                                                                      "paths": filteredPaths,
                                                                                                      "markers": filteredMarkers,
                                                                                                      "questions": newLayer["questions"],
                                                                                                      "userId": newLayer["userId"],
                                                                                                      "sharedWith": newLayer["sharedWith"],
                                                                                                      "projectId": newLayer["projectId"],
                                                                                                      "isDeleted": false,
                                                                                                      'lastUpdate': DateTime.now().toUtc().toIso8601String(),
                                                                                                    });
                                                                                                  }),
                                                                                                  Divider(
                                                                                                    color: Colors.grey[300],
                                                                                                    thickness: 1.0,
                                                                                                    height: 8.0,
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                          ],
                                                                                        ),
                                                                                      )
                                                                                    : Padding(
                                                                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                                                                        child: Column(
                                                                                          children: [
                                                                                            Expanded(
                                                                                              flex: 2,
                                                                                              child: QuestionWidget(
                                                                                                questions: List.from(selectedForm!),
                                                                                                onQuestionsUpdated: (newQuestions) {
                                                                                              
                                                                                                  setState(() {
                                                                                                    updatedQuestions = newQuestions; 
                                                                                                  });
                                                                                                  print("Questions updated: $newQuestions");
                                                                                                },
                                                                                              ), 
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          10.0,
                                                                      horizontal:
                                                                          16.0),
                                                                  color: Colors
                                                                          .grey[
                                                                      200],
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            _onItemSelected(null);
                                                                            setState(() {});
                                                                            Navigator.pop(context); 
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.grey[300], 
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(8.0),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'ยกเลิก',
                                                                            style:
                                                                                GoogleFonts.sarabun(
                                                                              color: Colors.grey[700],
                                                                              fontSize: 16.0,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              10.0),
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () async {
                                                                            if (updatedQuestions.isNotEmpty) {
                                                                              late Map<String, dynamic> newLayer;
                                                                             
                                                                              setState(() {
                                                                                int nextOrder = (layers.isNotEmpty ? layers.map((layer) => layer['order'] as int).reduce((a, b) => a > b ? a : b) : 0) + 1;
                                                                                String newLayerId = generateFromLayerId();
                                                                                newLayer = {
                                                                                  "id": newLayerId,
                                                                                  "title": layerNameController.text.isNotEmpty ? layerNameController.text : "เลเยอร์แบบฟอร์ม",
                                                                                  "description": "คลิกบน Building เพื่อกรอกแบบฟอร์ม",
                                                                                  "imageUrl": "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
                                                                                  "visible": true,
                                                                                  "order": nextOrder,
                                                                                  "paths": <Path>[],
                                                                                  "markers": [],
                                                                                  "questions": updatedQuestions,
                                                                                  "userId": userId,
                                                                                  "sharedWith": [],
                                                                                  "projectId": projectData?.projectId,
                                                                                  "isDeleted": false,
                                                                                  "lastUpdate": DateTime.now().toUtc().toIso8601String(),
                                                                                };
                                                                                setState(() {
                                                                                  layers.add(newLayer);
                                                                                });
                                                                              });
                                                                              bool isOnline = await _checkOfflineStatus();
                                                                              if (isOnline) {
                                                                                try {
                                                                                  final response = await http.post(
                                                                                    postLayerUrl(),
                                                                                    headers: {
                                                                                      'Content-Type': 'application/json',
                                                                                    },
                                                                                    body: jsonEncode({
                                                                                      "projectId": projectData?.projectId,
                                                                                      "layer": newLayer,
                                                                                    }),
                                                                                  );

                                                                                  if (response.statusCode == 200) {
                                                                                  
                                                                                    Navigator.of(context).pop();
                                                                                  } else {
                                                                                    print("Failed to save layer. Error: ${response.body}");
                                                                                    Navigator.of(context).pop();
                                                                                  }
                                                                                } catch (e) {
                                                                                  print("Error while saving layer: $e");
                                                                                  Navigator.of(context).pop();
                                                                                }
                                                                              }
                                                                              final hiveService = HiveService();
                                                                              List<Map<String, dynamic>> filteredMarkers = newLayer["markers"].map<Map<String, dynamic>>((marker) {
                                                                                String iconName = marker["iconName"];
                                                                                RegExp regExp = RegExp(r'\/([^\/]+)-');
                                                                                Match? match = regExp.firstMatch(iconName);
                                                                                String iconNameSubstring = match != null ? match.group(1) ?? '' : '';

                                                                                return {
                                                                                  "lat": marker["lat"],
                                                                                  "lng": marker["lng"],
                                                                                  "name": marker["name"],
                                                                                  "description": marker["description"],
                                                                                  "color": marker["color"],
                                                                                  "iconName": iconNameSubstring,
                                                                                  "imageUrls": marker["imageUrls"],
                                                                                };
                                                                              }).toList();

                                                                              List<Map<String, dynamic>> filteredPaths = newLayer["paths"].map<Map<String, dynamic>>((path) {
                                                                                
                                                                                List<Map<String, double>> transformedPoints = (path.points as List<Position>).map((point) {
                                                                                  return {
                                                                                    'lat': point.lat.toDouble(),
                                                                                    'lng': point.lng.toDouble(),
                                                                                  };
                                                                                }).toList();

                                                                                return {
                                                                                  "id": path.id,
                                                                                  "points": transformedPoints, 
                                                                                  "color": colorToHex(path.color),
                                                                                  "thickness": path.thickness,
                                                                                  "name": path.name,
                                                                                  "description": path.description,
                                                                                };
                                                                              }).toList();

                                                                              print(filteredPaths);

                                                                              final Map<String, dynamic> layerData = {
                                                                                "id": newLayer['id'],
                                                                                "title": newLayer["title"],
                                                                                "description": newLayer["description"],
                                                                                "imageUrl": newLayer["imageUrl"],
                                                                                "visible": newLayer["visible"],
                                                                                "order": newLayer["order"],
                                                                                "paths": filteredPaths,
                                                                                "markers": filteredMarkers,
                                                                                "questions": newLayer["questions"],
                                                                                "userId": newLayer["userId"],
                                                                                "sharedWith": newLayer["sharedWith"],
                                                                                "projectId": newLayer["projectId"],
                                                                                "isDeleted": false,
                                                                                'lastUpdate': DateTime.now().toUtc().toIso8601String(),
                                                                              };

                                                                              await hiveService.addLayer(projectData?.projectId, {
                                                                                "id": newLayer['id'],
                                                                                "title": newLayer["title"],
                                                                                "description": newLayer["description"],
                                                                                "imageUrl": newLayer["imageUrl"],
                                                                                "visible": newLayer["visible"],
                                                                                "order": newLayer["order"],
                                                                                "paths": filteredPaths,
                                                                                "markers": filteredMarkers,
                                                                                "questions": newLayer["questions"],
                                                                                "userId": newLayer["userId"],
                                                                                "sharedWith": newLayer["sharedWith"],
                                                                                "projectId": newLayer["projectId"],
                                                                                "isDeleted": false,
                                                                                'lastUpdate': DateTime.now().toUtc().toIso8601String(),
                                                                              });
                                                                            } else {
                                                                              late Map<String, dynamic> newLayer;
                                                                              setState(() {
                                                                                int nextOrder = (layers.isNotEmpty ? layers.map((layer) => layer['order'] as int).reduce((a, b) => a > b ? a : b) : 0) + 1;
                                                                                String newLayerId = generateFromLayerId();
                                                                                newLayer = {
                                                                                  "id": newLayerId,
                                                                                  "title": layerNameController.text.isNotEmpty ? layerNameController.text : "เลเยอร์แบบฟอร์ม",
                                                                                  "description": "คลิกบน Building เพื่อกรอกแบบฟอร์ม",
                                                                                  "imageUrl": "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
                                                                                  "visible": true,
                                                                                  "order": nextOrder,
                                                                                  "paths": <Path>[],
                                                                                  "markers": [],
                                                                                  "questions": selectedForm,
                                                                                  "userId": userId,
                                                                                  "sharedWith": [],
                                                                                  "projectId": projectData?.projectId,
                                                                                  "isDeleted": false,
                                                                                  "lastUpdate": DateTime.now().toUtc().toIso8601String(),
                                                                                };
                                                                                setState(() {
                                                                                  layers.add(newLayer);
                                                                                });
                                                                              });
                                                                              bool isOnline = await _checkOfflineStatus();
                                                                              if (isOnline) {
                                                                                try {
                                                                                
                                                                                  final response = await http.post(
                                                                                    postLayerUrl(),
                                                                                    headers: {
                                                                                      'Content-Type': 'application/json',
                                                                                    },
                                                                                    body: jsonEncode({
                                                                                      "projectId": projectData?.projectId,
                                                                                      "layer": newLayer, 
                                                                                    }),
                                                                                  );

                                                                                  if (response.statusCode == 200 || true) {
                                                                                    print("Layer saved successfully");
                                                                                   
                                                                                    Navigator.of(context).pop();
                                                                                  }
                                                                                } catch (e) {
                                                                                  print("Error while saving layer: $e");
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    const SnackBar(content: Text("เกิดข้อผิดพลาดขณะบันทึกเลเยอร์")),
                                                                                  );
                                                                                  Navigator.of(context).pop();
                                                                                }
                                                                              }

                                                                              final hiveService = HiveService();
                                                                              List<Map<String, dynamic>> filteredMarkers = newLayer["markers"].map<Map<String, dynamic>>((marker) {
                                                                              
                                                                                String iconName = marker["iconName"];
                                                                                RegExp regExp = RegExp(r'\/([^\/]+)-');
                                                                                Match? match = regExp.firstMatch(iconName);
                                                                                String iconNameSubstring = match != null ? match.group(1) ?? '' : '';

                                                                                return {
                                                                                  "lat": marker["lat"],
                                                                                  "lng": marker["lng"],
                                                                                  "name": marker["name"],
                                                                                  "description": marker["description"],
                                                                                  "color": marker["color"],
                                                                                  "iconName": iconNameSubstring, 
                                                                                  "imageUrls": marker["imageUrls"],
                                                                                };
                                                                              }).toList();

                                                                              List<Map<String, dynamic>> filteredPaths = newLayer["paths"].map<Map<String, dynamic>>((path) {
                                                                              
                                                                                List<Map<String, double>> transformedPoints = (path.points as List<Position>).map((point) {
                                                                                  return {
                                                                                    'lat': point.lat.toDouble(),
                                                                                    'lng': point.lng.toDouble(),
                                                                                  };
                                                                                }).toList();

                                                                                return {
                                                                                  "id": path.id,
                                                                                  "points": transformedPoints,
                                                                                  "color": colorToHex(path.color),
                                                                                  "thickness": path.thickness,
                                                                                  "name": path.name,
                                                                                  "description": path.description,
                                                                                };
                                                                              }).toList();

                                                                              print(filteredPaths);

                                                                              final Map<String, dynamic> layerData = {
                                                                                "id": newLayer['id'],
                                                                                "title": newLayer["title"],
                                                                                "description": newLayer["description"],
                                                                                "imageUrl": newLayer["imageUrl"],
                                                                                "visible": newLayer["visible"],
                                                                                "order": newLayer["order"],
                                                                                "paths": filteredPaths,
                                                                                "markers": filteredMarkers,
                                                                                "questions": newLayer["questions"],
                                                                                "userId": newLayer["userId"],
                                                                                "sharedWith": newLayer["sharedWith"],
                                                                                "projectId": newLayer["projectId"],
                                                                                "isDeleted": false,
                                                                                'lastUpdate': DateTime.now().toUtc().toIso8601String(),
                                                                              };

                                                                              await hiveService.addLayer(projectData?.projectId, {
                                                                                "id": newLayer['id'],
                                                                                "title": newLayer["title"],
                                                                                "description": newLayer["description"],
                                                                                "imageUrl": newLayer["imageUrl"],
                                                                                "visible": newLayer["visible"],
                                                                                "order": newLayer["order"],
                                                                                "paths": filteredPaths,
                                                                                "markers": filteredMarkers,
                                                                                "questions": newLayer["questions"],
                                                                                "userId": newLayer["userId"],
                                                                                "sharedWith": newLayer["sharedWith"],
                                                                                "projectId": newLayer["projectId"],
                                                                                "isDeleted": false,
                                                                                'lastUpdate': DateTime.now().toUtc().toIso8601String(),
                                                                              });
                                                                              // Navigator.of(context).pop(); // ปิด Modal
                                                                            }
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                const Color(0xFF699BF7), 
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(8.0),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'บันทึก',
                                                                            style:
                                                                                GoogleFonts.sarabun(
                                                                              color: Colors.white,
                                                                              fontSize: 16.0,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ));
                                                    },
                                                  );
                                                },
                                                child: const Text(
                                                  'เพิ่มเลเยอร์',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 15.0),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Column(
                                          children: layers.map((layer) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0),
                                              child: Slidable(
                                                key:
                                                    Key(layer['id'].toString()),
                                                direction: Axis
                                                    .horizontal,

                                                endActionPane: ActionPane(
                                                  motion: const ScrollMotion(),
                                                  children: [
                                                    SlidableAction(
                                                      onPressed: (BuildContext
                                                          context) {
                                                      
                                                        _showDeleteConfirmationDialog(
                                                            context, layer);
                                                      },
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                      icon: Icons.delete,
                                                    ),
                                                    SlidableAction(
                                                      onPressed: (BuildContext
                                                          context) {
                                                    
                                                        _showEditLayer(
                                                            context, layer);
                                                      },
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFECECEC),
                                                      foregroundColor:
                                                          Colors.grey,
                                                      icon: Icons.settings,
                                                    ),
                                                  ],
                                                ),

                                                child: GestureDetector(
                                                  onTap: () {
                                                  
                                                    if (layer['id']
                                                        .toString()
                                                        .startsWith(
                                                            "layer-symbol-")) {
                                                      setState(() {
                                                        _isSymbolLayerModalOpen =
                                                            true;
                                                        selectedMode =
                                                            'เพิ่มสัญลักษณ์';
                                                        _selectedLayer = layer;
                                                        markers =
                                                            _selectedLayer?[
                                                                'markers'];
                                                        existingPaths =
                                                            _selectedLayer?[
                                                                'paths'];
                                                        _isLayerModalOpen =
                                                            false;
                                                        _isModalOpen = false;
                                                      });
                                                    } else if (layer['id']
                                                        .toString()
                                                        .startsWith(
                                                            "layer-relationship-")) {
                                                      setState(() {
                                                        _isRelationshipLayerModalOpen =
                                                            true;
                                                        selectedMode =
                                                            "เพิ่มความสัมพันธ์";
                                                        _selectedLayer = layer;
                                                        _isLayerModalOpen =
                                                            false;
                                                        _isModalOpen = false;
                                                      });
                                                    } else if (layer['id']
                                                        .toString()
                                                        .startsWith(
                                                            "layer-form-")) {
                                                      setState(() {
                                                        print(
                                                            layer['questions']);
                                                        _isFormLayerModalOpen =
                                                            true;
                                                        _isModalOpen = false;
                                                        _isLayerModalOpen =
                                                            false;
                                                        selectedMode =
                                                            "กรอกแบบฟอร์ม";
                                                        _selectedLayer = layer;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16.0),
                                                    width: double.infinity,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFECECEC),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                layer['title'],
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize:
                                                                      16.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 2.0),
                                                              Text(
                                                                layer[
                                                                    'description'],
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      14.0,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            layer['visible']
                                                                ? Icons
                                                                    .visibility
                                                                : Icons
                                                                    .visibility_off,
                                                            color: layer[
                                                                    'visible']
                                                                ? Colors.blue
                                                                : Colors.grey,
                                                          ),
                                                          iconSize: 28.0,
                                                          onPressed: () async {
                                                            final newVisibility =
                                                                !layer[
                                                                    'visible'];
                                                            await Future.wait([
                                                              _updateMarkersVisibility(
                                                                  layer,
                                                                  newVisibility),
                                                              _updatePathsVisibility(
                                                                  layer,
                                                                  newVisibility),
                                                              _updateRelationshipVisibility(
                                                                  layer,
                                                                  newVisibility),
                                                              _updateFormVisibility(
                                                                  layer,
                                                                  newVisibility)
                                                            ]);
                                                            setState(() {
                                                              layer['visible'] =
                                                                  newVisibility;
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      )
                                    
                                    ],
                                  ),
                                )));
                      }),
                if (_isSymbolLayerModalOpen)
                  DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.2,
                    maxChildSize: 0.9,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Column(
                        children: [
                        
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9.0, vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade600
                                    .withOpacity(0.4), 
                                borderRadius:
                                    BorderRadius.circular(10.0), 
                              ),
                              padding: const EdgeInsets.all(2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedMode =
                                              'เพิ่มสัญลักษณ์'; 
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: selectedMode ==
                                                  'เพิ่มสัญลักษณ์'
                                              ? Colors.white
                                              : Colors
                                                  .transparent, 
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          boxShadow: selectedMode ==
                                                  'เพิ่มสัญลักษณ์'
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    blurRadius: 4.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [], 
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 6.0), 
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                            ),
                                            SizedBox(width: 8.0),
                                            Text(
                                              'เพิ่มสัญลักษณ์',
                                              style: TextStyle(fontSize: 14.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2.0),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedMode =
                                              'เพิ่มเส้นทาง'; 
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: selectedMode == 'เพิ่มเส้นทาง'
                                              ? Colors.white
                                              : Colors
                                                  .transparent, 
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          boxShadow: selectedMode ==
                                                  'เพิ่มเส้นทาง'
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    blurRadius: 4.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [], 
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 6.0),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.timeline,
                                            ),
                                            SizedBox(width: 8.0),
                                            Text(
                                              'เพิ่มเส้นทาง',
                                              style: TextStyle(fontSize: 14.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F2F2),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 15.0),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedLayer?['title'] ??
                                              'รายละเอียดเลเยอร์',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _isSymbolLayerModalOpen =
                                                  false; 
                                              _isLayerModalOpen = true;
                                              _selectedLayer =
                                                  null; 
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Align(
                                      alignment: Alignment
                                          .centerLeft, 
                                      child: Text(
                                        selectedMode == 'เพิ่มสัญลักษณ์'
                                            ? 'คลิกบนแผนที่เพื่อเพิ่มสัญลักษณ์'
                                            : 'คลิกบนแผนที่เพื่อเพิ่มเส้นทางใหม่',
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),

                                  selectedMode == 'เพิ่มสัญลักษณ์'
                                      ? Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount:
                                                _selectedLayer?["markers"]
                                                        ?.length ??
                                                    0, 
                                            itemBuilder: (context, index) {
                                             
                                              final marker =
                                                  _selectedLayer?["markers"]
                                                      ?[index];
                                              if (marker == null) {
                                                return const SizedBox(); 
                                              }

                                              return ListTile(
                                                title: Text(
                                                  marker["name"] ?? "ไม่มีชื่อ",
                                                  style: GoogleFonts.sarabun(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  marker["description"] ??
                                                      "ไม่มีคำอธิบาย",
                                                  style: GoogleFonts.sarabun(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                leading: Image.asset(
                                                  marker["iconName"] ??
                                                      "assets/default.png",
                                                  width: 30.0,
                                                  height: 30.0,
                                                ),
                                                onTap: () {
                                                  _showMarkerPopup(
                                                      marker); 
                                                },
                                              );
                                            },
                                          ),
                                        )
                                      : Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount: _selectedLayer?["paths"]
                                                    ?.length ??
                                                0, 
                                            itemBuilder: (context, index) {
                                              final path =
                                                  _selectedLayer?["paths"]
                                                      ?[index]; 

                                              return ListTile(
                                                title: Text(
                                                  path.name ?? '',
                                                  style: GoogleFonts.sarabun(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  path.description ?? '',
                                                  style: GoogleFonts.sarabun(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                leading: Icon(
                                                  Icons.line_axis,
                                                  color: path.color,
                                                  size: 30.0,
                                                ),
                                                onTap: () {
                                                  _showPathPopup(
                                                      path); 
                                                },
                                              );
                                            },
                                          ),
                                        ),

                                
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (_isFormLayerModalOpen)
                  DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.2,
                    maxChildSize: 0.9,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Column(
                        children: [
                        
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F2F2),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 15.0),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedLayer?['title'] ??
                                              'รายละเอียดเลเยอร์',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _isFormLayerModalOpen =
                                                  false;
                                              _isLayerModalOpen = true;
                                              _selectedLayer =
                                                  null; 
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Align(
                                      alignment: Alignment
                                          .centerLeft,
                                      child: Text(
                                        'คลิกบน Building เพื่อกรอกแบบฟอร์ม',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),

                                  selectedMode == 'เพิ่มสัญลักษณ์'
                                      ? Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount:
                                                _selectedLayer?["markers"]
                                                        ?.length ??
                                                    0, 
                                            itemBuilder: (context, index) {
                                           
                                              final marker =
                                                  _selectedLayer?["markers"]
                                                      ?[index];
                                              if (marker == null) {
                                                return const SizedBox(); 
                                              }

                                              return ListTile(
                                                title: Text(marker["name"] ??
                                                    "ไม่มีชื่อ"), 
                                                subtitle: Text(marker[
                                                        "description"] ??
                                                    "ไม่มีคำอธิบาย"), 
                                                leading: Image.asset(
                                                  marker["iconName"] ??
                                                      "assets/default.png",
                                                  width: 30.0,
                                                  height: 30.0,
                                                ),
                                                onTap: () {
                                                  _showMarkerPopup(
                                                      marker);
                                                },
                                              );
                                            },
                                          ),
                                        )
                                      : Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount: _selectedLayer?["paths"]
                                                    ?.length ??
                                                0, 
                                            itemBuilder: (context, index) {
                                              final path =
                                                  _selectedLayer?["paths"]
                                                      ?[index]; 

                                              return ListTile(
                                                title: Text(path.name),
                                                subtitle:
                                                    Text(path.description),
                                                leading: Icon(
                                                  Icons.line_axis,
                                                  color: path.color,
                                                  size: 30.0,
                                                ),
                                                onTap: () {
                                                  _showPathPopup(
                                                      path);
                                                },
                                              );
                                            },
                                          ),
                                        ),

                                  
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (false)
                  DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.2,
                    maxChildSize: 0.9,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Column(
                        children: [
                          // กล่องสี่เหลี่ยมสองกล่องด้านบนสุด

                          // Container สีพื้นหลัง
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F2F2),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 15.0),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedLayer?['title'] ??
                                              'รายละเอียดเลเยอร์',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _isFormLayerModalOpen =
                                                  false; // ปิด modal
                                              _isLayerModalOpen = true;
                                              _selectedLayer =
                                                  null; // รีเซ็ต layer ที่เลือก
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  // เพิ่มข้อความที่แสดงข้างบน ListView
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Align(
                                      alignment: Alignment
                                          .centerLeft, // จัดตำแหน่งชิดซ้าย
                                      child: Text(
                                        'คลิกบน Building เพื่อกรอกแบบฟอร์ม',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),

                                  selectedMode == 'เพิ่มสัญลักษณ์'
                                      ? Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount:
                                                _selectedLayer?["markers"]
                                                        ?.length ??
                                                    0, // ตรวจสอบ null ก่อน
                                            itemBuilder: (context, index) {
                                              // ดึงข้อมูล marker จาก List
                                              final marker =
                                                  _selectedLayer?["markers"]
                                                      ?[index];
                                              if (marker == null) {
                                                return const SizedBox(); // กรณี marker เป็น null
                                              }

                                              return ListTile(
                                                title: Text(marker["name"] ??
                                                    "ไม่มีชื่อ"), // แสดงชื่อ
                                                subtitle: Text(marker[
                                                        "description"] ??
                                                    "ไม่มีคำอธิบาย"), // แสดงคำอธิบาย
                                                leading: Image.asset(
                                                  marker["iconName"] ??
                                                      "assets/default.png", // ใช้ default หากไม่มี iconName
                                                  width: 30.0,
                                                  height: 30.0,
                                                ),
                                                onTap: () {
                                                  _showMarkerPopup(
                                                      marker); // เรียก Popup เมื่อคลิก
                                                },
                                              );
                                            },
                                          ),
                                        )
                                      : Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount: _selectedLayer?["paths"]
                                                    ?.length ??
                                                0, // จำนวน paths
                                            itemBuilder: (context, index) {
                                              final path =
                                                  _selectedLayer?["paths"]
                                                      ?[index]; // path แต่ละตัว

                                              return ListTile(
                                                title: Text(path.name),
                                                subtitle:
                                                    Text(path.description),
                                                leading: Icon(
                                                  Icons.line_axis,
                                                  color: path.color,
                                                  size: 30.0,
                                                ),
                                                onTap: () {
                                                  _showPathPopup(
                                                      path); // เรียก Popup เมื่อคลิก
                                                },
                                              );
                                            },
                                          ),
                                        ),

                                  // ไม่แสดงอะไรเมื่อเงื่อนไขไม่ตรง
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (_isNavigateLayerModalOpen)
                  DraggableScrollableSheet(
                    initialChildSize: 0.2,
                    minChildSize: 0.2,
                    maxChildSize: 0.2,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Column(
                        children: [
                          // กล่องสี่เหลี่ยมสองกล่องด้านบนสุด

                          // Container สีพื้นหลัง
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F2F2),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 15.0),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedLayer?['title'] ?? 'เส้นทาง',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _isNavigateLayerModalOpen =
                                                  false; 
                                              _isLayerModalOpen = false;
                                              _selectedLayer =
                                                  null; 
                                              polylineNavigateAnnotationManager
                                                  ?.deleteAll();
                                              pointNavigateAnnotationManager
                                                  ?.deleteAll();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                 
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Align(
                                      alignment: Alignment
                                          .centerLeft, 
                                      child: Text(
                                        '${_totalDistance.toStringAsFixed(2)} km',
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),

                                  selectedMode == 'เพิ่มสัญลักษณ์'
                                      ? Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount:
                                                _selectedLayer?["markers"]
                                                        ?.length ??
                                                    0, 
                                            itemBuilder: (context, index) {
                                            
                                              final marker =
                                                  _selectedLayer?["markers"]
                                                      ?[index];
                                              if (marker == null) {
                                                return const SizedBox();
                                              }

                                              return ListTile(
                                                title: Text(marker["name"] ??
                                                    "ไม่มีชื่อ"), 
                                                subtitle: Text(marker[
                                                        "description"] ??
                                                    "ไม่มีคำอธิบาย"), 
                                                leading: Image.asset(
                                                  marker["iconName"] ??
                                                      "assets/default.png", 
                                                  width: 30.0,
                                                  height: 30.0,
                                                ),
                                                onTap: () {
                                                  _showMarkerPopup(
                                                      marker); 
                                                },
                                              );
                                            },
                                          ),
                                        )
                                      : Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount: _selectedLayer?["paths"]
                                                    ?.length ??
                                                0,
                                            itemBuilder: (context, index) {
                                              final path =
                                                  _selectedLayer?["paths"]
                                                      ?[index]; 

                                              return ListTile(
                                                title: Text(path.name),
                                                subtitle:
                                                    Text(path.description),
                                                leading: Icon(
                                                  Icons.line_axis,
                                                  color: path.color,
                                                  size: 30.0,
                                                ),
                                                onTap: () {
                                                  _showPathPopup(
                                                      path); 
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (_isRelationshipLayerModalOpen)
                  DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.2,
                    maxChildSize: 0.9,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Column(
                        children: [
                        
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9.0, vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade600
                                    .withOpacity(0.4), 
                                borderRadius:
                                    BorderRadius.circular(10.0), 
                              ),
                              padding: const EdgeInsets.all(2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedLinePattern =
                                              'เส้นทึบ';
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: selectedLinePattern ==
                                                  'เส้นทึบ'
                                              ? Colors.white
                                              : Colors
                                                  .transparent, 
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          boxShadow: selectedLinePattern ==
                                                  'เส้นทึบ'
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    blurRadius: 4.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [], 
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 6.0), 
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(width: 8.0),
                                            Text(
                                              'เส้นทึบ',
                                              style: TextStyle(fontSize: 14.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedLinePattern =
                                              'เส้นประ'; 
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: selectedLinePattern ==
                                                  'เส้นประ'
                                              ? Colors.white
                                              : Colors
                                                  .transparent, 
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          boxShadow: selectedLinePattern ==
                                                  'เส้นประ'
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    blurRadius: 4.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 6.0), 
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(width: 8.0),
                                            Text(
                                              'เส้นประ',
                                              style: TextStyle(fontSize: 14.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedLinePattern =
                                              'เส้นขนาน';
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: selectedLinePattern ==
                                                  'เส้นขนาน'
                                              ? Colors.white
                                              : Colors
                                                  .transparent, 
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          boxShadow: selectedLinePattern ==
                                                  'เส้นขนาน'
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    blurRadius: 4.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [], 
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 6.0), 
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(width: 8.0),
                                            Text(
                                              'เส้นขนาน',
                                              style: TextStyle(fontSize: 14.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedLinePattern =
                                              'เส้นซิกแซก'; 
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: selectedLinePattern ==
                                                  'เส้นซิกแซก'
                                              ? Colors.white
                                              : Colors
                                                  .transparent, 
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          boxShadow: selectedLinePattern ==
                                                  'เส้นซิกแซก'
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    blurRadius: 4.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [], 
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 6.0), 
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(width: 8.0),
                                            Text(
                                              'เส้นซิกแซก',
                                              style: TextStyle(fontSize: 14.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                       
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F2F2),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 15.0),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedLayer?['title'] ??
                                              'รายละเอียดเลเยอร์',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _isRelationshipLayerModalOpen =
                                                  false; 
                                              _isLayerModalOpen = true;
                                              _selectedLayer =
                                                  null; 
                                              _isLayerModalOpen = true;
                                             
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                              
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Align(
                                      alignment: Alignment
                                          .centerLeft, 
                                      child: Text(
                                        'คลิกบนแผนที่เพื่อเพิ่มความสัมพันธ์ใหม่',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),

                                  selectedMode == 'เพิ่มความสัมพันธ์'
                                      ? Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount: relationships
                                                .where((relationship) =>
                                                    relationship.layerId ==
                                                    _selectedLayer?['id'])
                                                .toList()
                                                .length,
                                            itemBuilder: (context, index) {
                                            
                                              final relationship = relationships
                                                  .where((relationship) =>
                                                      relationship.layerId ==
                                                      _selectedLayer?['id'])
                                                  .toList()[index];

                                              return ListTile(
                                                title: Text(
                                                    'เส้นที่ ${index + 1}'), 
                                                subtitle: Text(
                                                    relationship.description),
                                                leading: Icon(
                                                  _getIconForRelationshipType(
                                                      relationship
                                                          .type), 
                                                  size: 30.0,
                                                  color: Colors
                                                      .blue, 
                                                ),
                                                onTap: () {
                                                  _showRelationshipPopup(
                                                      relationship); 
                                                },
                                              );
                                            },
                                          ),
                                        )
                                      : Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            itemCount: _selectedLayer?["paths"]
                                                    ?.length ??
                                                0, 
                                            itemBuilder: (context, index) {
                                              final path =
                                                  _selectedLayer?["paths"]
                                                      ?[index]; 

                                              return ListTile(
                                                title: Text(path.name),
                                                subtitle:
                                                    Text(path.description),
                                                leading: Icon(
                                                  Icons.line_axis,
                                                  color: path.color,
                                                  size: 30.0,
                                                ),
                                                onTap: () {
                                                  _showPathPopup(
                                                      path);
                                                },
                                              );
                                            },
                                          ),
                                        ),

                                 
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
              ],
            ),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question['type'] == 'checkbox' ||
            question['type'] == 'multiple_choice') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        question['showOnMap'] =
                            !(question['showOnMap'] ?? false);
                      });
                    },
                    child: Container(
                      width: 24.0,
                      height: 24.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (question['showOnMap'] ?? false)
                            ? Colors.blue 
                            : Colors.grey[500], 
                      ),
                      child: (question['showOnMap'] ?? false)
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16.0,
                            )
                          : const SizedBox.shrink(), 
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    'แสดงบนแผนที่',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],
        TextField(
          controller: TextEditingController(text: question['label']),
          onChanged: (value) {
            setState(() {
              question['label'] = value; 
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        if (question['type'] == 'text') ...[
          TextField(
            decoration: InputDecoration(
              hintText: 'กรอกข้อมูลที่นี่',
              filled: true,
              fillColor: Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
            ),
          ),
        ] else if (question['type'] == 'number') ...[
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'กรอกข้อมูลที่นี่',
              filled: true,
              fillColor: Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
            ),
          ),
        ] else if (question['type'] == 'multiple_choice') ...[
          ...List<Widget>.from(
            question['options'].asMap().entries.map(
              (entry) {
                int index = entry.key;
                var option = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24.0,
                        height: 24.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[700],
                        ),
                        child: Icon(
                          Icons.circle,
                          color: Colors.grey[100],
                          size: 23.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: TextField(
                          controller:
                              TextEditingController(text: option['label']),
                          onChanged: (value) {
                            setState(() {
                              question['options'][index]['label'] = value;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else if (question['type'] == 'checkbox') ...[
          ...List<Widget>.from(
            question['options'].asMap().entries.map(
              (entry) {
                int index = entry.key;
                var option = entry.value;
                return Row(
                  children: [
                    Checkbox(
                      value: option['selected'] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          question['options'][index]['selected'] =
                              value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(text: option['label']),
                        onChanged: (value) {
                          setState(() {
                            question['options'][index]['label'] = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 12.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ] else ...[
          const Text('Unsupported question type'),
        ],
      ],
    );
  }
}

class Path {
  final String id;
  String name;
  String description;
  Color? color;
  final List<Position> points;
  double thickness;
  PolylineAnnotation? polylineAnnotation;

  Path({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.thickness,
    this.color,
    this.polylineAnnotation,
  });
  Map<String, dynamic> toMap() {
    String colorToHex(Color? color) {
      return '#${color?.value.toRadixString(16).substring(2).toUpperCase()}';
    }

    return {
      'id': id,
      'points':
          points.map((point) => {'lat': point.lat, 'lng': point.lng}).toList(),
      'color': colorToHex(color),
      'name': name,
      'description': description,
      'thickness': thickness,
    };
  }
}

class Ralationship {
  final String id;
  String description;
  String layerId;
  String? userId;
  String type;
  final List<Position> points;
  PolylineAnnotation? polylineAnnotation;
  String updatedAt;
  bool? isDelete;

  Ralationship({
    required this.id,
    required this.layerId,
    required this.description,
    required this.type,
    required this.points,
    this.polylineAnnotation,
    required this.updatedAt,
    this.isDelete,
    this.userId,
  });
}

// {
//   "_id": {
//     "$oid": "675bac0a209a6a9450b7e6bd"
//   },
//   "layerId": "layer-form-de865353-bd2a-4e7b-b2e8-dccfb49b000f",
//   "buildingId": "173119727",
//   "answers": {
//     "1": "heart_disease",
//     "2": "no_raw_cooked",
//     "3": "eat_msg"
//   },
//   "color": "#6366f1",
//   "coordinates": [
//     100.56913331151009,
//     13.850175568699527
//   ],
//   "projectId": "675ba43fa237ebdbc044f06e",
//   "userId": "fQAXK0TgK1OsegBmEIiQ6fR8NGX2"
// }

class Answer {
  final String id;
  final String layerId;
  String buildingId;
  Map<int, String> answers;
  String? color;
  String? lastModified;
  final List<Position> coordinates;
  PolygonAnnotation? polygonAnnotation;

  Answer({
    required this.id,
    required this.layerId,
    required this.buildingId,
    required this.answers,
    this.color,
    required this.coordinates,
    this.polygonAnnotation,
    this.lastModified,
  });

  // Map<String, dynamic> toJson() {
  //   return {
  //     'layerId': layerId,
  //     'buildingId': buildingId,
  //     'answers': answers,
  //     'color': color,
  //     'lastModified': lastModified,
  //     'coordinates': coordinates.map((position) => position.toJson()).toList(),
  //     'isDelete': false,
  //     // 'polygonAnnotation':
  //     //     polygonAnnotation?.toJson(), // หากมี polygonAnnotation
  //   };
  // }
}

class Location {
  String id;
  final double lat;
  final double lng;
  String note;
  List<Attachment>? images; 
  CircleAnnotation? circleAnnotation;
  String type;

  Location({
    required this.id,
    required this.lat,
    required this.lng,
    required this.type,
    this.note = '',
    this.images,
    this.circleAnnotation,
  });
}

class Attachment {
  final String name; 
  final String type; 
  final int size; 
  final int lastModified; 
  String url;
  String offlineurl;

  Attachment({
    required this.name,
    required this.type,
    required this.size,
    required this.lastModified,
    required this.url,
    required this.offlineurl,
  });
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size': size,
      'lastModified': lastModified,
      'url': url,
      'offlineurl': offlineurl
    };
  }
}

class Project {
  final String projectId;
  final String projectName;
  // final String userIds;
  final List<Position> selectedPoints;
  final String lastUpdate;
  final String createdAt;

  Project({
    required this.projectId,
    required this.projectName,
    // required this.userIds,
    required this.selectedPoints,
    required this.lastUpdate,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    var points = (json['selectedPoints'] as List)
        .map((point) => (Position(point['lng'], point['lat'])));
    //  Position(point['lat'],point['lng'])))

    return Project(
      projectId: json['_id'],
      projectName: json['projectName'],
      // userIds: json['userIds'].toList(),
      selectedPoints: points.toList(),
      lastUpdate: json['lastUpdate'],
      createdAt: json['createdAt'],
    );
  }
}
