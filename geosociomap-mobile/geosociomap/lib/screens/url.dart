
// ดึงค่า BASE_URL จากตัวแปรสภาพแวดล้อม
const String BASE_URL = String.fromEnvironment(
  'https://geosociomap-backend.onrender.com',
  defaultValue: 'https://geosociomap-backend.onrender.com', // ให้ผู้ใช้แก้ไขเป็นของตัวเอง
);

Uri getLayerBaseUrl(String uid, String endpoint) {
  return Uri.parse('$BASE_URL/$endpoint?userId=$uid');
}

Uri getLayerProject(String projectId, String? userId) {
  return Uri.parse('$BASE_URL/layers/$projectId?userId=$userId');
}

Uri getProjectBaseUrl(String uid) {
  return Uri.parse('$BASE_URL/projects/$uid');
}

Uri putLayerUrl(String id) {
  return Uri.parse('$BASE_URL/layers/update/$id');
}

Uri postLayerUrl() {
  return Uri.parse('$BASE_URL/add-layer');
}

Uri postFileUrl() {
  return Uri.parse('$BASE_URL/upload');
}

Uri getBaseUrl(String id) {
  return Uri.parse('$BASE_URL/project/$id');
}

Uri getImageUrl() {
  return Uri.parse('$BASE_URL/upload');
}

Uri putNoteUrl(String? projectId) {
  return Uri.parse('$BASE_URL/notes/save/$projectId');
}

Uri postRelationshipUrl() {
  return Uri.parse('$BASE_URL/api/relationships');
}

Uri putRelationshipUrl(String id) {
  return Uri.parse('$BASE_URL/api/relationships/$id');
}

Uri getBuildingAnswerBaseUrl(String layerId, String? userId) {
  return Uri.parse('$BASE_URL/layers/$layerId/buildings?userId=$userId');
}

Uri getRelationshipBaseUrl(String projectId, String? userId) {
  return Uri.parse('$BASE_URL/api/relationships?projectId=$projectId&userId=$userId');
}

Uri getNotesBaseUrl(String projectId, String? userId) {
  return Uri.parse('$BASE_URL/notes/$projectId/$userId');
}

Uri postLayerBaseUrl(String uid) {
  return Uri.parse('$BASE_URL/share-layer');
}

Uri postBuildingBaseUrl(String layerId, String buildingId) {
  return Uri.parse('$BASE_URL/layers/$layerId/buildings/$buildingId/answers');
}

Uri deleteLayerBaseUrl(String layerId) {
  return Uri.parse('$BASE_URL/layers/$layerId');
}

Uri deleteRelationshipBaseUrl(String relationshipId) {
  return Uri.parse('$BASE_URL/api/relationships/$relationshipId');
}

Uri getEmailBaseUrl(String email) {
  return Uri.parse('$BASE_URL/api/getUserIdsByEmails?emails=$email');
}

