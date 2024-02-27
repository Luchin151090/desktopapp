import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'package:desktopapp/components/empleado/login1.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:desktopapp/components/provider/user_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Conductor {
  int? id;
  int rol_id;
  String nickname;
  String contrasena;
  String email;
  int usuario_id;
  String nombres;
  String apellidos;
  String? licencia;
  String dni;
  String fecha_nacimiento;

  Conductor(
      {required this.id,
      required this.rol_id,
      required this.nickname,
      required this.contrasena,
      required this.email,
      required this.usuario_id,
      required this.nombres,
      required this.apellidos,
      required this.licencia,
      required this.dni,
      required this.fecha_nacimiento});
}

class Empleado {
  int? id;
  int rol_id;
  String nickname;
  String contrasena;
  String email;
  int usuario_id;
  String nombres;
  String apellidos;
  String dni;
  String fecha_nacimiento;
  String? codigo_empleado;

  Empleado(
      {required this.id,
      required this.rol_id,
      required this.nickname,
      required this.contrasena,
      required this.email,
      required this.usuario_id,
      required this.nombres,
      required this.apellidos,
      required this.codigo_empleado,
      required this.dni,
      required this.fecha_nacimiento});
}

class Crud extends StatefulWidget {
  const Crud({super.key});

  @override
  State<Crud> createState() => _CrudState();
}

class _CrudState extends State<Crud> {
  String apiClima =
      "https://api.openweathermap.org/data/2.5/weather?q=Arequipa&appid=08607bf479e5f47f5b768154953d10f6";

  TextEditingController _nombre = TextEditingController();
  TextEditingController _apellidos = TextEditingController();
  TextEditingController _dni = TextEditingController();
  TextEditingController _fechanacimiento = TextEditingController();
  TextEditingController _usuario = TextEditingController();
  TextEditingController _contrasena = TextEditingController();
  TextEditingController _email = TextEditingController();

  String apiUrl = dotenv.env['API_URL'] ?? '';
  String apiEmpleado = '/api/user_empleado';
  String apiConductor = '/api/user_conductor';
  late int status = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Conductor> conductores = [];
  List<Empleado> empleados = [];

  late double temperatura = 0.0;
  DateTime nows = DateTime.now();
  // Formato para obtener el nombre del mes
  final monthFormat = DateFormat('MMMM');
  // Formato para obtener el nombre del mes

  // Obtener el nombre del mes

  @override
  void initState() {
    super.initState();
    getTemperature();
    getEmpleado();
    getConductores();
  }

