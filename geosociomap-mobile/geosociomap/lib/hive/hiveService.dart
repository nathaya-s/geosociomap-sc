import 'package:hive/hive.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class HiveService {
  late Box projectBox;
  late Box layerBox;
  late Box userBox;
  late Box noteBox;
  late Box relationshipBox;
  late Box buildingAnswersBox;

  Future<void> initHive() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    projectBox = await Hive.openBox('projects');
    layerBox = await Hive.openBox('layers');
    userBox = await Hive.openBox('users');
    noteBox = await Hive.openBox('notes');
    relationshipBox = await Hive.openBox('relationships');
    buildingAnswersBox = await Hive.openBox('buildingAnswers');
  }

  Future<void> saveProject(
    String projectId,
    Map<String, dynamic> projectData,
    String? userId,
  ) async {
    final box = await Hive.openBox('projects');

    final modifiedProjectData = {
      ...projectData, 
      'lastUpdate': DateTime.now().toUtc().toIso8601String(), 
      'isSync': false, 
      'userId': userId, 
    };

  
    await box.put(projectId, modifiedProjectData);

    // print('Project with ID $projectId has been saved to Hive.');
  }

//  Future<void> saveProject(
//     String projectId, Map<String, dynamic> projectData, String? userId) async {
//   try {
//     
//     print(projectId);
//     final box = await Hive.openBox('projects');

//     print("saveProject called with projectId: $projectId");

//   
//     final existingProjectData = box.get(projectId);
//     print("Project exists: ${existingProjectData != null}");

//     if (existingProjectData != null) {
//     
//       await box.put(projectId, projectData);
//       print('Project data updated in Hive with ID: $projectId');
//     } else {
//     
//       final projectName = projectData['projectName'] ?? 'Unnamed Project';
//       final selectedPoints = (projectData['selectedPoints'] as List<dynamic>)
//           .map((point) => Position(point['lat'], point['lng']))
//           .toList();

//       if (userId == null) {
//         throw Exception("UserId is required to create a new project.");
//       }

