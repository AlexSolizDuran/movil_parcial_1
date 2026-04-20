import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'vehiculos_list_screen.dart';

class PerfilScreen extends StatefulWidget {
  final Usuario? usuario;
  final VoidCallback onUpdate;

  const PerfilScreen({
    super.key,
    required this.usuario,
    required this.onUpdate,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _telefonoController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(PerfilScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usuario != oldWidget.usuario) {
      _initControllers();
    }
  }

  void _initControllers() {
    _nombreController = TextEditingController(text: widget.usuario?.nombre ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _usernameController = TextEditingController(text: widget.usuario?.username ?? '');
    _telefonoController = TextEditingController(text: widget.usuario?.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_isEditing) return;

    setState(() => _isLoading = true);

    final update = UsuarioUpdate(
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isNotEmpty
          ? _telefonoController.text.trim()
          : null,
    );

    final result = await AuthService.updateProfile(widget.usuario!.id, update);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onUpdate();
      setState(() => _isEditing = false);
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
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

    if (widget.usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor,
              child: Text(
                widget.usuario!.nombre.isNotEmpty
                    ? widget.usuario!.nombre[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Cliente',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre',
                      icon: Icons.badge,
                      enabled: _isEditing,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Usuario',
                      icon: Icons.account_circle,
                      enabled: false,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email,
                      enabled: _isEditing,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _telefonoController,
                      label: 'Teléfono',
                      icon: Icons.phone,
                      enabled: _isEditing,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.directions_car, color: primaryColor),
                title: const Text('Mis Vehículos'),
                subtitle: const Text('Gestionar vehículos registrados'),
                trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VehiculosListScreen()),
                  );
                },
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() => _isEditing = false);
                              _initControllers();
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled
            ? (isDark ? Colors.grey[800] : Colors.grey[100])
            : (isDark ? Colors.grey[850] : Colors.grey[200]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
