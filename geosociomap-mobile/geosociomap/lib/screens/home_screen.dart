import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geosociomap/hive/hiveService.dart';
import 'package:geosociomap/screens/api.dart';
import 'package:geosociomap/screens/editprojectpage.dart';
import 'package:geosociomap/screens/project_screens/createprojectmobile_screen.dart';
import 'package:geosociomap/screens/projectmap_screen.dart';
import 'package:geosociomap/screens/url.dart';
import 'package:geosociomap/screens/usersetting_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosociomap/components/components.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Add this import
import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
// import 'package:location/location.dart';
import 'dart:math';
import 'package:geotypes/src/geojson.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenPageState createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreen> {
  List<dynamic> projects = [];
  List<dynamic> layers = [];
  List<Map<String, dynamic>> layersByProject = [];
  List<Map<String, dynamic>> buildingsData = [];

  @override
  void initState() {
    super.initState();
    fetchProjectsAndLayers(); // ดึงข้อมูลโปรเจกต์และเลเยอร์พร้อมกันเมื่อเริ่มต้น
  }

  List<Ralationship> _relationships = [];

  // Future<void> fetchProjectsAndLayers() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     print('User is not signed in');
  //     return;
  //   }

  //   final hiveService = HiveService();

  //   final projectsUrl = getProjectBaseUrl(user.uid);
  //   final layersUrl = getLayerBaseUrl(user.uid, 'layers');

  //   var connectivityResult = await Connectivity().checkConnectivity();
  //   bool isOnline = connectivityResult != ConnectivityResult.none;

  //   try {
  //     if (isOnline) {
  //       // ดึงข้อมูลโปรเจกต์และเลเยอร์พร้อมกัน
  //       final responses = await Future.wait([
  //         http.get(projectsUrl),
  //         http.get(layersUrl),
  //       ]);

  //       final projectsResponse = responses[0];
  //       final layersResponse = responses[1];

  //       if (projectsResponse.statusCode == 200 &&
  //           layersResponse.statusCode == 200) {
  //         final fetchedProjects = jsonDecode(projectsResponse.body);
  //         final fetchedLayers = jsonDecode(layersResponse.body);

  //         setState(() {
  //           projects = fetchedProjects; // ข้อมูลโปรเจกต์
  //           layersByProject =
  //               List<Map<String, dynamic>>.from(fetchedLayers['projects']);
  //           // เข้าไปที่ layers ในแต่ละ project
  //           layersByProject.forEach((project) {
  //             if (project['layers'] != null) {
  //               List<dynamic> layers = project['layers']; // เข้าถึง layers
  //               layers.forEach((layer) {
  //                 // เช็คว่า id ของ layer เริ่มต้นด้วย 'layer-symbol-'
  //                 if (layer['id'] != null &&
  //                     layer['id'].startsWith('layer-symbol-')) {
  //                   // เข้าไปดู markers ของ layer
  //                   List<dynamic> markers = layer['markers'] ?? [];

  //                   // เปลี่ยนค่า iconName ของ markers ให้ใช้ assets/symbols/{iconName}/{iconName}-{color}.PNG
  //                   for (var marker in markers) {
  //                     String iconName = marker['iconName'] ?? '';
  //                     String color = marker['color'] ?? '';

  //                     if (iconName.isNotEmpty && color.isNotEmpty) {
  //                       marker['iconName'] =
  //                           'assets/symbols/$iconName/$iconName-$color.PNG';
  //                     }
  //                   }
  //                   // อัพเดท markers ใน layer
  //                   layer['markers'] = markers;
  //                   print(layer);
  //                 }

  //                 if (layer['paths'] != null) {
  //                   List<dynamic> paths =
  //                       layer['paths']; // เข้าถึง paths ของ layer
  //                   List<Path> convertedPaths = paths.map((path) {
  //                     // แปลง points จาก List<dynamic> เป็น List<Position>
  //                     List<Position> points = (path['points'] as List)
  //                         .map((point) => Position(point['lng'], point['lat']))
  //                         .toList();
  //                     double thickness =
  //                         double.parse(path['thickness'].toString());
  //                     // แปลง color เป็น int
  //                     Color? color;
  //                     if (path['color'] != null && path['color'].isNotEmpty) {
  //                       String colorString = path['color'];
  //                       color = Color(int.parse(
  //                           "0xFF${colorString.replaceAll('#', '')}"));
  //                     }

  //                     // สร้าง Path object จากข้อมูลที่มี
  //                     return Path(
  //                       id: path['id'] ?? '',
  //                       name: path['name'] ?? '',
  //                       description: path['description'] ?? '',
  //                       points: points,
  //                       thickness: thickness ?? 1.0,
  //                       color: color,
  //                       polylineAnnotation: null,
  //                     );
  //                   }).toList();

  //                   // อัพเดท paths ใน layer ให้เป็น List<Path>
  //                   layer['paths'] = convertedPaths;

  //                   print(layer);
  //                 }
  //               });

  //               // อัปเดต layers ใน project
  //               project['layers'] = layers;
  //             }
  //           });
  //         });

  //         print('Projects: $projects');
  //         print('Layers: $layersByProject');
  //       } else {
  //         throw Exception(
  //           'Failed to load data. '
  //           'Projects status: ${projectsResponse.statusCode}, '
  //           'Layers status: ${layersResponse.statusCode}',
  //         );
  //       }
  //     } else {
  //       // หากออฟไลน์ ให้ดึงข้อมูลจาก Hive
  //       final offlineProjects = hiveService.getProjects();
  //       final offlineLayers = hiveService.getLayers();

  //       setState(() {
  //         projects = offlineProjects;
  //         layersByProject = List<Map<String, dynamic>>.from(offlineLayers);
  //       });

  //       print('Loaded projects and layers from Hive');
  //     }
  //   } catch (e) {
  //     print('Error fetching projects and layers: $e');
  //   }
  // }

  Future<bool> _checkOfflineStatus() async {
    // ตรวจสอบสถานะเครือข่ายหรือการดาวน์โหลดแบบออฟไลน์
    try {
      // ใช้การตรวจสอบเครือข่ายเบื้องต้น
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return false; // ถ้าการตรวจสอบล้มเหลวถือว่าไม่ offline
    }
  }

  Future<void> fetchProjectsAndLayers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not signed in');
      return;
    }
    //  layersByProject = [];ง

    final hiveService = HiveService();
    // hiveService.resetProjectBox();
    // hiveService.resetLayersBox();
    // hiveService.resetNotesBox();
    // hiveService.resetRelationshipBox();

    final projectsUrl = getProjectBaseUrl(user.uid);
    // final layersUrl = getLayerBaseUrl(user.uid, 'layers');

    bool isOnline = await _checkOfflineStatus();
    print(isOnline);
    try {
      if (isOnline) {
        // ดึงข้อมูลโปรเจกต์และเลเยอร์พร้อมกัน
        final responses = await Future.wait([
          http.get(projectsUrl),
          // http.get(layersUrl),
        ]);

        final projectsResponse = responses[0];
        // final layersResponse = responses[1];

        print(projectsResponse);
        // print(layersResponse);

        if (projectsResponse.statusCode == 200) {
          final fetchedProjects = jsonDecode(projectsResponse.body);
          // final fetchedLayers = jsonDecode(layersResponse.body);

          setState(() {
            projects = fetchedProjects; // ข้อมูลโปรเจกต์
            // layersByProject =
            //     List<Map<String, dynamic>>.from(fetchedLayers['projects']);
            // // เข้าไปที่ layers ในแต่ละ project
            // layersByProject.forEach((project) {
            //   if (project['layers'] != null) {
            //     List<dynamic> layers = project['layers']; // เข้าถึง layers
            //     layers.forEach((layer) {
            //       // เช็คว่า id ของ layer เริ่มต้นด้วย 'layer-symbol-'
            //       if (layer['id'] != null &&
            //           layer['id'].startsWith('layer-symbol-')) {
            //         // เข้าไปดู markers ของ layer
            //         List<dynamic> markers = layer['markers'] ?? [];

            //         // เปลี่ยนค่า iconName ของ markers ให้ใช้ assets/symbols/{iconName}/{iconName}-{color}.PNG
            //         for (var marker in markers) {
            //           String iconName = marker['iconName'] ?? '';
            //           String color = marker['color'] ?? '';

            //           if (iconName.isNotEmpty && color.isNotEmpty) {
            //             marker['iconName'] =
            //                 'assets/symbols/$iconName/$iconName-$color.PNG';
            //           }
            //         }
            //         // อัพเดท markers ใน layer
            //         layer['markers'] = markers;
            //         // print(layer);
            //       }

            //       if (layer['paths'] != null) {
            //         List<dynamic> paths =
            //             layer['paths']; // เข้าถึง paths ของ layer
            //         List<Path> convertedPaths = paths.map((path) {
            //           // แปลง points จาก List<dynamic> เป็น List<Position>
            //           List<Position> points = (path['points'] as List)
            //               .map((point) => Position(point['lng'], point['lat']))
            //               .toList();
            //           double thickness =
            //               double.parse(path['thickness'].toString());
            //           // แปลง color เป็น int
            //           Color? color;
            //           if (path['color'] != null && path['color'].isNotEmpty) {
            //             String colorString = path['color'];
            //             color = Color(int.parse(
            //                 "0xFF${colorString.replaceAll('#', '')}"));
            //           }

            //           // สร้าง Path object จากข้อมูลที่มี
            //           return Path(
            //             id: path['id'] ?? '',
            //             name: path['name'] ?? '',
            //             description: path['description'] ?? '',
            //             points: points,
            //             thickness: thickness,
            //             color: color,
            //             polylineAnnotation: null,
            //           );
            //         }).toList();

            //         // อัพเดท paths ใน layer ให้เป็น List<Path>

            //         layer['paths'] = convertedPaths;

            //         List<Map<String, dynamic>> filteredMarkers =
            //             layer["markers"].map<Map<String, dynamic>>((marker) {
            //           // ใช้ RegExp เพื่อดึงค่าส่วนที่ต้องการจาก iconName
            //           String iconName = marker["iconName"];
            //           RegExp regExp = RegExp(r'\/([^\/]+)-');
            //           Match? match = regExp.firstMatch(iconName);
            //           String iconNameSubstring =
            //               match != null ? match.group(1) ?? '' : '';

            //           return {
            //             "lat": marker["lat"],
            //             "lng": marker["lng"],
            //             "name": marker["name"],
            //             "description": marker["description"],
            //             "color": marker["color"],
            //             "iconName":
            //                 iconNameSubstring, // ใช้ค่าที่ได้จากการแยกออก
            //             "imageUrls": marker["imageUrls"],
            //           };
            //         }).toList();

            //         print(layer["paths"]);

            //         String colorToHex(Color color) {
            //           return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
            //         }

            //         List<Map<String, dynamic>> filteredPaths =
            //             layer["paths"].map<Map<String, dynamic>>((path) {
            //           print(path);
            //           // แปลง path.points ที่เป็น List<Position> ให้เป็น List<Map<String, double>> ที่มี 'lat' และ 'lng'
            //           List<Map<String, double>> transformedPoints =
            //               (path.points as List<Position>)
            //                   .map((point) => {
            //                         'lat': point.lat.toDouble(),
            //                         'lng': point.lng.toDouble()
            //                       })
            //                   .toList();

            //           return {
            //             "id": path.id,
            //             "points":
            //                 transformedPoints, // ใช้ transformedPoints ที่แปลงแล้ว
            //             "color": colorToHex(path.color),
            //             "thickness": path.thickness,
            //             "name": path.name,
            //             "description": path.description,
            //           };
            //         }).toList();

            //         final Map<String, dynamic> layerData = {
            //           "id": layer['id'],
            //           "title": layer["title"],
            //           "description": layer["description"],
            //           "imageUrl": layer["imageUrl"],
            //           "visible": layer["visible"],
            //           "order": layer["order"],
            //           "paths": filteredPaths,
            //           "markers": filteredMarkers,
            //           "questions": layer["questions"],
            //           "userId": layer["userId"],
            //           "sharedWith": layer["sharedWith"],
            //           "projectId": layer["projectId"],
            //         };

            //         print(layerData);
            //         // hiveService.putLayer(layer["projectId"], layerData);
            //         // print(layer);
            //       }
            //     });

            //     // อัปเดต layers ใน project
            //     project['layers'] = layers;
            //   }
          });
          // });

          print('Projects: $projects');
          for (var project in projects) {
            final List<String> userIds = [];
            for (var email in project['userIds']) {
              // เรียก getUserIdByEmail แล้วเก็บ UID ที่ได้
              final uid = await getUserIdByEmail(email);
              if (uid != null) {
                userIds.add(uid);
              } else {
                print('No user found for email: $email');
              }
            }
            final Map<String, dynamic> projectData = {
              '_id': project['_id'], 
              'projectName': project['projectName'],
              'selectedPoints': project['selectedPoints'].map((point) {
                
                    return {
                      'lat': point['lat'], 
                      'lng': point['lng'], 
                    };
                  }).toList() ??
                  [], 
              'lastUpdate': project['lastUpdate'], 
              'createdAt': project['createdAt'],
              'userIds': userIds, 
            };

        
            hiveService.saveProject(projectData['_id'], projectData, user.uid);
          }
          print('Layers: $layersByProject');
        } else {
          throw Exception('Failed to load data. '
              'Projects status: ${projectsResponse.statusCode}, '
            
              );
        }
      } else {
      
        final hiveService = HiveService();
        await hiveService.initHive();
        print("offline");
        final offlineProjects = await hiveService.getProjects(user.uid);
        // final offlineLayers = hiveService.getLayers(user.uid);

        // print(offlineLayers);

        // final result = offlineLayers.entries.map((entry) {
        //   final projectId = entry.key;
        // final layers = List<Map<dynamic, dynamic>>.from(entry.value);

        // final transformedLayers = layers.map((layer) {
        //   return {
        //     'id': layer['id'],
        //     'title': layer['title'],
        //     'description': layer['description'],
        //     'imageUrl': layer['imageUrl'],
        //     'visible': layer['visible'],
        //     'order': layer['order'],
        //     'paths': layer['paths'],
        //     'markers': layer['markers'],
        //     'questions': layer['questions']
        //   };
        // }).toList();

        //   return {
        //     'projectId': projectId,
        //     // 'layers': transformedLayers,
        //   };
        // }).toList();

        // print("offlineProjects");
        // print(offlineProjects);

        print("offlineLayers");
        // print(result);

        setState(() {
          projects = offlineProjects;
          // layersByProject = List<Map<String, dynamic>>.from(result);
          // layersByProject.forEach((project) {
          //   if (project['layers'] != null) {
          //     List<dynamic> layers = project['layers']; // เข้าถึง layers
          //     layers.forEach((layer) {
          //       // เช็คว่า id ของ layer เริ่มต้นด้วย 'layer-symbol-'
          //       if (layer['id'] != null &&
          //           layer['id'].startsWith('layer-symbol-')) {
          //         // เข้าไปดู markers ของ layer
          //         List<dynamic> markers = layer['markers'] ?? [];

          //         // เปลี่ยนค่า iconName ของ markers ให้ใช้ assets/symbols/{iconName}/{iconName}-{color}.PNG
          //         for (var i = 0; i < markers.length; i++) {
          //           var marker = markers[i];

          //           if (marker is! Map<String, dynamic>) {
          //             // ถ้าไม่ใช่ Map<String, dynamic>, เปลี่ยนเป็น Map<String, dynamic>
          //             marker = Map<String, dynamic>.from(marker);
          //           }

          //           print("marker");
          //           print(marker);

          //           String iconName = marker['iconName'] ?? '';
          //           String color = marker['color'] ?? '';

          //           if (iconName.isNotEmpty && color.isNotEmpty) {
          //             // สร้าง URL ของไอคอนใหม่
          //             String newIconPath =
          //                 'assets/symbols/$iconName/$iconName-$color.PNG';

          //             // เช็คว่า iconName ปัจจุบันมีการลงท้ายด้วย ".PNG" หรือไม่
          //             if (marker['iconName'] != newIconPath &&
          //                 !marker['iconName'].endsWith('.PNG')) {
          //               marker['iconName'] =
          //                   newIconPath; // กำหนดค่าใหม่ถ้าไม่ลงท้ายด้วย .PNG
          //               print("passsss");
          //               print(marker['iconName']);
          //             }
          //           }

          //           // อัพเดท markers ใน layer หลังจากปรับปรุง marker
          //           markers[i] = marker;
          //         }
          //         // อัพเดท markers ใน layer
          //         layer['markers'] = markers;
          //         print(layer['markers']);
          //       }

          //       if (layer['paths'] != null) {
          //         List<dynamic> paths =
          //             layer['paths']; // เข้าถึง paths ของ layer
          //         List<Path> convertedPaths = paths.map((path) {
          //           // แปลง points จาก List<dynamic> เป็น List<Position>
          //           List<Position> points = (path['points'] as List)
          //               .map((point) => Position(point['lng'], point['lat']))
          //               .toList();
          //           double thickness =
          //               double.parse(path['thickness'].toString());
          //           // แปลง color เป็น int
          //           Color? color;
          //           if (path['color'] != null && path['color'].isNotEmpty) {
          //             String colorString = path['color'];
          //             color = Color(
          //                 int.parse("0xFF${colorString.replaceAll('#', '')}"));
          //           }

          //           // สร้าง Path object จากข้อมูลที่มี
          //           return Path(
          //             id: path['id'] ?? '',
          //             name: path['name'] ?? '',
          //             description: path['description'] ?? '',
          //             points: points,
          //             thickness: thickness,
          //             color: color,
          //             polylineAnnotation: null,
          //           );
          //         }).toList();

          //         layer['paths'] = convertedPaths;
          //       }
          //     });

          //     // อัปเดต layers ใน project
          //     project['layers'] = layers;
          //   }
          // });
        });
        // print(layersByProject);
        print('Loaded projects and layers from Hive');
      }
    } catch (e) {
      print('Error fetching projects and layers: $e');
    }
  }

  void mergeData(dynamic offlineData, dynamic onlineData) {
    for (var i = 0; i < offlineData.length; i++) {
      final offlineLayer = offlineData[i];
      final onlineLayer = onlineData.firstWhere(
          (onlineLayer) => onlineLayer['id'] == offlineLayer['id'],
          orElse: () => null);

      if (onlineLayer != null) {
      
        DateTime offlineUpdatedAt =
            DateTime.parse(offlineLayer['updatedAt'] ?? '1970-01-01T00:00:00Z');
        DateTime onlineUpdatedAt =
            DateTime.parse(onlineLayer['updatedAt'] ?? '1970-01-01T00:00:00Z');

        if (offlineUpdatedAt.isAfter(onlineUpdatedAt)) {
        
          onlineLayer.addAll(offlineLayer);
        } else {
         
          offlineLayer.addAll(onlineLayer);
        }
      }
    }
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> fetchLayers(String projectId) async {
  
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not signed in');
      return;
    }
    //  layersByProject = [];
    // final layersUrl = getLayerProject(projectId, user.uid);
    bool isOnline = await _checkOfflineStatus();

    print(isOnline);
    try {
      if (isOnline) {
        final responses = await http.get(getLayerProject(projectId, user.uid));
        print(responses.statusCode);
        if (responses.statusCode == 200) {
          final fetchedLayers = jsonDecode(responses.body);

          final hiveService = HiveService();
          final List<dynamic> offlineLayers =
              await hiveService.getLayerProject(projectId);
          print(fetchedLayers);
          print(offlineLayers);

          setState(() {
            fetchedLayers.forEach((layer) {
              if (layer['id'] != null &&
                  layer['id'].startsWith('layer-symbol-')) {
                print(layer['markers']);
                List<dynamic> markers = layer['markers'] ?? [];
                for (var marker in markers) {
                  String iconName = marker['iconName'] ?? '';
                  String color = marker['color'] ?? '';

                  if (iconName.isNotEmpty && color.isNotEmpty) {
                    String newIconPath =
                        'assets/symbols/$iconName/$iconName-$color.PNG';

                  
                    if (marker['iconName'] != newIconPath &&
                        !marker['iconName'].endsWith('.PNG')) {
                      marker['iconName'] =
                          newIconPath; 
                    }
                  }
                }
                layer['markers'] = markers;
              }

              if (layer['paths'] != null && layer['paths'] is List) {
                List<dynamic> paths = layer['paths']; 
                if (paths.isNotEmpty) {
                  List<Path> convertedPaths = paths.map((path) {
                    List<Position> points = (path['points'] as List)
                        .map((point) => Position(point['lng'], point['lat']))
                        .toList();
                    print("fetchedLayers5");
                    double thickness =
                        double.parse(path['thickness'].toString());
                    Color? color;
                    if (path['color'] != null && path['color'].isNotEmpty) {
                      String colorString = path['color'];
                      color = Color(
                          int.parse("0xFF${colorString.replaceAll('#', '')}"));
                    }
                    return Path(
                      id: path['id'] ?? '',
                      name: path['name'] ?? '',
                      description: path['description'] ?? '',
                      points: points,
                      thickness: thickness,
                      color: color,
                      polylineAnnotation: null,
                    );
                  }).toList();
                  layer['paths'] = convertedPaths;
                } else {
                  layer['paths'] = [];
                }
              } else {
                layer['paths'] =
                    [];
              }
            });
            for (var layer in offlineLayers) {
              if (layer['id'] != null &&
                  layer['id'].startsWith('layer-symbol-')) {
                List<dynamic> markers = layer['markers'] ?? [];
                for (var marker in markers) {
                  String iconName = marker['iconName'] ?? '';
                  String color = marker['color'] ?? '';

                  if (iconName.isNotEmpty && color.isNotEmpty) {
                    String newIconPath =
                        'assets/symbols/$iconName/$iconName-$color.PNG';

                 
                    if (marker['iconName'] != newIconPath &&
                        !marker['iconName'].endsWith('.PNG')) {
                      marker['iconName'] = newIconPath;
                    }
                  }
                }
                layer['markers'] = markers;
              }

              if (layer['paths'] != null && layer['paths'] is List) {
                List<dynamic> paths = layer['paths'];
                if (paths.isNotEmpty) {
                  List<Path> convertedPaths = paths.map((path) {
                    List<Position> points = (path['points'] as List)
                        .map((point) => Position(point['lng'], point['lat']))
                        .toList();
                    print("fetchedLayers5");
                    double thickness =
                        double.parse(path['thickness'].toString());
                    Color? color;
                    if (path['color'] != null && path['color'].isNotEmpty) {
                      String colorString = path['color'];
                      color = Color(
                          int.parse("0xFF${colorString.replaceAll('#', '')}"));
                    }
                    return Path(
                      id: path['id'] ?? '',
                      name: path['name'] ?? '',
                      description: path['description'] ?? '',
                      points: points,
                      thickness: thickness,
                      color: color,
                      polylineAnnotation: null,
                    );
                  }).toList();
                  layer['paths'] = convertedPaths;
                } else {
                  layer['paths'] = [];
                }
              } else {
                layer['paths'] =
                    []; 
              }
            }
          });

          Map<String, dynamic> mergedLayers = {};
          if (fetchedLayers.isNotEmpty && offlineLayers.isNotEmpty) {
            for (var layer in [...offlineLayers, ...fetchedLayers]) {
              String id = layer['id'];
              if (mergedLayers.containsKey(id)) {
                if (DateTime.parse(layer['lastUpdate'])
                    .isAfter(DateTime.parse(mergedLayers[id]['lastUpdate']))) {
                  mergedLayers[id] = layer;
                }
              } else {
                mergedLayers[id] = layer;
              }
            }
          } else if (offlineLayers.isEmpty && fetchedLayers.isNotEmpty) {
            for (var layer in [...fetchedLayers]) {
              String id = layer['id'];
              mergedLayers[id] = layer;
            }
          } else if (fetchedLayers.isEmpty && offlineLayers.isNotEmpty) {
            for (var layer in [...offlineLayers]) {
              String id = layer['id'];
              mergedLayers[id] = layer;
            }
          } else {
            mergedLayers = {};
          }

          // print("==============mergedLayers==============");
          // print(mergedLayers);
          // print("==============mergedLayers=============");

          List<dynamic> syncedLayers = mergedLayers.values
              .where((layer) => layer['isDeleted'] == false)
              .toList();

          // print("==============syncedLayers==============");
          // print(syncedLayers);
          // print("==============syncedLayers=============");

          if (syncedLayers.isNotEmpty) {
            List<Map<String, dynamic>> transformedLayers =
                syncedLayers.map((layer) {
              List<Map<String, dynamic>> filteredMarkers =
                  (layer["markers"] as List)
                      .map<Map<String, dynamic>>((marker) {
                String iconName = marker["iconName"];
                RegExp regExp = RegExp(r'\/([^\/]+)-');
                Match? match = regExp.firstMatch(iconName);
                String iconNameSubstring =
                    match != null ? match.group(1) ?? '' : '';

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

              return {
                "id": layer['id'],
                "title": layer["title"],
                "description": layer["description"],
                "imageUrl": layer["imageUrl"],
                "visible": layer["visible"],
                "order": layer["order"],
                "paths": filteredPaths,
                "markers": filteredMarkers,
                "questions": layer["questions"],
                "userId": layer["userId"],
                "sharedWith": layer["sharedWith"],
                "projectId": projectId,
                "isDeleted": false,
                'lastUpdate': DateTime.now().toUtc().toIso8601String(),
              };
            }).toList();
            print('transformedLayers: $transformedLayers');
            syncLayersToBackend(projectId, transformedLayers);
            hiveService.putLayerProject(projectId, transformedLayers);
          }
          print('transformedLayers: Done');
          print('Before Final: $syncedLayers');
          setState(() {
            layers = syncedLayers;
          });
        }
      } else {
        final hiveService = HiveService();
        final List<dynamic> offlineLayers =
            await hiveService.getLayerProject(projectId);
        print("offline======================");
        print(offlineLayers);

        final transformedLayers = offlineLayers.map((layer) {
          return {
            'id': layer['id'],
            'title': layer['title'],
            'description': layer['description'],
            'imageUrl': layer['imageUrl'],
            'visible': layer['visible'],
            'order': layer['order'],
            'paths': layer['paths'],
            'markers': layer['markers'],
            'questions': layer['questions'],
            'userId': layer['userId'],
            'projectId': layer['projectId'],
            "lastUpdate": layer["lastUpdate"],
            "isDeleted": layer["isDeleted"],
          };
        }).toList();

        setState(() {
          for (var layer in transformedLayers) {
            if (layer['id'] != null &&
                layer['id'].startsWith('layer-symbol-')) {
              List<dynamic> markers = layer['markers'] ?? [];

              for (var i = 0; i < markers.length; i++) {
                var marker = markers[i];

                if (marker is! Map<String, dynamic>) {
                  marker = Map<String, dynamic>.from(marker);
                }

                String iconName = marker['iconName'] ?? '';
                String color = marker['color'] ?? '';

                if (iconName.isNotEmpty && color.isNotEmpty) {
                  String newIconPath =
                      'assets/symbols/$iconName/$iconName-$color.PNG';

               
                  if (marker['iconName'] != newIconPath &&
                      !marker['iconName'].endsWith('.PNG')) {
                    marker['iconName'] =
                        newIconPath; 
                  }
                }
                markers[i] = marker;
              }
              layer['markers'] = markers;
            }

            if (layer['paths'] != null) {
              List<dynamic> paths = layer['paths'];
              List<Path> convertedPaths = paths.map((path) {
             
                List<Position> points = (path['points'] as List)
                    .map((point) => Position(point['lng'], point['lat']))
                    .toList();
                double thickness = double.parse(path['thickness'].toString());
             
                Color? color;
                if (path['color'] != null && path['color'].isNotEmpty) {
                  String colorString = path['color'];
                  color = Color(
                      int.parse("0xFF${colorString.replaceAll('#', '')}"));
                }

            
                return Path(
                  id: path['id'] ?? '',
                  name: path['name'] ?? '',
                  description: path['description'] ?? '',
                  points: points,
                  thickness: thickness,
                  color: color,
                  polylineAnnotation: null,
                );
              }).toList();

            
              layer['paths'] = convertedPaths;
            }
          }

        
          // project['layers'] = layers;
          setState(() {
            layers = transformedLayers;
          });
        });

    
        print('Loaded projects and layers from Hive');
      }
    } catch (e) {
      print('Error fetching projects and layers: $e');
    }
  }


  void _processMarkers(Map<String, dynamic> layer) {
    if (layer['id'] != null && layer['id'].startsWith('layer-symbol-')) {
      List<dynamic> markers = layer['markers'] ?? [];

      for (var marker in markers) {
        String iconName = marker['iconName'] ?? '';
        String color = marker['color'] ?? '';

        if (iconName.isNotEmpty && color.isNotEmpty) {
          marker['iconName'] = 'assets/symbols/$iconName/$iconName-$color.PNG';
        }
      }

      layer['markers'] = markers;
      print('Updated markers in layer ${layer['id']}');
    }
  }


  void _processPaths(Map<String, dynamic> layer) {
    if (layer['paths'] != null) {
      List<dynamic> paths = layer['paths'];
      List<Path> convertedPaths = paths.map((path) {
      
        List<Position> points = (path['points'] as List)
            .map((point) => Position(point['lng'], point['lat']))
            .toList();
        double thickness = double.parse(path['thickness'].toString());

      
        Color? color;
        if (path['color'] != null && path['color'].isNotEmpty) {
          String colorString = path['color'];
          color = Color(int.parse("0xFF${colorString.replaceAll('#', '')}"));
        }

        return Path(
          id: path['id'] ?? '',
          name: path['name'] ?? '',
          description: path['description'] ?? '',
          points: points,
          thickness: thickness,
          color: color,
          polylineAnnotation: null,
        );
      }).toList();

      layer['paths'] = convertedPaths;
      print('Updated paths in layer ${layer['id']}');
    }
  }

  Future<String> getOfflineFilePath(String fileName) async {
    Directory dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/offline_files/$fileName';
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

  Future<Map<String, dynamic>> fetchNotes(String projectId) async {
    try {
    
      bool isOnline = await _checkOfflineStatus();

      if (isOnline) {
        User? user = FirebaseAuth.instance.currentUser;
        final response = await http.get(getNotesBaseUrl(projectId, user?.uid));

        if (response.statusCode == 200) {
          final Map<String, dynamic> noteData = jsonDecode(response.body);
          final hiveService = HiveService();
       
          User? user = FirebaseAuth.instance.currentUser;

          final Map<String, dynamic> noteDataOffline =
              await hiveService.getNote(projectId) ?? {};

          print('-----------note online-------------');
          print(noteData);
          print(noteData['updatedAt']);
          print('-----------note online-------------');

          print('-----------noteDataOffline-------------');
          print(noteDataOffline);
          print(noteDataOffline['updatedAt']);
          print('-----------noteDataOffline-------------');

          Map<String, dynamic> mergedLayers = {};

          if (noteDataOffline.isNotEmpty && noteData.isNotEmpty) {
            if (DateTime.parse(noteData['updatedAt'])
                .isAfter(DateTime.parse(noteDataOffline['updatedAt']))) {
              mergedLayers = noteData;
            } else {
              mergedLayers = noteDataOffline;
            }
          } else if (noteDataOffline.isEmpty) {
            mergedLayers = noteData;
          }

          print("----------mergedLayers-------------");
          print(mergedLayers);
          print("----------mergedLayers-------------");

       
          if (mergedLayers['attachments'] != null &&
              mergedLayers['attachments'] is List) {
            final attachments = mergedLayers['attachments'] as List;
            final updatedAttachments = await Future.wait(
              attachments.map((file) async {
                final fileName = file['lastModified'].toString();
                if (file['url'] != "") {
                  final offlinePath =
                      await downloadAndSaveFile(file['url'], fileName);

                  return {
                    'name': file['name'],
                    'type': file['type'],
                    'size': file['size'],
                    'lastModified': file['lastModified'],
                    'url': file['url'],
                    'offlineurl': offlinePath
                  };
                } else {
                  final File offlineImage = File(file['offlineurl']);
                  final uploadedUrl =
                      await uploadImage(offlineImage, postFileUrl());
                  if (uploadedUrl != null) {
                    return {
                      'name': file['name'],
                      'type': file['type'],
                      'size': file['size'],
                      'lastModified': file['lastModified'],
                      'url': uploadedUrl[
                          'fileUrl'], 
                      'offlineurl': file['offlineurl']
                    };
                  }
                }
              }),
            );

            mergedLayers['attachments'] = updatedAttachments;
          } else {
            print('attachments is null or not a List');
          }

         
          for (var item in mergedLayers['items']) {
            if (item['attachments'] != null && item['attachments'] is List) {
              final attachments = item['attachments'] as List;
              final updatedAttachments = await Future.wait(
                attachments.map((file) async {
                  final fileName = file['lastModified'].toString();
                  if (file['url'] != "") {
                    final offlinePath =
                        await downloadAndSaveFile(file['url'], fileName);

                    return {
                      'name': file['name'],
                      'type': file['type'],
                      'size': file['size'],
                      'lastModified': file['lastModified'],
                      'url': file['url'], 
                      'offlineurl': offlinePath
                    };
                  } else {
                    final File offlineImage = File(file['offlineurl']);
                    final uploadedUrl =
                        await uploadImage(offlineImage, postFileUrl());
                    if (uploadedUrl != null) {
                      return {
                        'name': file['name'],
                        'type': file['type'],
                        'size': file['size'],
                        'lastModified': file['lastModified'],
                        'url': uploadedUrl[
                            'fileUrl'], 
                        'offlineurl': file['offlineurl']
                      };
                    }
                  }
                }),
              );
              item['attachments'] = updatedAttachments;
              print(updatedAttachments);
            } else {
              print('attachments is null or not a List');
            }
          }

          await hiveService.putNote(projectId, {
            "projectId": projectId,
            "userId": user?.uid,
            "items": List<Map<String, dynamic>>.from(mergedLayers['items']),
            "note": mergedLayers['note'],
            "attachments":
                List<Map<String, dynamic>>.from(mergedLayers['attachments']),
            "updatedAt": DateTime.now().toUtc().toIso8601String(),
          });
          saveLocationToDatabase(
              List<Map<String, dynamic>>.from(mergedLayers['items']),
              projectId,
              user?.uid,
              mergedLayers['note'],
              List<Map<String, dynamic>>.from(mergedLayers['attachments']));

        
          print("----------final note--------------");
          print(mergedLayers);
          print("----------final note--------------");

        

          return mergedLayers;
        } else if (response.statusCode == 404) {
          print('No notes found for project ID: $projectId');
          return {};
        } else {
          throw Exception(
              'Failed to fetch notes with status code ${response.statusCode}');
        }
      } else {
        final hiveService = HiveService();
        User? user = FirebaseAuth.instance.currentUser;

        final Map<String, dynamic> noteData =
            await hiveService.getNote(projectId) ?? {};

        print("------noteData offline----------");
        print(noteData);
        print("--------------------------------");
        return noteData;
      }
    
    } catch (error) {
      print('Error fetching notes: $error');
      throw Exception('Error fetching notes: $error');
    }
  }

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

  bool _isLoading = false;
  String _errorMessage = '';
  Future<void> fetchRelationships(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    final hiveService = HiveService();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      bool isOnline = await _checkOfflineStatus();
      print('Is online: $isOnline');

      if (isOnline) {
        final Uri apiUrl = getRelationshipBaseUrl(projectId, user?.uid);
        final response = await http.get(apiUrl);
        print(response);
        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
        
          final List<Map<String, dynamic>> cachedRelationships =
              await hiveService.getRelationships(projectId, user?.uid);

          List<Map<String, dynamic>> dataList =
              List<Map<String, dynamic>>.from(data);
          print("------data = jsonDecode(response.body)----------");
          print(dataList);
          print("------data = jsonDecode(response.body)----------");

          print("----------cachedRelationships-----------");
          print(cachedRelationships);
          print("----------cachedRelationships)----------");

          Map<String, dynamic> mergedLayers = {};

          for (var relationship in [...dataList, ...cachedRelationships]) {
            String id = relationship['id'];
            if (mergedLayers.containsKey(id)) {
              if (DateTime.parse(relationship['updatedAt'])
                  .isAfter(DateTime.parse(mergedLayers[id]['updatedAt']))) {
                mergedLayers[id] = relationship;
              }
            } else {
              mergedLayers[id] = relationship;
            }
          }

          List<dynamic> syncedLayers = mergedLayers.values
              .where((layer) => layer['isDelete'] == false)
              .where((layer) => layers.any((storedLayer) => storedLayer['id'] == layer['layerId']))
              .toList();

          print("----------syncedLayers Relationships-----------");
          print(syncedLayers);
          print("----------syncedLayers Relationships-----------");

          for (var relationship in syncedLayers) {
            print("--------before save---------------");
            print(relationship);
            print("--------before save---------------");
            syncRelationships(
              layerId: relationship['layerId'].toString(),
              id: relationship['id'].toString(),
              points: (relationship['points'] as List)
                  .map<List<double>>((point) => List<double>.from(point))
                  .toList(),
              type: relationship['type'].toString(),
              projectId: relationship['projectId'].toString(),
              description: relationship['description'].toString(),
              userId: user?.uid,
            );
            print('createRelationship Database');
            await hiveService.putRelationship(relationship['id'], relationship);
            print('Relationship with id ${relationship['id']} has been saved.');
          }
          print("-------------sync done------------");

          List<Ralationship> toRelationships = syncedLayers
              .where((layer) => layers.any((storedLayer) =>
                  storedLayer['id'] ==
                  layer['layerId']))
              .map((layer) {
            List<Position> points = [];

            if (layer['points'] != null) {
              points = (layer['points'] as List)
                  .map((point) => Position(point[0], point[1]))
                  .toList();
            }
            return Ralationship(
              id: layer['id'],
              description: layer['description'] ?? '',
              layerId: layer['layerId'] ?? '',
              type: layer['type'] ?? '',
              points: points,
              polylineAnnotation: null,
              updatedAt: layer['updatedAt'] ?? '',
              isDelete: layer['isDelete'],
              // userId: user?.uid
            );
          }).toList();

          print("--------final relationships-----------");
          print(toRelationships);
          print("--------final relationships-----------");

          setState(() {
            _relationships = toRelationships;
            _isLoading = false;
          });
        } else {
          setState(() {
            _relationships = [];
            _errorMessage = response.statusCode == 404
                ? 'No relationships found.'
                : 'Failed to fetch relationships.';
            _isLoading = false;
          });
          //  List<dynamic> data = jsonDecode(response.body);
          // hiveService.resetRelationshipBox();
          final List<Map<String, dynamic>> cachedRelationships =
              await hiveService.getRelationships(projectId, user?.uid);

          print("----------cachedRelationships-----------");
          print(cachedRelationships);
          print("----------cachedRelationships)----------");

          Map<String, dynamic> mergedLayers = {};

          for (var relationship in [...cachedRelationships]) {
            String id = relationship['id'];
            if (mergedLayers.containsKey(id)) {
              if (DateTime.parse(relationship['updatedAt'])
                  .isAfter(DateTime.parse(mergedLayers[id]['updatedAt']))) {
                mergedLayers[id] = relationship;
              }
            } else {
              mergedLayers[id] = relationship;
            }
          }

          List<dynamic> syncedLayers = mergedLayers.values
              .where((layer) => layer['isDelete'] == false)
              .where((layer) => layers.any((storedLayer) => storedLayer['id'] == layer['layerId']))
              .toList();

          print("----------syncedLayers Relationships-----------");
          print(syncedLayers);
          print("----------syncedLayers Relationships-----------");

          for (var relationship in syncedLayers) {
            print("--------before save---------------");
            print(relationship);
            print("--------before save---------------");
            syncRelationships(
              layerId: relationship['layerId'].toString(),
              id: relationship['id'].toString(),
              points: (relationship['points'] as List)
                  .map<List<double>>((point) => List<double>.from(point))
                  .toList(),
              type: relationship['type'].toString(),
              projectId: relationship['projectId'].toString(),
              description: relationship['description'].toString(),
              userId: user?.uid,
            );
            print('createRelationship Database');
            await hiveService.putRelationship(relationship['id'], relationship);
            print('Relationship with id ${relationship['id']} has been saved.');
          }
          print("-------------sync done------------");

          List<Ralationship> toRelationships = syncedLayers
              .where((layer) => layers.any((storedLayer) =>
                  storedLayer['id'] ==
                  layer['layerId']))
              .map((layer) {
            List<Position> points = [];

            if (layer['points'] != null) {
              points = (layer['points'] as List)
                  .map((point) => Position(point[0], point[1]))
                  .toList();
            }
            return Ralationship(
              id: layer['id'],
              description: layer['description'] ?? '',
              layerId: layer['layerId'] ?? '',
              type: layer['type'] ?? '',
              points: points,
              polylineAnnotation: null,
              updatedAt: layer['updatedAt'] ?? '',
              isDelete: layer['isDelete'],
              // userId: user?.uid
            );
          }).toList();

          print("--------final relationships-----------");
          print(toRelationships);
          print("--------final relationships-----------");

          setState(() {
            _relationships = toRelationships;
            _isLoading = false;
          });
        }
      } else {
        final List<Map<String, dynamic>> cachedRelationships =
            await hiveService.getRelationships(projectId, user?.uid);

        List<Ralationship> relationships = cachedRelationships.map((item) {
          print(
            item['id'],
          );
          print(
            item['layerId'],
          );
          print(item['description']);
          print(item['type']);
          print((item['points'] as List<dynamic>)
              .map((coord) => Position(coord[0], coord[1]))
              .toList());
          return Ralationship(
            id: item['id'],
            layerId: item['layerId'],
            description: item['description'] ?? '',
            type: item['type'] ?? '',
            points: (item['points'] as List<dynamic>)
                .map((coord) => Position(coord[0], coord[1]))
                .toList(),

            polylineAnnotation: null,
            updatedAt: item['updatedAt'],
            // userId: user?.uid
          );
        }).toList();

        setState(() {
          _relationships = relationships;
          print(_relationships);
          // _isLoading = false;
        });
        print("offline relationship------------");
        print(_relationships);
        print("offline relationship------------");
      }

      // ดึงข้อมูลจาก API ถ้าไม่มีข้อมูลใน Hive
    } catch (error) {
      setState(() {
        _relationships = [];
        _errorMessage = 'Error: ${error.toString()}';
        _isLoading = false;
        print(_errorMessage);
      });
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Unknown';
    }
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy')
          .format(dateTime); 
    } catch (e) {
      return 'Unknown';
    }
  }

  List<Position> convertToPositions(List<Map<String, num>> coordinates) {
    // print(coordinates);
    return coordinates.map((coord) {
      return Position(
        coord['lng']!.toDouble(),
        coord['lat']!.toDouble(),
      );
    }).toList();
  }

  Future<void> shareLayer(Map<String, dynamic> project, dynamic layer) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;
      final response = await http.post(
        postLayerBaseUrl(user.uid),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'projectId': project['_id'],
          'layer': layer,
          'userId': user.uid,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Layer shared successfully!');

     
        final projectUsers = project['userIds']
            as List;
        List<String> sharedWith = List<String>.from(layer['sharedWith'] ?? []);

       
        for (var projectUser in projectUsers) {
          if (projectUser.toLowerCase() != user.email?.toLowerCase() &&
              !sharedWith.contains(projectUser)) {
            sharedWith.add(projectUser);
          }
        }
        setState(() {
          layer['sharedWith'] = sharedWith;
        });
        print('Layer shared with updated sharedWith list: $sharedWith');
      } else {
        print('Failed to share layer: ${response.body}');
      }
    } catch (e) {
      print('Error sharing layer: $e');
    }
  }

  Map<String, dynamic> locationMetaData = {};
  Future<List<Location>> convertNoteDataToLocations(
      Map<String, dynamic> noteData) async {
    print("convertNoteDataToLocations");
    print(noteData);
    if (noteData['items'] == null) {
      return [];
    }

    List<Location> locations = [];
    List<Attachment> globalAttachments = [];

    if (noteData['attachments'] != null && noteData['attachments'] is List) {
      // ใช้ Future.wait เพื่อรอให้ทุกคำขอเสร็จสิ้น
      globalAttachments = await Future.wait(
        (noteData['attachments'] as List).map((attachment) async {
          return Attachment(
              name: attachment['name'] as String,
              type: attachment['type'] as String,
              size: attachment['size'] as int,
              lastModified: attachment['lastModified'] as int,
              url: attachment['url'] as String,
              offlineurl: attachment['offlineurl'] as String);
        }),
      );
    }

    for (var item in noteData['items']) {
      double lat = item['latitude']?.toDouble() ?? 0.0;
      double lng = item['longitude']?.toDouble() ?? 0.0;
      String note = item['note'] ?? ''; 
      String type = item['type'] ?? 'position';
      String id = item['id'] ?? '';

      List<Attachment> itemAttachments = [];
      if (item['attachments'] != null && item['attachments'] is List) {
        itemAttachments = (item['attachments'] as List<dynamic>)
            .map((attachment) => Attachment(
                  name: attachment['name'] as String,
                  type: attachment['type'] as String,
                  size: attachment['size'] as int,
                  lastModified: attachment['lastModified'] as int,
                  url: attachment['url'] as String,
                  offlineurl: attachment['offlineurl'] as String,
                ))
            .toList();
      }

      Location location = Location(
        id: id,
        lat: lat,
        lng: lng,
        note: note,
        images: itemAttachments,
        type: type,
      );

      locations.add(location);
    }

    String mainNote = noteData['note'] ?? '';
    bool visible = noteData['visible'] ?? true;

    setState(() {
      locationMetaData = {
        'mainNote': mainNote,
        'visible': visible,
        'attachments': globalAttachments,
      };
    });
    print('-----------locationMetaData-----------');
    print(locationMetaData);
    print('-----------locationMetaData-----------');
    print('-----------locationMetaData-----------');
    print(locations);
    print('-----------locationMetaData-----------');
    return locations;
  }

  Future<void> _fetchBuildings(List<dynamic> layersData) async {
    try {
      bool isOnline = await _checkOfflineStatus();
      print('Is online: $isOnline');
      buildingsData.clear();

      final user = FirebaseAuth.instance.currentUser;
      final hiveService = HiveService();

      // hiveService.resetBuildingBox();

      for (var layer in layersData) {
        final layerId = layer['id']; 

        if (layerId != null && layerId.startsWith('layer-form-')) {
          List<Answer> answersList = [];

          if (isOnline) {
     
            final url = getBuildingAnswerBaseUrl(layerId, user?.uid);
            final response = await http.get(url);

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final List<Map<String, dynamic>> buildingAnswers =
                  List<Map<String, dynamic>>.from(data);

              final offlineData = await hiveService.getBuildingAnswers(
                  layerId, user?.uid ?? '');

              print("---------getBuildingAnswerBaseUrl----------");
              print(buildingAnswers.length);
              print(buildingAnswers);
              print(offlineData.length);
              print(offlineData);
              print("---------getBuildingAnswerBaseUrl----------");

              Map<String, dynamic> mergedLayers = {};

              for (var answer in [...offlineData, ...buildingAnswers]) {
                String id = answer['_id'];
                print(answer['_id']);
                if (mergedLayers.containsKey(id)) {
                  if (DateTime.parse(answer['lastModified']).isAfter(
                      DateTime.parse(mergedLayers[id]['lastModified']))) {
                    mergedLayers[id] = answer;
                    print(answer);
                  }
                } else {
                  mergedLayers[id] = answer;
                  print(answer);
                }
              }
              print(mergedLayers);
              List<dynamic> syncedLayers = mergedLayers.values.toList();

              print("----------syncedLayers answer-----------");
              print(syncedLayers.length);
              print(syncedLayers);
              print("----------syncedLayers answer-----------");

              List<Map<String, dynamic>> answers = syncedLayers.map((layer) {
                return {
                  'id': layer['_id'],
                  'layerId': layer['layerId'],
                  'answers': {
                    for (var key in layer['answers'].keys)
                      key.toString(): layer['answers'][key]?.toString() ?? ''
                  },
                  'color': layer['color'],
                  'lastModified': DateTime.now().toUtc().toIso8601String(),
                  'coordinates': layer['coordinates'],
                  'buildingId': layer['buildingId'],
                  'projectId': layer['projectId'],
                  'userId': layer['userId'],
                  'isDelete': layer['isDelete'],
                };
              }).toList();

              await syncBuildingAnswers(
                  layerId: layerId, buildingAnswers: answers);

              final url = getBuildingAnswerBaseUrl(layerId, user?.uid);
              final responses = await http.get(url);

              if (responses.statusCode == 200) {
                print(responses.statusCode);
                print(responses.body);
                final synced = jsonDecode(responses.body);
                final List<Map<String, dynamic>> syncAnswers =
                    List<Map<String, dynamic>>.from(synced);

                print(syncAnswers.length);

                List<Map<String, dynamic>> toHive = syncAnswers.map((layer) {
                  return {
                    '_id': layer['_id'],
                    'layerId': layer['layerId'],
                    'answers': layer[
                        'answers'], 
                    'color': layer['color'],
                    'lastModified': DateTime.now().toUtc().toIso8601String(),
                    'coordinates': layer['coordinates'],
                    'buildingId': layer['buildingId'],
                    'projectId': layer['projectId'],
                    'userId': layer['userId'],
                    'isDelete': layer['isDelete'],
                  };
                }).toList();

                await hiveService.deleteBuildingAnswers(layerId, user?.uid);
                await hiveService.saveBuildingAnswers(
                    layerId, user?.uid, toHive);

                List<Map<String, dynamic>> process = toHive.map((layer) {
                  return {
                    '_id': layer['_id'],
                    'layerId': layerId, 
                    'answers': layer['answers'] ??
                        {},
                    'color': layer['color'],
                    'lastModified': layer['lastModified'],
                    'coordinates':
                        layer['coordinates'][0] ?? [],
                    'buildingId': layer['buildingId'],
                    'projectId': layer['projectId'],
                    'userId': layer['userId'],
                    'isDelete': layer['isDelete'],
                  };
                }).toList();

                answersList = _processBuildingAnswers(process, layerId);
              }
              final List<Map<String, dynamic>> selectedAnswers =
                  answersList.map((answer) {
                return {
                  'layerId': answer.layerId,
                  'buildingId': answer.buildingId,
                  'answers': answer.answers,
                  'color': answer.color,
                  'lastModified': answer.lastModified,
                  'coordinates': answer.coordinates
                      .map((position) => position.toJson())
                      .toList(),
                };
              }).toList();
            } else if (response.statusCode == 404) {


             
              final offlineData = await hiveService.getBuildingAnswers(
                  layerId, user?.uid ?? '');

              print("---------getBuildingAnswerBaseUrl----------");

              print(offlineData.length);
              print(offlineData);
              print("---------getBuildingAnswerBaseUrl----------");

              Map<String, dynamic> mergedLayers = {};

              for (var answer in [...offlineData]) {
                String id = answer['_id'];
                print(answer['_id']);
                if (mergedLayers.containsKey(id)) {
                  if (DateTime.parse(answer['lastModified']).isAfter(
                      DateTime.parse(mergedLayers[id]['lastModified']))) {
                    mergedLayers[id] = answer;
                    print(answer);
                  }
                } else {
                  mergedLayers[id] = answer;
                  print(answer);
                }
              }
              print(mergedLayers);
              List<dynamic> syncedLayers = mergedLayers.values.toList();

              print("----------syncedLayers answer-----------");
              print(syncedLayers.length);
              print(syncedLayers);
              print("----------syncedLayers answer-----------");

              List<Map<String, dynamic>> answers = syncedLayers.map((layer) {
                return {
                  'id': layer['_id'],
                  'layerId': layer['layerId'],
                  'answers': {
                    for (var key in layer['answers'].keys)
                      key.toString(): layer['answers'][key]?.toString() ?? ''
                  },
                  'color': layer['color'],
                  'lastModified': DateTime.now().toUtc().toIso8601String(),
                  'coordinates': layer['coordinates'],
                  'buildingId': layer['buildingId'],
                  'projectId': layer['projectId'],
                  'userId': layer['userId'],
                  'isDelete': layer['isDelete'],
                };
              }).toList();

              await syncBuildingAnswers(
                  layerId: layerId, buildingAnswers: answers);

              final url = getBuildingAnswerBaseUrl(layerId, user?.uid);
              final responses = await http.get(url);

              if (responses.statusCode == 200) {
                print(responses.statusCode);
                print(responses.body);
                final synced = jsonDecode(responses.body);
                final List<Map<String, dynamic>> syncAnswers =
                    List<Map<String, dynamic>>.from(synced);

                print(syncAnswers.length);

                List<Map<String, dynamic>> toHive = syncAnswers.map((layer) {
                  // สมมุติว่าแต่ละ layer ใน syncedLayers มีฟิลด์ที่เกี่ยวข้องกับ building answers
                  return {
                    '_id': layer['_id'],
                    'layerId': layer['layerId'],
                    'answers': layer[
                        'answers'], // Ensure answers is a valid serializable object
                    'color': layer['color'],
                    'lastModified': DateTime.now().toUtc().toIso8601String(),
                    'coordinates': layer['coordinates'],
                    'buildingId': layer['buildingId'],
                    'projectId': layer['projectId'],
                    'userId': layer['userId'],
                    'isDelete': layer['isDelete'],
                  };
                }).toList();

                await hiveService.deleteBuildingAnswers(layerId, user?.uid);
                await hiveService.saveBuildingAnswers(
                    layerId, user?.uid, toHive);

                List<Map<String, dynamic>> process = toHive.map((layer) {
                  return {
                    '_id': layer['_id'],
                    'layerId': layerId,
                    'answers': layer['answers'] ??
                        {}, 
                    'color': layer['color'],
                    'lastModified': layer['lastModified'],
                    'coordinates':
                        layer['coordinates'][0] ?? [],
                    'buildingId': layer['buildingId'],
                    'projectId': layer['projectId'],
                    'userId': layer['userId'],
                    'isDelete': layer['isDelete'],
                  };
                }).toList();

                answersList = _processBuildingAnswers(process, layerId);
              }
              final List<Map<String, dynamic>> selectedAnswers =
                  answersList.map((answer) {
                return {
                  'layerId': answer.layerId,
                  'buildingId': answer.buildingId,
                  'answers': answer.answers,
                  'color': answer.color,
                  'lastModified': answer.lastModified,
                  'coordinates': answer.coordinates
                      .map((position) => position.toJson())
                      .toList(),
                };
              }).toList();
              
              

              
            } else {
              print(
                  'Error fetching data for layerId: $layerId, Status Code: ${response.statusCode}');
            }
          } else {
          
            final hiveService = HiveService();
            final offlineData =
                await hiveService.getBuildingAnswers(layerId, user?.uid ?? '');
            print("---------offline----------");
            print(offlineData.length);
            print(offlineData);
            print("---------offline----------");

            Map<String, dynamic> mergedLayers = {};

            for (var answer in [...offlineData]) {
              print(answer);
              String id = answer['_id'];

              if (mergedLayers.containsKey(id)) {
                if (DateTime.parse(answer['lastModified']).isAfter(
                    DateTime.parse(mergedLayers[id]['lastModified']))) {
                  mergedLayers[id] = answer;
                  print(answer);
                }
              } else {
                mergedLayers[id] = answer;
                print(answer);
              }
            }
            print(mergedLayers);
            List<dynamic> syncedLayers = mergedLayers.values.toList();
            List<Map<String, dynamic>> answers = syncedLayers.map((layer) {
              return {
                '_id': layer['_id'],
                'layerId': layerId,
                'answers':
                    layer['answers'] ?? {}, 
                'color': layer['color'], 
                'lastModified': layer['lastModified'],
                'coordinates':
                    layer['coordinates'][0] ?? [], 
                'buildingId': layer['buildingId'],
                'projectId': layer['projectId'],
                'userId': layer['userId'],
                'isDelete': layer['isDelete'],
              };
            }).toList();

            if (answers.isNotEmpty) {
              print('Fetched offline data for layerId: $layerId');
              print(answers.length);
              answersList = _processBuildingAnswers(answers, layerId);
              print(answersList);
            } else {
              print('No offline data found for layerId: $layerId');
            }
          }

          setState(() {
            buildingsData.add({
              'layerId': layerId,
              'data': answersList,
            });
          });
        }
      }
    } catch (e) {
      print('Error fetching buildings data: $e');
    }
  }

  String generateSymbolLayerId() {
    final random = Random();

    final numericId = List.generate(
            8,
            (index) =>
                random.nextInt(10).toString()) 
        .join();

    return numericId;
  }

  List<Answer> _processBuildingAnswers(List<dynamic> data, String layerId) {
    List<Answer> answersList = [];
    print(data);

    for (var item in data) {
      print(item['buildingId'].toString());
      print(item['color']);
      print(item['lastModified']);
      print(item['answers']);
      print(item['coordinates']);

      String buildingId = item['buildingId'].toString();
      String answerId = item['_id'].toString();
      String? color = item['color'];
      String? lastModified = item['lastModified'];
      Map<int, String> answers = {};

      if (item['answers'] != null) {
        answers = {
          for (var key in item['answers'].keys)
            int.tryParse(key.toString()) ?? 0:
                item['answers'][key]?.toString() ?? ''
        };
      }

      if (item['questions'] != null) {
        for (var question in item['questions']) {
          answers[question['id']] = '';
        }
      }

      if (item['coordinates'].isNotEmpty) {
        print(layerId);
        print(buildingId);
        print(answers);
        print(color);
        print(lastModified);

        answersList.add(Answer(
          id: answerId,
          layerId: layerId,
          buildingId: buildingId,
          answers: answers,
          color: color,
          coordinates: item['coordinates'].map<Position>((coordinate) {
            return Position(coordinate[0] as double, coordinate[1] as double);
          }).toList(),
          lastModified: lastModified,
        ));
      }
    }

    return answersList;
  }

  void _showProjectModal(
      BuildContext context, Map<String, dynamic> project) async {
    final String projectId = project['_id'];

    // print(project);
    // final layersData = layersByProject.firstWhere(
    //   (item) => item['projectId'] == projectId,
    //   orElse: () => {'layers': []}, // กรณีไม่พบ projectId ที่ตรงกัน
    // );

    // print(layersByProject);
    // print(layersData);

    String colorToHex(Color color) {
      return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    }

    // final List<dynamic> layers = layersData['layers'] ?? [];
    // print("layers");
    // print("layers");
    bool isOnline = await _checkOfflineStatus();
    // print("layers");
    // print("layers");
    // print("layers");
    print(layers);
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
          widthFactor: 1,
          heightFactor: 0.8, 
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
                Text(
                  project['projectName'] ?? 'Unnamed Project',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('แก้ไขล่าสุด: ${formatDate(project['lastUpdate'])}'),
                const SizedBox(height: 16),
            
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton(
                    onPressed: () async {
                      await fetchRelationships(projectId);
                      final noteData = await fetchNotes(projectId);
                      List<Location> locations =
                          await convertNoteDataToLocations(noteData);
                      await _fetchBuildings(layers);

                      User? user = FirebaseAuth.instance.currentUser;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectMapPage(
                              id: projectId,
                              userId: user?.uid,
                              project: project,
                              layers: layers,
                              buildingsData: buildingsData,
                              relationships: _relationships,
                              locations: locations,
                              note: locationMetaData),
                        ),
                      ).then((_) {
                      
                        setState(() {
                          Navigator.of(context).pop();
                        });
                      });
                    },

              

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF699BF7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'เปิดโครงการ',
                      style: GoogleFonts.sarabun(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600, 
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProjectPage(
                            project: project,
                            layers: layers,
                          ),
                        ),
                      );

                      if (result == true) {
                        fetchProjectsAndLayers(); 
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 236, 236, 236), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0, 
                    ),
                    child: Text(
                      'แก้ไขโครงการ',
                      style: GoogleFonts.sarabun(
                        color: const Color(0xFF699BF7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text('เลเยอร์'),
             
                Expanded(
                  child: layers.isNotEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius:
                                BorderRadius.circular(16.0),
                          ),
                          child: ListView.builder(
                            itemCount: layers.length,
                            itemBuilder: (context, index) {
                              final layer = layers[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16.0),
                                  ),
                                  child: ListTile(
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.publish_rounded, 
                                        color: isOnline
                                            ? Colors.blue
                                            : Colors.grey, 
                                        size: 24,
                                      ),
                                      onPressed: () {
                                       
                                        List<Map<String, dynamic>>
                                            filteredMarkers = layer["markers"]
                                                .map<Map<String, dynamic>>(
                                                    (marker) {
                                        
                                          String iconName = marker["iconName"];
                                          RegExp regExp =
                                              RegExp(r'\/([^\/]+)-');
                                          Match? match =
                                              regExp.firstMatch(iconName);
                                          String iconNameSubstring =
                                              match != null
                                                  ? match.group(1) ?? ''
                                                  : '';

                                          return {
                                            "lat": marker["lat"],
                                            "lng": marker["lng"],
                                            "name": marker["name"],
                                            "description":
                                                marker["description"],
                                            "color": marker["color"],
                                            "iconName":
                                                iconNameSubstring,
                                            "imageUrls": marker["imageUrls"],
                                          };
                                        }).toList();

                                        print(layer["paths"]);

                                        List<Map<String, dynamic>>
                                            filteredPaths = layer["paths"]
                                                .map<Map<String, dynamic>>(
                                                    (path) {
                                          print(path);
                                          List<Map<String, double>>
                                              transformedPoints =
                                              (path.points as List<Position>)
                                                  .map((point) {
                                            return {
                                              'lat': point.lat.toDouble(),
                                              'lng': point.lng.toDouble(),
                                            };
                                          }).toList();

                                          return {
                                            "id": path.id,
                                            "points":
                                                transformedPoints,
                                            "color": colorToHex(path.color),
                                            "thickness": path.thickness,
                                            "name": path.name,
                                            "description": path.description,
                                          };
                                        }).toList();

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
                                          "userId": layer["userId"],
                                          "sharedWith": layer["sharedWith"],
                                          "projectId": layer["projectId"],
                                        };
                                        shareLayer(project, layerData);
                                        print(
                                            'Share button pressed for layer: ${layer['title']}');
                                     
                                      },
                                    ),
                                    title: Text(
                                      layer['title'] ?? 'Unnamed Layer',
                                      style: GoogleFonts.sarabun(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    subtitle: Text(
                                      layer['sharedWith'] == null ||
                                              layer['sharedWith'].isEmpty
                                          ? 'ยังไม่แชร์'
                                          : 'แชร์แล้ว',
                                      style: GoogleFonts.sarabun(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    leading: layer['id'] != null
                                        ? layer['id']
                                                .startsWith('layer-symbol-')
                                            ? Container(
                                                width:
                                                    40, 
                                                height:
                                                    40,
                                                decoration: const BoxDecoration(
                                                  color: Colors
                                                      .blue, 
                                                  shape: BoxShape
                                                      .circle, 
                                                ),
                                                child: const Icon(
                                                  Icons
                                                      .house_rounded, 
                                                  size: 20, 
                                                  color: Colors
                                                      .white, 
                                                ),
                                              )
                                            : layer['id']
                                                    .startsWith('layer-form-')
                                                ? Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.green,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .messenger_rounded, 
                                                      size: 20,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : layer['id'].startsWith(
                                                        'layer-relationship-')
                                                    ? Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.orange,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .people_alt_rounded, 
                                                          size: 20,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : layer['imageUrl'] != null
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            child:
                                                                Image.network(
                                                              layer['imageUrl'],
                                                              width: 40,
                                                              height: 40,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                        : null
                                        : null,
                                    onTap: () {
                                      print(
                                          'Tapped on layer: ${layer['title']}');
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Text(
                            'ไม่มีเลเยอร์ในโปรเจกต์นี้',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'โครงการ',
            style: GoogleFonts.sarabun(
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.lightBlue.shade700,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle_sharp,
                  size: 30, color: Colors.grey),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment:
                    MainAxisAlignment.end, 
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: Colors.lightBlue.shade800,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateprojectmobileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: projects.map((project) {
                    return Column(
                      children: [
                        ProjectCard(
                          projectName:
                              project['projectName'] ?? 'Unnamed Project',
                          lastUpdate: formatDate(project['lastUpdate']),
                          onTap: () async {
                            await fetchLayers(project['_id']);
                            _showProjectModal(context, project);
                          },
                        ),
                        const SizedBox(
                            height: 8), 
                      ],
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        )));
  }
}
