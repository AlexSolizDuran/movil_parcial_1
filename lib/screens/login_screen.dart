import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'tecnico/tecnico_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _esTecnico = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final rol = await ApiService.getUserRole();
      debugPrint('Rol decodificado: $rol');
      debugPrint('¿Es técnico?: $_esTecnico');
      
      if (_esTecnico) {
        if (rol == 'tecnico') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TecnicoHomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No eres técnico. Inicia sesión como cliente.'),
              backgroundColor: Colors.red,
            ),
          );
          await AuthService.logout();
        }
      } else {
        if (rol == 'cliente' || rol == 'dueno') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No eres cliente. Inicia sesión como técnico.'),
              backgroundColor: Colors.red,
            ),
          );
          await AuthService.logout();
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : const Color(0xFF2563EB);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.amber.shade400, Colors.amber.shade700]
                          : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AUXIA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu asistente de emergencia vehicular',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _esTecnico = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: !_esTecnico
                                  ? LinearGradient(
                                      colors: isDark
                                          ? [Colors.amber.shade400, Colors.amber.shade600]
                                          : [
                                              const Color(0xFF2563EB),
                                              const Color(0xFF1D4ED8)
                                            ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Soy Cliente',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: !_esTecnico
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _esTecnico = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: _esTecnico
                                  ? LinearGradient(
                                      colors: isDark
                                          ? [Colors.amber.shade400, Colors.amber.shade600]
                                          : [
                                              const Color(0xFF2563EB),
                                              const Color(0xFF1D4ED8)
                                            ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Soy Técnico',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _esTecnico
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 0,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu usuario';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.amber.shade400, Colors.amber.shade600]
                          : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Regístrate',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
