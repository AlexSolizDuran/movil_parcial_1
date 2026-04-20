class Usuario {
  final int id;
  final String email;
  final String username;
  final String nombre;
  final String? telefono;
  final String rol;

  Usuario({
    required this.id,
    required this.email,
    required this.username,
    required this.nombre,
    this.telefono,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      rol: json['rol'] is String ? json['rol'] : json['rol']['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'nombre': nombre,
      'telefono': telefono,
      'rol': rol,
    };
  }
}

class UsuarioRegister {
  final String email;
  final String username;
  final String nombre;
  final String? telefono;
  final String password;
  final String rol;

  UsuarioRegister({
    required this.email,
    required this.username,
    required this.nombre,
    this.telefono,
    required this.password,
    this.rol = 'cliente',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'nombre': nombre,
      'telefono': telefono,
      'password': password,
      'rol': rol,
    };
  }
}

class UsuarioUpdate {
  final String? email;
  final String? username;
  final String? nombre;
  final String? telefono;

  UsuarioUpdate({
    this.email,
    this.username,
    this.nombre,
    this.telefono,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (username != null) data['username'] = username;
    if (nombre != null) data['nombre'] = nombre;
    if (telefono != null) data['telefono'] = telefono;
    return data;
  }
}