  // EMPLEADO
  Future<dynamic> createEmpleado(
      nombre, apellidos, dni, fecha, usuario, contrasena, email) async {
    try {
      var res = await http.post(Uri.parse(apiUrl + apiEmpleado),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({
            "rol_id": 2,
            "nickname": usuario,
            "contrasena": contrasena,
            "email": email ?? '',
            "nombres": nombre,
            "apellidos": apellidos,
            "codigo_empleado": "",
            "dni": dni,
            "fecha_nacimiento": fecha,
          }));
      if (res.statusCode == 200) {
        setState(() {
          status = 200;
        });
      } else if (res.statusCode == 409) {
        setState(() {
          status = 409;
        });
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> getEmpleado() async {
    var res = await http.get(
      Uri.parse(apiUrl + apiEmpleado),
      headers: {"Content-type": "application/json"},
    );
    try {
      var data = json.decode(res.body);
      List<Empleado> tempEmpleado = data.map<Empleado>((data) {
        return Empleado(
            id: data['id'],
            rol_id: data['rol_id'],
            nickname: data['nickname'],
            contrasena: data['contrasena'],
            email: data['email'],
            usuario_id: data['usuario_id'],
            nombres: data['nombres'],
            apellidos: data['apellidos'],
            codigo_empleado: data['codigo_empleado'],
            dni: data['dni'],
            fecha_nacimiento: data['fecha_nacimiento']);
      }).toList();
      setState(() {
        empleados = tempEmpleado;
      });
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> deleteEmpleado(id) async {
    var res = await http.delete(
        Uri.parse(apiUrl + apiEmpleado + '/' + id.toString()),
        headers: {"Content-type": "application/json"});
    if (res.statusCode == 200) {
      print("me booro");
    }
  }

// CONDUCTOR
  Future<dynamic> createConductor(
      nombre, apellidos, dni, fecha, usuario, contrasena, email) async {
    try {
      var res = await http.post(Uri.parse(apiUrl + apiConductor),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({
            "rol_id": 5,
            "nickname": usuario,
            "contrasena": contrasena,
            "email": email ?? '',
            "nombres": nombre,
            "apellidos": apellidos,
            "licencia": "",
            "dni": dni,
            "fecha_nacimiento": fecha,
          }));
      if (res.statusCode == 200) {
        setState(() {
          status = 200;
        });
      } else if (res.statusCode == 409) {
        setState(() {
          status = 409;
        });
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> getConductores() async {
    var res = await http.get(Uri.parse(apiUrl + apiConductor),
        headers: {"Content-type": "application/json"});
    try {
      var data = json.decode(res.body);
      List<Conductor> tempConductor = data.map<Conductor>((data) {
        return Conductor(
            id: data['id'],
            rol_id: data['rol_id'],
            nickname: data['nickname'],
            contrasena: data['contrasena'],
            email: data['email'],
            usuario_id: data['usuario_id'],
            nombres: data['nombres'],
            apellidos: data['apellidos'],
            licencia: data['licencia'],
            dni: data['dni'],
            fecha_nacimiento: data['fecha_nacimiento']);
      }).toList();
      setState(() {
        conductores = tempConductor;
      });
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> deleteConductor(id) async {
    var res = await http.delete(
        Uri.parse(apiUrl + apiConductor + '/' + id.toString()),
        headers: {"Content-type": "application/json"});
    if (res.statusCode == 200) {
      print("borro conductor");
    }
  }

  // CLIMA
  Future<dynamic> getTemperature() async {
    try {
      var res = await http.get(Uri.parse(apiClima),
          headers: {"Content-type": "application/json"});
      if (res.statusCode == 200) {
        var data = json.decode(res.body);

        //
        print("${data['main']['temp']}");
        setState(() {
          temperatura = data['main']['temp'] - 273.15;
        });
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final monthName = monthFormat.format(nows);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 82, 56, 85),
      body: Padding(
        padding: const EdgeInsets.all(6),
        child: SingleChildScrollView(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                width: MediaQuery.of(context).size.width / 3,
                height: MediaQuery.of(context).size.height / 1.1,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Hola, ${userProvider.user?.nombre}",
                          style: TextStyle(fontSize: 20),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 20),
                          width: MediaQuery.of(context).size.width / 5.5,
                          height: 80,
                          // color: Colors.amber,
                          child: Column(
                            children: [
                              Text(
                                "Arequipa,${nows.day} de ${monthName} del ${nows.year}",
                                style: TextStyle(fontSize: 15),
                              ),
                              Text(
                                "${temperatura.toStringAsFixed(1)} ° C",
                                style: TextStyle(fontSize: 23),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Bienvenid@ a Agua Sol",
                      style: TextStyle(fontSize: 20),
                    ),
                    Container(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(top: 20, bottom: 20),
                            decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              "Creación de usuarios",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          Container(
                              margin: const EdgeInsets.only(left: 20),
                              width: 100,
                              height: 90,
                              child:
                                  Lottie.asset('lib/imagenes/credencial.json')),
                          Container(
                            margin: const EdgeInsets.only(left: 20),
                            //color: Colors.grey,
                            width: 130,
                            height: 30,
                            child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Login1()));
                                },
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        (Color.fromARGB(255, 0, 41, 75)))),
                                child: const Text(
                                  "Cerrar Sesión",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                )),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(20)),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombre,
                              decoration: InputDecoration(labelText: 'Nombre'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese un nombre';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _apellidos,
                              decoration:
                                  InputDecoration(labelText: 'Apellidos'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese un apellido';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _dni,
                              decoration: InputDecoration(labelText: 'DNI'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese un dni';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              readOnly: true,
                              controller:
                                  _fechanacimiento, // Usa el controlador de texto
                              onTap: () async {
                                // Abre el selector de fechas cuando se hace clic en el campo
                                DateTime? fechaSeleccionada =
                                    await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime(2101),
                                );

                                if (fechaSeleccionada != null) {
                                  // Actualiza el valor del campo de texto con la fecha seleccionada
                                  _fechanacimiento.text =
                                      "${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}";
                                }
                              },
                              keyboardType: TextInputType.datetime,
                              style: const TextStyle(
                                //fontSize: largoActual * 0.024,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Nacimiento',
                                // hintText: 'Ingrese sus apellidos',
                                isDense: true,
                                labelStyle: TextStyle(
                                  // fontSize: largoActual * 0.02,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 1, 55, 99),
                                ),
                                hintStyle: TextStyle(
                                  //  fontSize: largoActual * 0.018,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _usuario,
                              decoration: InputDecoration(labelText: 'Usuario'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese un usuario';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _contrasena,
                              decoration:
                                  InputDecoration(labelText: 'Contraseña'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingrese una contraseña';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _email,
                              decoration: InputDecoration(labelText: 'E-mail'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 7,
                          margin: const EdgeInsets.only(top: 20),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return const AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(
                                            backgroundColor: Colors.green,
                                          ),
                                          SizedBox(width: 20),
                                          Text("Cargando..."),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                try {
                                  await createEmpleado(
                                      _nombre.text,
                                      _apellidos.text,
                                      _dni.text,
                                      _fechanacimiento.text,
                                      _usuario.text,
                                      _contrasena.text,
                                      _email.text);
                                  Navigator.of(context).pop();

                                  if (status == 200) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const AlertDialog(
                                          content: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(width: 20),
                                              Text(
                                                "Usuario Empleado Creado!",
                                                style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 16),
                                              ),
                                              Icon(
                                                Icons.check,
                                                size: 30,
                                                color: Colors.green,
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                    _nombre.clear();
                                    _apellidos.clear();
                                    _dni.clear();
                                    _fechanacimiento.clear();
                                    _usuario.clear();
                                    _contrasena.clear();
                                    _email.clear();
                                    //_formKey.currentState!.reset();
                                    setState(() {});
                                    await getEmpleado();
                                  } else if (status == 409) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const AlertDialog(
                                          content: Row(
                                            children: [
                                              SizedBox(width: 20),
                                              Text(
                                                "Usuario ya existe. Intente otro por favor.",
                                                style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 11, 48, 79),
                                                    fontSize: 20),
                                              ),
                                              Icon(
                                                Icons.cancel,
                                                size: 30,
                                                color: Color.fromARGB(
                                                    255, 29, 78, 119),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                } catch (e) {
                                  throw Exception('$e');
                                }
                              }
                            },
                            child: Text(
                              "Crear Empleado",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.blue)),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 7,
                          margin: const EdgeInsets.only(top: 20),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return const AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(
                                            backgroundColor: Colors.green,
                                          ),
                                          SizedBox(width: 20),
                                          Text("Cargando..."),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                try {
                                  await createConductor(
                                      _nombre.text,
                                      _apellidos.text,
                                      _dni.text,
                                      _fechanacimiento.text,
                                      _usuario.text,
                                      _contrasena.text,
                                      _email.text);
                                  Navigator.of(context).pop();

                                  if (status == 200) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const AlertDialog(
                                          content: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(width: 20),
                                              Text(
                                                "Usuario Conductor Creado!",
                                                style: TextStyle(
                                                    color: Colors.orange,
                                                    fontSize: 16),
                                              ),
                                              Icon(
                                                Icons.check,
                                                size: 30,
                                                color: Colors.green,
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                    _nombre.clear();
                                    _apellidos.clear();
                                    _dni.clear();
                                    _fechanacimiento.clear();
                                    _usuario.clear();
                                    _contrasena.clear();
                                    _email.clear();
                                    //_formKey.currentState!.reset();
                                    setState(() {});
                                    await getConductores();
                                  } else if (status == 409) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const AlertDialog(
                                          content: Row(
                                            children: [
                                              SizedBox(width: 20),
                                              Text(
                                                "Usuario ya existe. Intente otro por favor.",
                                                style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 11, 48, 79),
                                                    fontSize: 20),
                                              ),
                                              Icon(
                                                Icons.cancel,
                                                size: 30,
                                                color: Color.fromARGB(
                                                    255, 29, 78, 119),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                } catch (e) {
                                  throw Exception('$e');
                                }
                              }
                            },
                            child: Text(
                              "Crear Conductor",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.amber)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                width: MediaQuery.of(context).size.width / 3.5,
                height: MediaQuery.of(context).size.height / 1.1,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 5,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Text(
                          "Empleados",
                          style: TextStyle(fontSize: 28, color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      width: 500,
                      height: MediaQuery.of(context).size.height / 1.5,
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(20)),
                      child: ListView.builder(
                        itemCount: empleados.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(top: 20),
                            height: MediaQuery.of(context).size.height / 6,
                            width: 150,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(left: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ID USER: ${empleados[index].usuario_id}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        "Nombre: ${empleados[index].nombres}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        "Apellidos: ${empleados[index].apellidos}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        "usuario: ${empleados[index].nickname}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                    height: 50,
                                    width: 130,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Color.fromARGB(255, 86, 41, 94)),
                                    margin: const EdgeInsets.only(right: 20),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await deleteEmpleado(
                                            empleados[index].usuario_id);
                                        setState(() {});
                                        await getEmpleado();
                                      },
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Colors.blue)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Borrar",
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white),
                                          ),
                                          Icon(Icons.delete)
                                        ],
                                      ),
                                    ))
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 20, top: 20, right: 0),
                width: MediaQuery.of(context).size.width / 3.5,
                height: MediaQuery.of(context).size.height / 1.1,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 5,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Text(
                          "Conductores",
                          style: TextStyle(fontSize: 28, color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      width: 500,
                      height: MediaQuery.of(context).size.height / 1.5,
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(20)),
                      child: ListView.builder(
                        itemCount: conductores.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(top: 20),
                            height: MediaQuery.of(context).size.height / 6,
                            width: 150,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(left: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ID usuario: ${conductores[index].usuario_id}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        "Nombres: ${conductores[index].nombres}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        "Apellidos: ${conductores[index].apellidos}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        "Usuario: ${conductores[index].nickname}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                    height: 50,
                                    width: 130,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Color.fromARGB(255, 86, 41, 94)),
                                    margin: const EdgeInsets.only(right: 20),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await deleteConductor(
                                            conductores[index].usuario_id);
                                        setState(() {});
                                        await getConductores();
                                      },
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Colors.amber)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Borrar",
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white),
                                          ),
                                          Icon(Icons.delete)
                                        ],
                                      ),
                                    ))
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
