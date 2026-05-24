import 'package:civicall/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splashScreen.dart';
import 'login.dart';
import 'checkAccount.dart';
import 'theme/app_theme.dart';
import 'api_service.dart';
import 'firebase/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.setupHttpOverrides();
  await FirebaseService.initialize();
  final apiService = ApiService();
  final authToken = await apiService.getAuthToken();

  runApp(MyApp(
    initialRoute: authToken != null ? '/checkAccount' : '/splash',
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({required this.initialRoute, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CiviCall',
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/checkAccount': (context) => const CheckAccountScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}