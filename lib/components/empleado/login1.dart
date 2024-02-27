import 'package:desktopapp/components/empleado/crud.dart';
import 'package:desktopapp/components/model/user_model.dart';
import 'package:desktopapp/components/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:desktopapp/components/empleado/inicio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class Login1 extends StatefulWidget {
  const Login1({Key? key}) : super(key: key);
  @override
  State<Login1> createState() => _Login1State();
}

class _Login1State extends State<Login1> {
  // VARIABLES
  final TextEditingController _contrasena = TextEditingController();
  final TextEditingController _usuario = TextEditingController();
  String api = dotenv.env['API_URL'] ?? '';
  String login = '/api/login';
  late UserModel userData;
  late int status = 0;
  late int rol = 0;
  DateTime tiempo = DateTime.now();

  Future<dynamic> loginsol(username, password) async {
    try {
      var res = await http.post(Uri.parse(api+login),
          headers: {"Content-type": "application/json"},
          body: json.encode({
            "nickname": username,
             "contrasena": password
          }));
      print("RES.........");
      print(res.body);

      if(res.statusCode==200){
        var data = json.decode(res.body);
        //EMPLEADO
        if(data['usuario']['rol_id']==2){
          userData = UserModel(
            id: data['usuario']['id'] ?? 0,
           nombre: data['usuario']['nombres'] ?? '',
            apellidos: data['usuario']['apellidos'] ?? ''
            );
            setState(() {
              status=200;
              rol=2;
            });
                 print("STATUS");
           print(status);
           print("ROL");
           print(rol);
        }
        //ADMINISTRADOR
        else if(data['usuario']['rol_id']==1){
          userData=UserModel(
            id: data['usuario']['id'],
           nombre: data['usuario']['nombres'], 
           apellidos: data['usuario']['apellidos']);
           setState(() {
             status=200;
             rol=1;
           });
           print("STATUS");
           print(status);
           print("ROL");
           print(rol);
        }

        /// SETEAMOS EL PROVIDER CON UN USUARIO
        Provider.of<UserProvider>(context,listen: false).updateUser(userData);

      }
      else if(res.statusCode==401){
        var data = json.decode(res.body);
        print(data);
        setState(() {
          status=401;
        });
             print("STATUS");
           print(status);
           print("ROL");
           print(rol);

      }
      else if(res.statusCode==404){
        var data = json.decode(res.body);
        print(data);
        setState(() {
          status=404;
        });
             print("STATUS");
           print(status);
           print("ROL");
           print(rol);
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.amber,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('lib/imagenes/aguita.png'),
                  fit: BoxFit.fill)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 100),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    "Bienvenido",
                    style: TextStyle(
                        fontSize: 40, color: Color.fromARGB(255, 30, 30, 30)),
                  ),
                ),
                Container(
                  //color: Colors.grey,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white),
                  width: MediaQuery.of(context).size.width / 5,
                  margin: const EdgeInsets.only(top: 80),
                  child: TextField(
                    controller: _usuario,
                    decoration: const InputDecoration(
                      hintText: 'Usuario',
                    ),
                  ),
                ),
                Container(
                  //color: Colors.grey,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  width: MediaQuery.of(context).size.width / 5,
                  margin: const EdgeInsets.only(top: 80),
                  child: TextField(
                    controller: _contrasena,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Contraseña'),
                  ),
                ),
                Container(
                  //color: Colors.grey,
                  margin: const EdgeInsets.only(top: 20),
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "¿Olvidaste tu Contraseña?",
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                ),
                 Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(8),
                height: 60,
                width: MediaQuery.of(context).size.width / 5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)
                ),
                child: ElevatedButton(
                  onPressed: () async {
                   
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
                        await loginsol(_usuario.text, _contrasena.text);

                        if (status == 200) {
                         /* Navigator.of(context)
                              .pop(); */// Cerrar el primer AlertDialog
                          // EMPLEADO
                          if (rol == 2) {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Inicio()),
                            );
                          } 
                          // ADMINISTRADOR
                          else if (rol == 1) {
                              Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Crud()),
                            );
                          } 
                        } else if (status == 401) {
                          Navigator.of(context)
                              .pop(); // Cerrar el primer AlertDialog

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const AlertDialog(
                                content: Row(
                                  children: [
                                    SizedBox(width: 20),
                                    Text("Credenciales inválidas"),
                                  ],
                                ),
                              );
                            },
                          );
                        } else if (status == 404) {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const AlertDialog(
                                content: Row(
                                  children: [
                                    SizedBox(width: 20),
                                    Text("Usuario no existente"),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      } catch (e) {
                        print("Excepción durante el inicio de sesión: $e");
                      }
                    
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromARGB(255, 1, 61, 109)),
                  ),
                  child: const Text(
                    "Iniciar Sesión",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Text("COTECSA ${tiempo.year}",
                style: TextStyle(color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w500),),
              )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
