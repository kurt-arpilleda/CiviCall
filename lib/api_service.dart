import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String apiUrl = "http://192.168.1.58/CiviCall/CiviCallAPI/";
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration requestTimeoutUploadImage = Duration(seconds: 45);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  late http.Client httpClient;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  ApiService() {
    httpClient = _createHttpClient();
  }

  http.Client _createHttpClient() {
    final HttpClient client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = requestTimeout;
    client.idleTimeout = const Duration(seconds: 30);
    return IOClient(client);
  }

  Future<String> _getOrCreateDeviceId() async {
    String? deviceId = await _secureStorage.read(key: 'deviceId');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await _secureStorage.write(key: 'deviceId', value: deviceId);
    }
    return deviceId;
  }

  Future<Map<String, dynamic>> _executeWithRetry(Future<Map<String, dynamic>> Function() fn) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          return {"success": false, "message": "Slow Internet"};
        }
        await Future.delayed(retryDelay * attempt);
      }
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {"success": false, "message": "Waiting for Network"};
      }
    }
    return {"success": false, "message": "Waiting for Network"};
  }

  Map<String, dynamic> _handleStreamResponse(http.StreamedResponse response, String responseBody) {
    if (response.statusCode == 200) {
      try {
        return jsonDecode(responseBody);
      } catch (e) {
        return {"success": false, "message": "Waiting for Network"};
      }
    }
    return {"success": false, "message": "Waiting for Network"};
  }

  Future<Map<String, dynamic>> fetchCampus() async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}civicall_fetchCampus.php");
      final response = await httpClient.get(uri).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> fetchDropdowns() async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}civicall_fetch_dropdowns.php");
      final response = await httpClient.get(uri).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String middleName,
    required String lastName,
    required String address,
    required String mobileNum,
    required int campusId,
    required int userTypeId,
    required String birthDay,
    required int gender,
    required String email,
    required String password,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}civicall_signup.php");
      final response = await httpClient.post(
        uri,
        body: {
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'address': address,
          'mobileNum': mobileNum,
          'campusId': campusId.toString(),
          'userTypeId': userTypeId.toString(),
          'birthDay': birthDay,
          'gender': gender.toString(),
          'email': email,
          'password': password,
        },
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    return _executeWithRetry(() async {
      final deviceId = await _getOrCreateDeviceId();
      final uri = Uri.parse("${apiUrl}civicall_login.php");
      final response = await httpClient.post(
        uri,
        body: {
          'email': email,
          'password': password,
          'deviceId': deviceId,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String googleId,
    required String firstName,
    required String lastName,
    String? photoUrl,
    String? birthDay,
    int? gender,
    String? mobileNum,
    String? fcmToken,
  }) async {
    return _executeWithRetry(() async {
      final deviceId = await _getOrCreateDeviceId();
      final uri = Uri.parse("${apiUrl}civicall_login.php");
      final response = await httpClient.post(
        uri,
        body: {
          'email': email,
          'googleId': googleId,
          'deviceId': deviceId,
          'isGoogleLogin': '1',
          'firstName': firstName,
          'lastName': lastName,
          if (photoUrl != null) 'photoUrl': photoUrl,
          if (birthDay != null) 'birthDay': birthDay,
          if (gender != null) 'gender': gender.toString(),
          if (mobileNum != null) 'mobileNum': mobileNum,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> logout() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "Not logged in"};
      }
      final uri = Uri.parse("${apiUrl}civicall_logout.php");
      final response = await httpClient.post(
        uri,
        body: {'authToken': token},
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> getUserData() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_get_user.php");
      final response = await httpClient.post(
        uri,
        body: {'authToken': token},
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? address,
    String? mobileNum,
    String? emergencyNum,
    int? campusId,
    int? departmentId,
    int? courseId,
    int? userTypeId,
    String? birthDay,
    int? gender,
    int? nstpId,
    String? srCode,
    String? yrSection,
  }) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_update_user.php");
      final Map<String, String> body = {'authToken': token};
      if (firstName != null) body['firstName'] = firstName;
      if (middleName != null) body['middleName'] = middleName;
      if (lastName != null) body['lastName'] = lastName;
      if (address != null) body['address'] = address;
      if (mobileNum != null) body['mobileNum'] = mobileNum;
      if (emergencyNum != null) body['emergencyNum'] = emergencyNum;
      if (campusId != null) body['campusId'] = campusId.toString();
      if (departmentId != null) body['departmentId'] = departmentId.toString();
      if (courseId != null) body['courseId'] = courseId.toString();
      if (userTypeId != null) body['userTypeId'] = userTypeId.toString();
      if (birthDay != null) body['birthDay'] = birthDay;
      if (gender != null) body['gender'] = gender.toString();
      if (nstpId != null) body['nstpId'] = nstpId.toString();
      if (srCode != null) body['srCode'] = srCode;
      if (yrSection != null) body['yrSection'] = yrSection;
      final response = await httpClient.post(uri, body: body).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_upload_photo.php");
      final request = http.MultipartRequest('POST', uri);
      request.fields['authToken'] = token;

      final mimeType = _getMimeType(imageFile.path);
      final mediaType = _parseMediaType(mimeType);

      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: mediaType,
      ));

      final streamedResponse = await request.send().timeout(requestTimeoutUploadImage);
      final responseBody = await streamedResponse.stream.bytesToString();
      print('Upload response: $responseBody');

      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {"success": false, "message": "Invalid server response"};
        }
      } catch (e) {
        return {"success": false, "message": "Failed to parse server response: $responseBody"};
      }
    } catch (e) {
      print('Upload exception: $e');
      return {"success": false, "message": "Upload error: ${e.toString()}"};
    }
  }
  Future<Map<String, dynamic>> getVerificationStatus() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_getVerification.php");
      final response = await httpClient.post(
        uri,
        body: {'authToken': token},
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> uploadVerification({
    required File file,
    required int fileType,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_uploadVerification.php");
      final request = http.MultipartRequest('POST', uri);
      request.fields['authToken'] = token;
      request.fields['fileType'] = fileType.toString();

      final mimeType = _getMimeType(file.path);
      final mediaType = _parseMediaType(mimeType);
      request.files.add(await http.MultipartFile.fromPath(
        'verificationFile',
        file.path,
        contentType: mediaType,
      ));

      final streamedResponse = await request.send().timeout(requestTimeoutUploadImage);
      final responseBody = await streamedResponse.stream.bytesToString();
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {"success": false, "message": "Invalid server response"};
        }
      } catch (e) {
        return {"success": false, "message": "Failed to parse server response"};
      }
    } catch (e) {
      return {"success": false, "message": "Upload error: ${e.toString()}"};
    }
  }
  Future<Map<String, dynamic>> getFeedback() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_feedback.php");
      final response = await httpClient.post(
        uri,
        body: {'authToken': token, 'action': 'get'},
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> sendFeedback({
    required double starNum,
    required String feedback,
  }) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_feedback.php");
      final response = await httpClient.post(
        uri,
        body: {
          'authToken': token,
          'action': 'send',
          'starNum': starNum.toString(),
          'feedBack': feedback,
        },
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }
  String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  http.MediaType? _parseMediaType(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length == 2) {
      return http.MediaType(parts[0], parts[1]);
    }
    return null;
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String emailOrPhone,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}civicall_reset_password.php");
      final response = await httpClient.post(
        uri,
        body: {'emailOrPhone': emailOrPhone},
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    });
  }
  Future<Map<String, dynamic>> sendReport({
    required String reportText,
    required int reportType,
    File? imageFile,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_send_report.php");
      final request = http.MultipartRequest('POST', uri);
      request.fields['authToken'] = token;
      request.fields['reportText'] = reportText;
      request.fields['reportType'] = reportType.toString();

      if (imageFile != null) {
        final mimeType = _getMimeType(imageFile.path);
        final mediaType = _parseMediaType(mimeType);
        request.files.add(await http.MultipartFile.fromPath(
          'reportImage',
          imageFile.path,
          contentType: mediaType,
        ));
      }

      final streamedResponse = await request.send().timeout(requestTimeoutUploadImage);
      final responseBody = await streamedResponse.stream.bytesToString();
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {"success": false, "message": "Invalid server response"};
        }
      } catch (e) {
        return {"success": false, "message": "Failed to parse server response"};
      }
    } catch (e) {
      return {"success": false, "message": "Upload error: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> getUserReports() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "No token"};
      }
      final uri = Uri.parse("${apiUrl}civicall_get_reports.php");
      final response = await httpClient.post(
        uri,
        body: {'authToken': token},
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }
  Future<Map<String, dynamic>> fetchEngagementCategories() async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}civicall_fetch_engagement_categories.php");
      final response = await httpClient.get(uri).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> addEngagement({
    required int categoryId,
    required String title,
    required String description,
    required String objective,
    required String instruction,
    required String locationAddress,
    required double latitude,
    required double longitude,
    required String startSchedule,
    required String endSchedule,
    required String campus,
    required int targetParty,
    required int activityPoints,
    required String facilitatorName,
    required String facilitatorContact,
    File? imageFile,
  }) async {
    return _executeWithRetry(() async {
      final token = await _secureStorage.read(key: 'authToken') ?? '';
      final uri = Uri.parse("${apiUrl}civicall_add_engagement.php");

      final request = http.MultipartRequest('POST', uri);
      request.fields['authToken']          = token;
      request.fields['categoryId']         = categoryId.toString();
      request.fields['title']              = title;
      request.fields['description']        = description;
      request.fields['objective']          = objective;
      request.fields['instruction']        = instruction;
      request.fields['locationAddress']    = locationAddress;
      request.fields['latitude']           = latitude.toString();
      request.fields['longitude']          = longitude.toString();
      request.fields['startSchedule']      = startSchedule;
      request.fields['endSchedule']        = endSchedule;
      request.fields['campus']             = campus;
      request.fields['targetParty']        = targetParty.toString();
      request.fields['activityPoints']     = activityPoints.toString();
      request.fields['facilitatorName']    = facilitatorName;
      request.fields['facilitatorContact'] = facilitatorContact;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('engagementImage', imageFile.path),
        );
      }

      final streamed = await httpClient.send(request).timeout(requestTimeoutUploadImage);
      final body = await streamed.stream.bytesToString();
      return _handleStreamResponse(streamed, body);
    });
  }
  Future<Map<String, dynamic>> fetchEngagements() async {
    return _executeWithRetry(() async {
      final token = await _secureStorage.read(key: 'authToken') ?? '';
      final uri = Uri.parse("${apiUrl}civicall_fetch_engagements.php");
      final response = await httpClient.post(
        uri,
        body: {'authToken': token},
      ).timeout(requestTimeout);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> updateEngagement({
    required int engagementId,
    required int categoryId,
    required String title,
    required String description,
    required String objective,
    required String instruction,
    required String locationAddress,
    required double latitude,
    required double longitude,
    required String startSchedule,
    required String endSchedule,
    required String campus,
    required int targetParty,
    required int activityPoints,
    required String facilitatorName,
    required String facilitatorContact,
    File? imageFile,
  }) async {
    return _executeWithRetry(() async {
      final token = await _secureStorage.read(key: 'authToken') ?? '';
      final uri = Uri.parse("${apiUrl}civicall_update_engagement.php");

      final request = http.MultipartRequest('POST', uri);
      request.fields['authToken']          = token;
      request.fields['engagementId']       = engagementId.toString();
      request.fields['categoryId']         = categoryId.toString();
      request.fields['title']              = title;
      request.fields['description']        = description;
      request.fields['objective']          = objective;
      request.fields['instruction']        = instruction;
      request.fields['locationAddress']    = locationAddress;
      request.fields['latitude']           = latitude.toString();
      request.fields['longitude']          = longitude.toString();
      request.fields['startSchedule']      = startSchedule;
      request.fields['endSchedule']        = endSchedule;
      request.fields['campus']             = campus;
      request.fields['targetParty']        = targetParty.toString();
      request.fields['activityPoints']     = activityPoints.toString();
      request.fields['facilitatorName']    = facilitatorName;
      request.fields['facilitatorContact'] = facilitatorContact;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('engagementImage', imageFile.path),
        );
      }

      final streamed = await httpClient.send(request).timeout(requestTimeoutUploadImage);
      final body = await streamed.stream.bytesToString();
      return _handleStreamResponse(streamed, body);
    });
  }
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: 'authToken', value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'authToken');
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: 'authToken');
  }

  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: 'deviceId');
  }

  static void setupHttpOverrides() {
    HttpOverrides.global = MyHttpOverrides();
  }

  void dispose() {
    httpClient.close();
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = ApiService.requestTimeout;
    client.idleTimeout = const Duration(seconds: 30);
    return client;
  }
}