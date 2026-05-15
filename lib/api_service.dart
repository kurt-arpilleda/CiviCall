import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String apiUrl = "https://192.168.1.57/CiviCall/CiviCallAPI";
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

  Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String surName,
    required int gender,
    required String email,
    required String phoneNum,
    required String password,
    required int signupType,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_signup.php");
      final response = await httpClient.post(
        uri,
        body: {
          'firstName': firstName,
          'surName': surName,
          'gender': gender.toString(),
          'email': email,
          'phoneNum': phoneNum,
          'password': password,
          'signupType': signupType.toString(),
        },
      ).timeout(requestTimeout);

      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> signUpWithGoogle({
    required String firstName,
    required String surName,
    required String email,
    required String googleId,
    required String photoUrl,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_signup.php");
      final response = await httpClient.post(
        uri,
        body: {
          'firstName': firstName,
          'surName': surName,
          'gender': '0',
          'email': email,
          'phoneNum': '',
          'password': '',
          'signupType': '1',
          'googleId': googleId,
          'photoUrl': photoUrl,
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
      final uri = Uri.parse("${apiUrl}cares_login.php");
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
    String? fcmToken,
  }) async {
    return _executeWithRetry(() async {
      final deviceId = await _getOrCreateDeviceId();
      final uri = Uri.parse("${apiUrl}cares_login.php");
      final response = await httpClient.post(
        uri,
        body: {
          'email': email,
          'googleId': googleId,
          'deviceId': deviceId,
          'isGoogleLogin': '1',
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      ).timeout(requestTimeout);

      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String emailOrPhone,
  }) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse("${apiUrl}cares_reset_password.php");
      final response = await httpClient.post(
        uri,
        body: {'emailOrPhone': emailOrPhone},
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    });
  }


  Future<Map<String, dynamic>> logout() async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "Waiting for Network"};
      }

      final uri = Uri.parse("${apiUrl}cares_logout.php");
      final response = await httpClient.post(
        uri,
        body: {'token': token},
      ).timeout(requestTimeout);

      return _handleResponse(response);
    });
  }


  Future<Map<String, dynamic>> getFcmTokensByAccountId(int accountId) async {
    return _executeWithRetry(() async {
      final token = await getAuthToken();
      if (token == null) {
        return {"success": false, "message": "Waiting for Network"};
      }

      final uri = Uri.parse("${apiUrl}cares_getFcmTokens.php");
      final response = await httpClient.post(
        uri,
        body: {
          'token': token,
          'accountId': accountId.toString(),
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