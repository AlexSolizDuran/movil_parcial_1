import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final usuario = UsuarioRegister(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      nombre: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim().isNotEmpty 
          ? _telefonoController.text.trim() 
          : null,
      password: _passwordController.text,
    );

    final result = await AuthService.register(usuario);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Ahora puedes iniciar sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Únete a AUXIA',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.alternate_email, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa un nombre de usuario';
                            }
                            if (value.length < 3) {
                              return 'El usuario debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Teléfono (opcional)',
                            prefixIcon: Icon(Icons.phone_android, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
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
                              return 'Ingresa una contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                              return 'Confirma tu contraseña';
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
                    onPressed: _isLoading ? null : _register,
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
                              Icon(Icons.person_add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Registrarse',
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
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Inicia sesión',
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
