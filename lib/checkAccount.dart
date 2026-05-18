import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:civicall/theme/app_theme.dart';
import 'package:civicall/api_service.dart';
import 'package:civicall/dashboard.dart';
import 'package:civicall/login.dart';

class CheckAccountScreen extends StatefulWidget {
  const CheckAccountScreen({Key? key}) : super(key: key);

  @override
  State<CheckAccountScreen> createState() => _CheckAccountScreenState();
}

class _CheckAccountScreenState extends State<CheckAccountScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndAccount();
  }
  Future<void> _checkConnectivityAndAccount() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _noInternet = true;
        _isLoading = false;
      });
      return;
    }
    await _verifyAccount();
  }

  Future<void> _verifyAccount() async {
    try {
      final response = await _apiService.getUserData();

      if (response['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        final message = response['message'] ?? '';
        if (message.contains('Invalid or expired token') ||
            message.contains('No token')) {
          await _apiService.clearAuthToken();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else {
          setState(() {
            _noInternet = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _noInternet = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _noInternet = false;
    });
    await _checkConnectivityAndAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppTheme.redPink)
                  : _noInternet
                  ? _buildNoInternetWidget()
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned(
      top: -80,
      right: -60,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.redPink.withOpacity(0.07),
        ),
      ),
    );
  }

  Widget _buildNoInternetWidget() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 80,
            color: AppTheme.darkGray.withOpacity(0.6),
          ),
          const SizedBox(height: 20),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.darkGray.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redPink,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}