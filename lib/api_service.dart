import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String apiUrl = "http://192.168.1.57/CiviCall/CiviCallAPI/";
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

  Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String middleName,
    required String lastName,
    required String address,
    required String mobileNum,
    required int campusId,
    required int userCategory,
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
          'userCategory': userCategory.toString(),
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
        },
      ).timeout(requestTimeout);
      return _handleResponse(response);
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