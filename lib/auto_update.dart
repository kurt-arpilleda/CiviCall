import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AutoUpdate {
  static const String apiUrl = "https://192.168.1.57/CiviCall/";
  static const String versionPath = "LatestVersionAPK/version.json";
  static const String apkPathPrefix = "LatestVersionAPK/";

  static const Duration requestTimeout = Duration(seconds: 5);
  static const int maxRetries = 6;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  static bool isUpdating = false;
  static late http.Client httpClient;

  static void _initializeHttpClient() {
    final HttpClient client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = requestTimeout;
    httpClient = IOClient(client);
  }

  static Future<void> checkForUpdate(BuildContext context, {bool manualCheck = false}) async {
    if (isUpdating) return;
    isUpdating = true;

    _initializeHttpClient();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await httpClient.get(
            Uri.parse("$apiUrl$versionPath")
        ).timeout(requestTimeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> versionInfo = jsonDecode(response.body);
          final int latestVersionCode = versionInfo["versionCode"];
          final String latestVersionName = versionInfo["versionName"];
          final String releaseNotes = versionInfo["releaseNotes"];
          final String apkFileName = versionInfo["apk"];

          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          int currentVersionCode = int.parse(packageInfo.buildNumber);

          if (latestVersionCode > currentVersionCode) {
            await _showUpdateConfirmationDialog(
                context,
                latestVersionName,
                releaseNotes,
                apkFileName
            );
            isUpdating = false;
            return;
          } else if (manualCheck) {
            Fluttertoast.showToast(msg: "You're using the latest version");
            isUpdating = false;
            return;
          }
          isUpdating = false;
          return;
        }
      } catch (e) {
        debugPrint("Error checking for update on attempt $attempt: $e");
      }

      if (attempt < maxRetries) {
        final delay = initialRetryDelay * (1 << (attempt - 1));
        debugPrint("Waiting for ${delay.inSeconds} seconds before retrying...");
        await Future.delayed(delay);
      }
    }

    if (manualCheck) {
      Fluttertoast.showToast(msg: "Failed to check for updates after $maxRetries attempts.");
    }
    isUpdating = false;
  }

  static Future<void> _showUpdateConfirmationDialog(
      BuildContext context,
      String versionName,
      String releaseNotes,
      String apkFileName
      ) async {
    bool? updateAccepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Available"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("New Version: $versionName"),
                const SizedBox(height: 10),
                const Text("Release Notes:"),
                Text(releaseNotes),
                const SizedBox(height: 20),
                const Text("Would you like to update now?"),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Update Now"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (updateAccepted == true) {
      await _startUpdateProcess(context, apkFileName);
    } else {
      isUpdating = false;
    }
  }

  static Future<void> _startUpdateProcess(BuildContext context, String apkFileName) async {
    await WakelockPlus.enable();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text("Updating Application"),
            content: StreamBuilder<int>(
              stream: _downloadAndInstallApk(context, apkFileName),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data! == 100) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: 1.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        const SizedBox(height: 10),
                        const Text("Installation in progress..."),
                      ],
                    );
                  } else if (snapshot.data! == -1) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 40),
                        const SizedBox(height: 10),
                        const Text("Update failed. Retrying..."),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: snapshot.data! / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 10),
                        Text("${snapshot.data}% Downloaded"),
                      ],
                    );
                  }
                } else {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 10),
                      const Text("Preparing download..."),
                    ],
                  );
                }
              },
            ),
          ),
        );
      },
    );

    await WakelockPlus.disable();
  }

  static Stream<int> _downloadAndInstallApk(
      BuildContext context,
      String apkFileName
      ) async* {
    _initializeHttpClient();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          yield -1;
          continue;
        }

        final String apkFilePath = "${externalDir.path}/$apkFileName";
        final File apkFile = File(apkFilePath);

        final request = http.Request('GET', Uri.parse("$apiUrl$apkPathPrefix$apkFileName"));
        final http.StreamedResponse response = await httpClient.send(request).timeout(requestTimeout);

        if (response.statusCode == 200) {
          int totalBytes = response.contentLength ?? 0;
          int downloadedBytes = 0;

          yield 0;

          final fileSink = apkFile.openWrite();
          await for (var chunk in response.stream) {
            downloadedBytes += chunk.length;
            fileSink.add(chunk);
            int progress = ((downloadedBytes / totalBytes) * 100).round();
            yield progress;
          }
          await fileSink.close();

          if (await apkFile.exists()) {
            yield 100;
            await _installApk(context, apkFilePath);
            return;
          } else {
            yield -1;
            Fluttertoast.showToast(msg: "Failed to save the APK file.");
          }
        }
      } catch (e) {
        debugPrint("Error downloading APK on attempt $attempt: $e");
        yield -1;
        if (attempt < maxRetries) {
          final delay = initialRetryDelay * (1 << (attempt - 1));
          debugPrint("Waiting for ${delay.inSeconds} seconds before retrying...");
          await Future.delayed(delay);
        }
      }
    }
    Fluttertoast.showToast(msg: "Failed to download update after $maxRetries attempts.");
  }

  static Future<void> _installApk(BuildContext context, String apkPath) async {
    try {
      if (Platform.isAndroid) {
        // Request install permission if needed (Android 8.0+)
        if (await Permission.requestInstallPackages.request().isGranted) {
          final result = await OpenFile.open(apkPath);
          if (result.type != ResultType.done) {
            Fluttertoast.showToast(msg: "Failed to open the installer. Retrying...");
            await Future.delayed(const Duration(seconds: 2));
            await checkForUpdate(context);
          }
        } else {
          Fluttertoast.showToast(msg: "Installation permission denied. Retrying...");
          await Future.delayed(const Duration(seconds: 2));
          await checkForUpdate(context);
        }
      } else {
        Fluttertoast.showToast(msg: "Auto-update is only supported on Android");
      }
    } catch (e) {
      debugPrint("Error installing APK: $e");
      Fluttertoast.showToast(msg: "Failed to install update. Retrying...");
      await Future.delayed(const Duration(seconds: 2));
      await checkForUpdate(context);
    } finally {
      isUpdating = false;
      httpClient.close();
    }
  }
}