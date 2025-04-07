import 'dart:developer';

import 'dart:io';
// import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geosociomap/hive/hiveService.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:hive/hive.dart';

class MongoDatabase {
  static connect() async {
    var db = await Db.create(MONGO_URL);
    await db.open();
    inspect(db);
    var status = db.serverStatus();
    print(status);
    var collection = db.collection(COLLECTION_NAME);
    print(await collection.find().toList());
  }
}

class MongoDBService {
  late Db _db;
  late DbCollection _usersCollection;

  Future<void> connect() async {
    _db = await Db.create(MONGO_URL);
    await _db.open();
    inspect(_db);
    var status = _db.serverStatus();
    print(status);
    _usersCollection = _db.collection('users');
  }

  Future<void> insertData(String uid, String email) async {
    Uri getBaseUrl() {
      if (Platform.isAndroid) {
        return Uri.parse('https://geosociomap-backend.onrender.com/createUser');
      } else if (Platform.isIOS) {
        return Uri.parse('https://geosociomap-backend.onrender.com/createUser');
      } else {
        throw UnsupportedError('This platform is not supported');
      }
    }

    final url = getBaseUrl();
    print(uid);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uid': uid,
        'email': email.toLowerCase(),
      }),
    );

    if (response.statusCode == 200) {
      print('Data inserted successfully');
    } else {
      print('Failed to createUser: ${response.body}');
      throw Exception('Failed to createUser');
    }
  }

  Future<void> deleteUser(String uid) async {
    Uri getBaseUrl() {
      if (Platform.isAndroid) {
        return Uri.parse('https://geosociomap-backend.onrender.com/deleteUser');
      } else if (Platform.isIOS) {
        return Uri.parse('https://geosociomap-backend.onrender.com/deleteUser');
      } else {
        throw UnsupportedError('This platform is not supported');
      }
    }

    final url = getBaseUrl();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uid': uid,
      }),
    );

    if (response.statusCode == 200) {
      print('Data deleted successfully');
    } else {
      throw Exception('Failed to deleted data');
    }
  }

  Future<void> createProject(
      String projectName, List<Position> selectedPoints) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      throw Exception('User is not authenticated');
    }


    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
    
      try {
        Uri getBaseUrl() {
          if (Platform.isAndroid) {
            return Uri.parse('https://geosociomap-backend.onrender.com/create-project');
          } else if (Platform.isIOS) {
            return Uri.parse('https://geosociomap-backend.onrender.com/create-project');
          } else {
            throw UnsupportedError('This platform is not supported');
          }
        }

        final url = getBaseUrl();
        final points = selectedPoints
            .map((point) => {
                  'lat': point.lat,
                  'lng': point.lng,
                })
            .toList();
        final projectData = {
          'projectName': projectName,
          'userId': userId,
          'selectedPoints': points,
          'selectedEmails': [],
          'createdAt':  DateTime.now().toUtc().toIso8601String(), 
        };
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(projectData),
        );

        if (response.statusCode == 200) {
          print('Project created successfully');
       
          final Map<String, dynamic> responseData = json.decode(response.body);
          final projectData = responseData['projectData'];
          final modifiedProjectData = {
            ...projectData,
            'lastUpdate': DateTime.now().toUtc().toIso8601String(),
            'isSync': false, 
          };

          final projectBox = await Hive.openBox('projects');

          final projectId = await projectBox.add(modifiedProjectData);

          print('Project added to Hive with ID: $projectId');
          print('Modified Project Data: $modifiedProjectData');


          final noteData = responseData['noteData'];
          final modifiedNoteData = {
            ...noteData,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
            'isSync': false, 
          };

          final noteBox = await Hive.openBox('notes');

          final noteId = await noteBox.add(modifiedNoteData);

          print('Project added to Hive with ID: $projectId, and Note $noteId');
          print('Modified Project Data: $modifiedProjectData');
        } else {
          throw Exception('Failed to create project: ${response.body}');
        }
      } catch (error) {
        print('Error creating project: $error');
        _saveToHiveOffline(projectName, user?.uid, selectedPoints);
      }
    } else {
      _saveToHiveOffline(projectName, user?.uid, selectedPoints);
    }
  }

  void _saveToHiveOffline(
      String projectName, String? userId, List<Position> selectedPoints) {
    final hiveService = HiveService();
    hiveService.createProject(projectName, userId, selectedPoints);
    print('Project saved offline to Hive');
  }

  Future<void> closeConnection() async {
    await _db.close();
  }
}