//     
//       await createProject(projectName, userId, selectedPoints);
//       print('Project does not exist, created a new project');
//     }
//   } catch (e) {
//     print('Error in saveProject: $e');
//   }
// }

  Future<void> createProject(
    String projectName,
    String? userId,
    List<Position> selectedPoints,
  ) async {
    try {
     
      if (projectName.isEmpty || selectedPoints.isEmpty) {
        throw Exception("Invalid input");
      }
     
      final projectData = {
        '_id': uuid.v4(),
        'projectName': projectName,
        'userIds': [userId],
        'selectedPoints': selectedPoints
            .map((point) => {'lat': point.lat, 'lng': point.lng})
            .toList(),
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

    
      final modifiedProjectData = {
        ...projectData,
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
        'isSync': false,
      };

      final projectBox = await Hive.openBox('projects');
      await projectBox.add(modifiedProjectData);
      // print('Project created and saved to Hive with ID: $projectBox');

     

      // print('Notes for the project saved to Hive successfully');
    } catch (e) {
      // print('Error creating project and notes: $e');
    }
  }

  Future<void> saveLayers(List<dynamic> layers) async {
    await layerBox.put('layers', layers);
  }

  Future<List<Map<String, dynamic>>> getProjects(String? userId) async {
 
    final box = await Hive.openBox('projects');

   
    final allProjects = box.values.map((project) {
      return Map<String, dynamic>.from(project as Map);
    }).toList();

  
    final filteredProjects = allProjects.where((project) {
     
      return project['userId'] == userId;
    }).toList();

    return filteredProjects;
  }

  Future<void> saveUser(String userId, Map<String, dynamic> userData) async {
    await userBox.put(userId, userData);
  }

  Map<String, List<dynamic>> getLayers(String? userId) {
    final allKeys = layerBox.keys;
    final groupedLayers = <String, List<dynamic>>{};

    for (var key in allKeys) {
      groupedLayers[key] = List<dynamic>.from(layerBox
          .get(key, defaultValue: []).map(
              (layer) => Map<String, dynamic>.from(layer as Map)));
    }

    // print("groupedLayers");
    // print(groupedLayers);
    return groupedLayers;
  }

  Future<List<dynamic>> getLayerProject(String? projectId) async {
    final layerBox = await Hive.openBox('layers');

    // print("layerBox.keys: ${layerBox.get(projectId)}");
    var layerData = layerBox.get(projectId, defaultValue: []);
    if (layerData != null) {
      return layerData;
    }
    return [];
  }

  Future<void> putLayerProject(
      String? projectId, List<dynamic> layerData) async {
    final layerBox =
        await Hive.openBox('layers'); 

  
    await layerBox.put(projectId, layerData);
    print("Data saved for projectId: $projectId");
  }

  Future<Map<String, dynamic>?> getNote(String projectId) async {
    try {
  
      final noteBox = await Hive.openBox('notes');

   
      final note = noteBox.get(projectId);

      if (note != null) {
        return note; 
      } else {
        print("No note found for projectId: $projectId");
        return null;
      }
    } catch (e) {
      print('Error retrieving note from Hive: $e');
      return null; 
    }
  }

  Future<void> putLayer(String? projectId, String layerId,
      Map<String, dynamic> updatedLayer) async {
    try {
      print(projectId);
      print(layerId);
      print(updatedLayer);
      final layerBox = await Hive.openBox('layers');
      final existingLayers = List<Map<String, dynamic>>.from(layerBox
          .get(projectId, defaultValue: []).map(
              (layer) => Map<String, dynamic>.from(layer as Map)));

      bool layerUpdated = false;
      for (int i = 0; i < existingLayers.length; i++) {
        if (existingLayers[i]['id'] == layerId) {
          existingLayers[i] = {
            ...existingLayers[i],
            ...updatedLayer,
            'lastUpdate':
                DateTime.now().toUtc().toIso8601String(), 
            'isSync': false,
          };
          layerUpdated = true;
          break;
        }
      }

      if (layerUpdated) {
        await layerBox.put(projectId, existingLayers);
        // print('Layer updated successfully for projectId: $projectId');
      } else {
        // print('Layer not found for the given layerId: $layerId');
      }
    } catch (e) {
      // print('Error updating layer in Hive: $e');
    }
  }

  Future<void> addLayer(String? projectId, Map<String, dynamic> layer) async {
    try {
      final layerBox = await Hive.openBox('layers');
      final existingLayers = List<Map<String, dynamic>>.from(layerBox
          .get(projectId, defaultValue: []).map(
              (layer) => Map<String, dynamic>.from(layer as Map)));
      for (var layer in existingLayers) {
        if (layer.containsKey('markers')) {
          var markers = layer['markers'];
          for (var marker in markers) {
            if (marker.containsKey('pointAnnotation')) {
              marker.remove('pointAnnotation');
            }
          }
        }

        //  if (layer.containsKey('paths')) {
        //   var markers = layer['paths'];
        //   for (var marker in markers) {
        //     if (marker.containsKey('polylineAnnotation')) {
        //       marker.remove('polylineAnnotation');
        //     }
        //   }
        // }
      }
      print('Error adding layer to Hive: 3');
      for (var layer in existingLayers) {
        print(layer);
      }

      final layerWithProjectId = {
        ...layer,
        'projectId': projectId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'lastUpdate': DateTime.now().toUtc().toIso8601String(),
        'isSync': false,
      };
      existingLayers.add(layerWithProjectId);
      await layerBox.put(projectId, existingLayers);
      print('Layer added successfully to projectId: $projectId');
    } catch (e) {
      print('Error adding layer to Hive: $e');
    }
  }

  Future<void> putRelationship(
      String relationshipId, Map<String, dynamic> relationship) async {
    final box = await Hive.openBox('relationships');
    await box.put(relationshipId, relationship);
    print('put : $relationship and buildingId: ${box.values}');
  }

  Future<List<Map<String, dynamic>>> getRelationships(
      String projectId, String? userId) async {
    print("getRelationships");
    print("Project ID: $projectId");
    print("User ID: $userId");

    final box = await Hive.openBox('relationships');

    final relationships = box.values
        .where((relationship) =>
            relationship['projectId'] == projectId &&
            relationship['userId'] == userId)
        .toList();
    final transformedRelationships =
        relationships.map((item) => Map<String, dynamic>.from(item)).toList();

    print("Transformed relationships:");
    print(transformedRelationships);

    return transformedRelationships;
  }

  Future<void> removeRelationship(String relationshipId) async {
    final box = await Hive.openBox('relationships');
    final keyToDelete = box.keys.firstWhere(
      (key) {
        final relationship = box.get(key);
        return relationship['id'] == relationshipId;
      },
      orElse: () => null,
    );

    if (keyToDelete != null) {
      await box.delete(keyToDelete);
      print('Deleted relationship with id: $relationshipId');
    } else {
      print('No relationship found with id: $relationshipId');
    }
  }

  Future<void> deleteLayer(String? projectid, String layerId) async {
    final layerBox = await Hive.openBox('layers');

    String projectId = projectid!;
    String layerIdToDelete = layerId;

    List<dynamic> layers = layerBox
        .get(projectId, defaultValue: [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (layers.isNotEmpty) {
      final layerToDelete = layers.firstWhere(
        (layer) => layer['id'] == layerIdToDelete,
        orElse: () => null,
      );

      if (layerToDelete != null) {
        layers.remove(layerToDelete);

        await layerBox.put(projectId, layers);
        print("Layer with layerId: $layerIdToDelete deleted.");
      } else {
        print("No layer found with layerId: $layerIdToDelete.");
      }
    } else {
      print("No layers found for projectId: $projectId.");
    }
  }

  Future<List<Map<String, dynamic>>> getBuildingAnswers(
      String layerId, String userId) async {
    try {
      final box = await Hive.openBox('buildingAnswers');
      final String key = '$layerId-$userId';

      final List<dynamic> data = box.get(key, defaultValue: []);
      final List<Map<String, dynamic>> answers = data
          .map((item) =>
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
          .toList();

      return answers;
    } catch (e) {
      print('Error fetching building answers: $e');
      return []; 
    }
  }

  Future<void> deleteBuildingAnswers(String layerId, String? userId) async {
    try {
      final box = await Hive.openBox('buildingAnswers');

      print("deleteBuildingAnswers");

      final key = '$layerId-$userId';

      if (box.containsKey(key)) {
        await box.delete(key);
        print('Data deleted for layerId: $layerId and userId: $userId');
      } else {
        print('No data found for the given key');
      }
    } catch (e) {
      print('Error deleting building answers: $e');
    }
  }

  Future<void> saveBuildingAnswers(String layerId, String? userId,
      List<Map<String, dynamic>> answers) async {
    try {
      final box = await Hive.openBox('buildingAnswers');

      print("saveBuildingAnswers");
      print(answers);

      final key = '$layerId-$userId';
      await box.put(key, answers);

      print('Data saved for layerId: $layerId and userId: $userId');
    } catch (e) {
      print('Error saving building answers: $e');
    }
  }

  Future<void> putNote(String? projectId, Map<String, dynamic> note) async {
    try {
      final noteBox = await Hive.openBox('notes');
      await noteBox.put(projectId, note);
    } catch (e) {
      print('Error adding or updating note in Hive: $e');
    }
  }

  Map<String, dynamic>? getUserById(String? userId) {
    return userBox.get(userId);
  }

  Future<void> resetProjectBox() async {
    final projectBox = await Hive.openBox('projects');
    await projectBox.clear();
    print('Project box has been reset.');
  }

  Future<void> resetNotesBox() async {
    final noteBox = await Hive.openBox('notes');
    await noteBox.clear(); 
    print('noteBox box has been reset.');
  }

  Future<void> resetLayersBox() async {
    final layerBox = await Hive.openBox('layers');
    await layerBox.clear();
    print('layerBox box has been reset.');
  }

  Future<void> resetRelationshipBox() async {
    final layerBox = await Hive.openBox('relationships');
    await layerBox.clear();
    print('relationshipbox has been reset.');
  }

  Future<void> resetBuildingBox() async {
    final layerBox = await Hive.openBox('buildingAnswers');
    await layerBox.clear();
    print('buildingAnswers has been reset.');
  }
}
