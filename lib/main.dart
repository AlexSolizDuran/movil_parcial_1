import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/notificacion_local_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notifService = NotificacionLocalService();
  await notifService.inicializar();
  await notifService.solicitarPermisos();
  
  runApp(const AuxiaApp());
}

class AuxiaApp extends StatelessWidget {
  const AuxiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUXIA',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          indicatorColor: Colors.amber.withAlpha(50),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.amber);
            }
            return IconThemeData(color: Colors.grey[400]);
          }),
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black87,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.blue[700]!.withAlpha(30),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: Colors.blue[700]);
            }
            return IconThemeData(color: Colors.grey[600]);
          }),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
