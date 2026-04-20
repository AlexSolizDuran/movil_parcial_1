class Vehiculo {
  final int id;
  final int clienteId;
  final String placa;
  final String modelo;
  final String marca;
  final String? color;

  Vehiculo({
    required this.id,
    required this.clienteId,
    required this.placa,
    required this.modelo,
    required this.marca,
    this.color,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'],
      clienteId: json['cliente_id'],
      placa: json['placa'],
      modelo: json['modelo'],
      marca: json['marca'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'placa': placa,
      'modelo': modelo,
      'marca': marca,
      'color': color,
    };
  }
}

class VehiculoCreate {
  final String placa;
  final String modelo;
  final String marca;
  final String? color;

  VehiculoCreate({
    required this.placa,
    required this.modelo,
    required this.marca,
    this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'placa': placa,
      'modelo': modelo,
      'marca': marca,
      'color': color,
    };
  }
}

class VehiculoUpdate {
  final String? placa;
  final String? modelo;
  final String? marca;
  final String? color;

  VehiculoUpdate({
    this.placa,
    this.modelo,
    this.marca,
    this.color,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (placa != null) data['placa'] = placa;
    if (modelo != null) data['modelo'] = modelo;
    if (marca != null) data['marca'] = marca;
    if (color != null) data['color'] = color;
    return data;
  }
}
