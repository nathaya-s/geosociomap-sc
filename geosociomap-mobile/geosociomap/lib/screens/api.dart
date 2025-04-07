import 'dart:convert';
import 'package:geosociomap/screens/url.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

Future<void> updateLayer(
    String layerId, String? userId, Map<String, dynamic> updatedLayer) async {
  try {
  
    print('Updating layer with userId: $userId');

    final response = await http.put(
      putLayerUrl(layerId),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        ...updatedLayer,
        'userId': userId,
        'sharedWith': [],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Layer updated successfully: ${data['message']}');
    } else if (response.statusCode == 404) {
      print('Layer not found or no changes detected: ${response.body}');
    } else {
      print('Failed to update layer: ${response.body}');
    }
  } catch (error) {
    print('Error updating layer: $error');
  }
}

Future<Map<String, dynamic>?> uploadImage(File image, Uri uploadUrl) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      uploadUrl,
    );

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final responseBody = jsonDecode(responseData.body);

      return responseBody;
    } else {
      print('Upload failed: ${response.reasonPhrase}');
      return null;
    }
  } catch (e) {
    print('Error uploading image: $e');
    return null;
  }
}

Future<void> saveLocationToDatabase(
    List<Map<String, dynamic>> items,
    String? projectId,
    String? userId,
    String? note,
    List<Map<String, dynamic>> attachment) async {
  print(projectId);
  print(attachment);
  try {
    final response = await http.put(
      putNoteUrl(projectId),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "projectId": projectId,
        "userId": userId,
        "items": items,
        "note": note,
        "attachments": attachment,
        "visible": true,
        "updatedAt": DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      print("Location saved successfully");
    } else {
      print("Failed to save location: ${response.statusCode}");
    }
  } catch (e) {
    print("Error saving location: $e");
  }
}

Future<void> createRelationship({
  required String layerId,
  required String id,
  required List<List<double>> points,
  String? userId,
  required String type,
  String? projectId,
  required String description,
  String? updatedAt,
}) async {
  final newRelationship = {
    'id': id,
    'layerId': layerId,
    'points': points,
    'userId': userId,
    'type': type,
    'projectId': projectId,
    'description': description,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
    'isDelete': false,
  };

  try {
    final response = await http.post(
      postRelationshipUrl(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(newRelationship),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print('Relationship added successfully: ${responseData['data']}');
    } else {
      final responseData = jsonDecode(response.body);
      print('Failed to add relationship: ${responseData['message']}');
    }
  } catch (error) {
    print('Error creating relationship: $error');
  }
}

Future<void> updateRelationship({
  required String id,
  String? userId,
  required String description,
  required String type,
}) async {
  print(userId);
  print(description);
  print(type);
 
  final Map<String, dynamic> requestBody = {
    'userId': userId,
    'description': description,
    'type': type,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
    'isDelete': false,
  };
  try {
    final response = await http.put(
      putRelationshipUrl(id),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Relationship updated successfully: ${responseData['message']}');
    } else if (response.statusCode == 404) {
      print('Error: Relationship not found or unauthorized');
    } else {
      final responseData = jsonDecode(response.body);
      print('Failed to update relationship: ${responseData['message']}');
    }
  } catch (error) {
    print('Error updating relationship: $error');
  }
}

Future<void> saveBuildingAnswers({
  required String layerId,
  required String buildingId,
  required Map<int, String> buildingAnswers,
  String? color,
  required List<List<double>> coordinates,
  String? userId,
  String? projectId,
}) async {
  final Map<String, String> convertedBuildingAnswers = buildingAnswers.map(
    (key, value) => MapEntry(key.toString(), value),
  );

  final Map<String, dynamic> requestBody = {
    'buildingAnswers': convertedBuildingAnswers,
    'color': color, 
    'coordinates': [coordinates], 
    'userId': userId,
    'projectId': projectId,
    'lastModified': DateTime.now().toUtc().toIso8601String(),
  };

  try {
    final response = await http.post(
      postBuildingBaseUrl(layerId, buildingId),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Answers saved successfully: ${responseData['message']}');
    } else {
      final responseData = jsonDecode(response.body);
      print('Failed to save answers: ${responseData['message']}');
    }
  } catch (error) {
    print('Error saving answers: $error');
  }
}

Future<void> deleteLayer(String layerId) async {
  try {
    final response = await http.delete(
      deleteLayerBaseUrl(layerId),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Layer deleted successfully: ${responseData['message']}');
    } else if (response.statusCode == 404) {
      final responseData = jsonDecode(response.body);
      print('Layer not found: ${responseData['message']}');
    } else {
      print('Failed to delete layer. Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('Error message: ${responseData['message']}');
    }
  } catch (error) {
    print('Error deleting layer: $error');
  }
}

Future<void> deleteRelationship({
  required String relationshipId,
  String? userId,
}) async {
  try {
    const String url = 'https://geosociomap-backend.onrender.com/';

    final response = await http.delete(
      Uri.parse('$url$relationshipId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId, 
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Relationship deleted successfully: ${responseData['message']}');
    } else if (response.statusCode == 404) {
      final responseData = jsonDecode(response.body);
      print(
          'Relationship not found or unauthorized: ${responseData['message']}');
    } else {
      print(
          'Failed to delete relationship. Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('Error message: ${responseData['message']}');
    }
  } catch (error) {
    print('Error deleting relationship: $error');
  }
}

Future<String?> getUserIdByEmail(String email) async {
  final url = getEmailBaseUrl(email);

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['userIds'] != null && data['userIds'].isNotEmpty) {
        return data['userIds'][0];
      } else {
        print('No user found for the provided email.');
        return null;
      }
    } else {
      print('Failed to fetch user ID: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error: $e');
    return null;
  }
}

Future<void> syncLayersToBackend(
    String projectId, List<Map<String, dynamic>> syncedLayers) async {
  const String apiUrl =
      'https://geosociomap-backend.onrender.com/layers/sync';
  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json', 
      },
      body: jsonEncode({
        'projectId': projectId,
        'layers': syncedLayers,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Sync successful: $responseData');
    } else {
      print('Failed to sync layers. Status code: ${response.statusCode}');
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Error syncing layers: $e');
  }
}

Future<void> syncRelationships({
  required String layerId,
  required String id,
  required List<List<double>> points,
  String? userId,
  required String type,
  String? projectId,
  required String description,
  String? updatedAt,
}) async {
  const String url =
      'https://geosociomap-backend.onrender.com/relationships/sync'; 

  final Map<String, dynamic> body = {
    'projectId': projectId, 
    'relationships': [
      {
        'id': id,
        'layerId': layerId,
        'points': points,
        'userId': userId,
        'type': type,
        'description': description,
        'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
        'isDelete': false,
      }
    ],
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
   
      final data = jsonDecode(response.body);
      print('Sync successful: ${data['message']}');
    } else {
    
      print('Failed to sync relationships: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> syncBuildingAnswers({
  required String layerId,
  required List<Map<String, dynamic>> buildingAnswers,
}) async {

  final url = Uri.parse(
      'https://geosociomap-backend.onrender.com/buildings/sync');


  print("pass");
 
  Map<String, dynamic> body = {
    'layerId': layerId,
    'buildingAnswers': buildingAnswers,
  };

  print("pass3");

  print(body);

  print(json.encode(body));
 print("pass4");

  try {

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json', 
      },
      body: json.encode(body), 
    );

     print("pass2");


    if (response.statusCode == 200) {
      print('Sync completed successfully: ${response.body}');
    } else {
      print('Failed to sync building answers: ${response.statusCode}');
      
    }
  } catch (e) {
    print('Error during sync: $e');
  }
}
