import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final token = await ApiService.getToken();
    
    if (token != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 80,
              color: isDark ? Colors.amber : Colors.blue[700],
            ),
            const SizedBox(height: 24),
            Text(
              'AUXIA',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.amber : Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Asistente Vehicular',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: isDark ? Colors.amber : Colors.blue[700],
            ),
          ],
        ),
      ),
    );
  }
}
