

class UserModel {
  final int id;
  final String nombre;
  final String apellidos;

  // Agrega más atributos según sea necesario

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellidos,


    // Agrega más parámetros según sea necesario
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:json['usuario']['id'] ?? 0,
      nombre: json['usuario']['nombre'] ?? '',
      apellidos: json['usuario']['apellidos'] ?? '',


      // Agrega más inicializaciones según sea necesario
    );
  }
}
