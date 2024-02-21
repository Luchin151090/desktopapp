import 'dart:io';

import 'package:desktopapp/components/empleado/inicio.dart';
import 'package:desktopapp/components/empleado/updatearruta.dart';
import 'package:desktopapp/components/provider/ruta_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:provider/provider.dart';
import 'package:desktopapp/components/provider/user_provider.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

// AGENDADOS
class Pedido {
  final int id;
  int? ruta_id; // Puede ser nulo// Puede ser nulo
  final double subtotal; //
  final double descuento;
  final double total;

  final String fecha;
  final String tipo;
  String estado;
  String? observacion;

  double? latitud;
  double? longitud;
  String? distrito;

  // Atributos adicionales para el caso del GET
  final String nombre; //
  final String apellidos; //
  final String telefono; //

  bool seleccionado; // Nuevo campo para rastrear la selección

  Pedido(
      {required this.id,
      this.ruta_id,
      required this.subtotal,
      required this.descuento,
      required this.total,
      required this.fecha,
      required this.tipo,
      required this.estado,
      this.observacion,
      required this.latitud,
      required this.longitud,
      this.distrito,
      // Atributos adicionales para el caso del GET
      required this.nombre,
      required this.apellidos,
      required this.telefono,
      this.seleccionado = false});
}

// PREGUNTAR SI DEBO MODIFICAR EL MODEL CONDUCTOR AÑADIENDO UN ATRIBUTO
// ESTADO  O EN EL LOGIN PARA VER SI SE CONECTO EN TIEMPO REAL
class Conductor {
  final int id;
  final String nombres;
  final String apellidos;
  final String licencia;
  final String dni;
  final String fecha_nacimiento;

  bool seleccionado; // Nuevo campo para rastrear la selección

  Conductor(
      {required this.id,
      required this.nombres,
      required this.apellidos,
      required this.licencia,
      required this.dni,
      required this.fecha_nacimiento,
      this.seleccionado = false});
}

// CLASE PARA EL MARCADOR
class MarcadorWidget extends StatefulWidget {
  // ATRIBUTOS
  final Color color;

  // CONSTRUCTOR
  MarcadorWidget({required this.color, Key? key}) : super(key: key);

  @override
  _MarcadorWidgetState createState() => _MarcadorWidgetState();
}

class _MarcadorWidgetState extends State<MarcadorWidget> {
  late Color color;

  @override
  void initState() {
    super.initState();
    color = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    /*return Container(
      color: color,
      height: 40,
      width: 40,
    );*/
    return GestureDetector(
      onTap: () {
        setState(() {
          color = Colors.red;
          print("s");
        });
      },
      child: Container(
        color: color,
        height: 50,
        width: 50,
      ),
    );
  }
}

// --------------------------------------------------///

class Armado2 extends StatefulWidget {
  const Armado2({super.key});

  @override
  State<Armado2> createState() => _Armado2State();
}

class _Armado2State extends State<Armado2> {
  // CONTROLES DE DESPLAZAMIENTO
  ScrollController _scrollController1 = ScrollController(); //SELECCIONADOS
  ScrollController _scrollController2 = ScrollController(); //HOY
  ScrollController _scrollController3 = ScrollController(); //EXPRESS

  // URI API
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  String conductores = '/api/user_conductor';
  String rutacrear = '/api/ruta';
  String apiRutaCrear = '/api/ruta';
  String apiLastRuta = '/api/rutalast';
  String apiUpdateRuta = '/api/pedidoruta';
  late int rutaIdLast;
  late io.Socket socket;
  late DateTime fechaparseadas;
  DateTime now = DateTime.now();
  List<Pedido> hoypedidos = [];
  List<Pedido> hoyexpress = [];
  List<Pedido> agendados = [];
  ScrollController _scrollControllerExpress = ScrollController();
  late ScrollController _scrollController;

  //LISTAS Y VARIABLES
  List<Pedido> pedidosget = [];
  List<Conductor> conductorget = [];
  List<Pedido> pedidoSeleccionado = [];
  Color sinSeleccionar = Colors.green;
  List<LatLng> seleccionadosUbicaciones = [];
  List<Conductor> obtenerConductor = [];
  int conductorid = 0;

  LatLng currentLcocation = LatLng(0, 0);

  List<LatLng> puntosget = [];
  List<LatLng> puntosnormal = [];
  List<LatLng> puntosexpress = [];

  // MARCADORES
  List<Marker> marcadores = [];
  List<Marker> expressmarker = [];
  List<Marker> normalmarker = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final _winNotifyPlugin = WindowsNotification(
    applicationId:
        r"{D65231B0-B2F1-4857-A4CE-A8E7C6EA7D27}\WindowsPowerShell\v1.0\powershell.exe",
  );
  Map<LatLng, Color> coloreSeleccionados = {};

  void initState() {
    super.initState();
    connectToServer();
    getPedidos();
    getConductores();
    // marcadoresPut();
  }

  Future<String> getImageBytes(String assetPath) async {
    final supportDir = await getApplicationSupportDirectory();
    final bytes = await rootBundle.load(assetPath);
    final imageFile =
        File("${supportDir.path}/${DateTime.now().millisecond}.png");
    await imageFile.create();
    await imageFile.writeAsBytes(bytes.buffer.asUint8List());
    return imageFile.path;
  }

  Future<dynamic> refresh() async {
    setState(() {});
  }

  Future<dynamic> getConductores() async {
    try {
      var res = await http.get(Uri.parse(api + conductores),
          headers: {"Content-type": "application/json"});

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<Conductor> tempConductor = data.map<Conductor>((data) {
          return Conductor(
              id: data['id'],
              nombres: data['nombres'],
              apellidos: data['apellidos'],
              licencia: data['licencia'],
              dni: data['dni'],
              fecha_nacimiento: data['fecha_nacimiento']);
        }).toList();
        setState(() {
          conductorget = tempConductor;
        });
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  // POST RUTA
  Future<dynamic> createRuta(
      empleado_id, conductor_id, distancia, tiempo) async {
    await http.post(Uri.parse(api + apiRutaCrear),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({
          "conductor_id": conductor_id,
          "empleado_id": empleado_id,
          "distancia_km": distancia,
          "tiempo_ruta": tiempo
        }));
    print("Ruta creada");
  }

  // LAST RUTA BY EMPRLEADOID
  Future<dynamic> lastRutaEmpleado(empleadoId) async {
    var res = await http.get(
        Uri.parse(api + apiLastRuta + '/' + empleadoId.toString()),
        headers: {"Content-type": "application/json"});

    setState(() {
      rutaIdLast = json.decode(res.body)['id'] ?? 0;
    });
    print("LAST RUTA EMPLEAD");
    print(rutaIdLast);
  }

  // UPDATE PEDIDO-RUTA
  Future<dynamic> updatePedidoRuta(ruta_id, estado) async {
    for (var i = 0; i < pedidoSeleccionado.length; i++) {
      await http.put(
          Uri.parse(
              api + apiUpdateRuta + '/' + pedidoSeleccionado[i].id.toString()),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({"ruta_id": ruta_id, "estado": estado}));
    }
    print("RUTA ACTUALIZADA A ");
    print(ruta_id);

    //ALMACENO LA RUTA EN EL PROVIDER PARA ESE CONDUCTOR
    Provider.of<RutaProvider>(context, listen: false).updateUser(ruta_id);
  }

  // CREAR Y OBTENER
  Future<void> crearobtenerYactualizarRuta(
      empleadoId, conductorid, distancia, tiempo, estado) async {
    await createRuta(empleadoId, conductorid, distancia, tiempo);
    await lastRutaEmpleado(empleadoId);
    await updatePedidoRuta(rutaIdLast, estado);
    socket.emit('Termine de Updatear', 'si');
  }

  void getUbicacionSeleccionada() {
    print("ubicaciones seleccionadas");
    print(seleccionadosUbicaciones);
  }

// Función para comparar coordenadas con tolerancia
  bool _isCoordenadaIgual(double valor1, double valor2) {
    print("VALOR 1");
    print(valor1);
    print("VALOR 2");
    print(valor2);
    const tolerancia =
        0.0000000001; // Puedes ajustar la tolerancia según tus necesidades
    return (valor1 - valor2).abs() < tolerancia;
  }

  // FUNCIONES
  void marcadoresPut(tipo) {
    if (tipo == 'agendados') {
      int count = 1;

      final Map<LatLng, Pedido> mapaLatPedido = {};

      for (var i = 0; i < puntosget.length; i++) {
        print("---||||||||||||||||||||---");
        print(puntosget[i].latitude);
        print(puntosget[i].longitude);
        double offset = count * 0.000001;
        LatLng coordenada = puntosget[i];
        Pedido pedido = agendados[i];

        mapaLatPedido[LatLng(coordenada.latitude, coordenada.longitude)] =
            pedido;

        setState(() {
          marcadores.add(
            Marker(
              point: LatLng(
                  coordenada.latitude + offset, coordenada.longitude + offset),
              width: 140,
              height: 150,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    mapaLatPedido[
                            LatLng(coordenada.latitude, coordenada.longitude)]
                        ?.estado = 'en proceso';
                    Pedido? pedidoencontrado = mapaLatPedido[
                        LatLng(coordenada.latitude, coordenada.longitude)];
                    pedidoSeleccionado.add(pedidoencontrado!);
                  });
                },
                child: Container(
                    height: 155,
                    width: 140,
                    //color: Colors.grey,
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.white.withOpacity(0.5),
                              border:
                                  Border.all(width: 1, color: Colors.black)),
                          child: Center(
                              child: Text(
                            "${count}",
                            style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          )),
                        ),
                        Container(
                          //margin: const EdgeInsets.only(right: 20),
                          width: 94,
                          height: 94,
                          // color:Colors.blueGrey,
                          decoration: BoxDecoration(
                              // color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                  image:
                                      AssetImage('lib/imagenes/celeste.png'))),
                        ),
                      ],
                    ) /*Icon(Icons.location_on_outlined,
              size: 40,color: Colors.blueAccent,)*/
                    ),
              ),
            ),
          );
        });
        count++;
      }
    }
  }

  Future<dynamic> getPedidos() async {
    try {
      var res = await http.get(Uri.parse(api + apipedidos),
          headers: {"Content-type": "application/json"});
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<Pedido> tempPedido = data.map<Pedido>((data) {
          return Pedido(
              id: data['id'],
              ruta_id: data['ruta_id'] ?? 0,
              subtotal: data['subtotal']?.toDouble() ?? 0.0,
              descuento: data['descuento']?.toDouble() ?? 0.0,
              total: data['total']?.toDouble() ?? 0.0,
              fecha: data['fecha'],
              tipo: data['tipo'],
              estado: data['estado'],
              latitud: data['latitud']?.toDouble() ?? 0.0,
              longitud: data['longitud']?.toDouble() ?? 0.0,
              nombre: data['nombre'] ?? '',
              apellidos: data['apellidos'] ?? '',
              telefono: data['telefono'] ?? '');
        }).toList();

        setState(() {
          pedidosget = tempPedido;

          int count = 1;
          for (var i = 0; i < pedidosget.length; i++) {
            fechaparseadas = DateTime.parse(pedidosget[i].fecha.toString());
            if (pedidosget[i].estado == 'pendiente') {
              print("pendi...");
              if (pedidosget[i].tipo == 'normal') {
                print("normlllll");
                // SI ES NORMAL
                if (fechaparseadas.day != now.day) {
                  print("no es hoy");
                  print(fechaparseadas.day);

                  setState(() {
                    LatLng coordGET = LatLng(
                        (pedidosget[i].latitud ?? 0.0) + (0.000001 * count),
                        (pedidosget[i].longitud ?? 0.0) + (0.000001 * count));

                    puntosget.add(coordGET);
                    pedidosget[i].latitud = coordGET.latitude;
                    pedidosget[i].longitud = coordGET.longitude;

                    print("--get posss");
                    print(coordGET);
                    agendados.add(pedidosget[i]);
                  });
                }
              } else if (pedidosget[i].tipo == 'express') {
                hoyexpress.add(pedidosget[i]);
              }
            } else {
              setState(() {});
            }
            count++;
          }
        });

        // OBTENER COORDENADAS DE LOS PEDIDOS
        // for (var i = 0; i < pedidosget.length; i++) {}
        print("PUNTOS GET");
        print(puntosget);

        // PONER MARCADOR PARA AGENDADOS
        marcadoresPut("agendados");
        setState(() {});
      }
    } catch (e) {
      throw Exception('Error $e');
    }
  }

  void connectToServer() {
    print("-----CONEXIÓN------");

    socket = io.io(api, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnect': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Conexión establecida: EMPLEADO');
    });

    socket.onDisconnect((_) {
      print('Conexión desconectada: EMPLEADO');
    });

    socket.on('nuevoPedido', (data) async {
      String imagePath = await getImageBytes('lib/imagenes/azul.png');
      NotificationMessage message = NotificationMessage.fromPluginTemplate(
        "Pedido",
        " Llegó un pedido !",
        "${data['tipo']}",
        image: imagePath,
      );
      _winNotifyPlugin.showNotificationPluginTemplate(message);
    });
    // CREATE PEDIDO WS://API/PRODUCTS
    /* socket.on('nuevoPedido', (data) {
      print('Nuevo Pedido: $data');
      setState(() {
        print("DENTOR DE nuevoPèdido");
        DateTime fechaparseada = DateTime.parse(data['fecha'].toString());

        // CREADO POR EL SOCKET
        Pedido nuevoPedido = Pedido(
          id: data['id'],
          ruta_id: data['ruta_id'] ?? 0,
          nombre: data['nombre'] ?? '',
          apellidos: data['apellidos'] ?? '',
          telefono: data['telefono'] ?? '',
          latitud: data['latitud']?.toDouble() ?? 0.0,
          longitud: data['longitud']?.toDouble() ?? 0.0,
          distrito: data['distrito'],
          subtotal: data['subtotal']?.toDouble() ?? 0.0,
          descuento: data['descuento']?.toDouble() ?? 0.0,
          total: data['total']?.toDouble() ?? 0.0,
          observacion: data['observacion'],
          fecha: data['fecha'],
          tipo: data['tipo'],
          estado: data['estado'],
        );

        if (nuevoPedido.estado == 'pendiente') {
          print('esta pendiente');
          print(nuevoPedido);
          if (nuevoPedido.tipo == 'normal') {
            print('es normal');
            if (fechaparseada.year == now.year &&
                fechaparseada.month == now.month &&
                fechaparseada.day == now.day) {
              print("day");
              print(now.day);
              print("month");
              print(now.month);
              print("year");
              print(now.year);
              print("parse");
              print(fechaparseada.hour);
              if (fechaparseada.hour < 13) {
                print('es antes de la 1');
                hoypedidos.add(nuevoPedido);

                // OBTENER COORDENADAS DE LOS PEDIDOS

                LatLng tempcoord = LatLng(
                    nuevoPedido.latitud ?? 0.0, nuevoPedido.longitud ?? 0.0);
                setState(() {
                  puntosnormal.add(tempcoord);
                });
                marcadoresPut("normal");
                setState(() {
                  // ACTUALIZAMOS LA VISTA
                });
              }
            } else {
              agendados.add(nuevoPedido);
            }
          } else if (nuevoPedido.tipo == 'express') {
            print(nuevoPedido);

            hoyexpress.add(nuevoPedido);

            // OBTENER COORDENADAS DE LOS EXPRESS
            LatLng tempcoordexpress =
                LatLng(nuevoPedido.latitud ?? 0.0, nuevoPedido.longitud ?? 0.0);
            setState(() {
              puntosexpress.add(tempcoordexpress);
            });
            marcadoresPut("express");
            setState(() {
              // ACTUALIZAMOS LA VISTA
            });
          }
        }
        // SI EL PEDIDO TIENE FECHA DE HOY Y ES NORMAL
      });

      // Desplaza automáticamente hacia el último elemento
      _scrollController3.animateTo(
        _scrollController3.position.maxScrollExtent,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOutQuart,
      );

      _scrollController2.animateTo(
        _scrollController2.position.maxScrollExtent,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOutQuart,
      );
    });*/

    socket.onConnectError((error) {
      print("error de conexion $error");
    });

    socket.onError((error) {
      print("error de socket, $error");
    });

    socket.on('testy', (data) {
      print("CARRRR");
    });

    socket.on('enviandoCoordenadas', (data) {
      print("Conductor transmite:");
      print(data);
      setState(() {
        currentLcocation = LatLng(data['x'], data['y']);
      });
    });

    socket.on('vista', (data) async {
      print("...recibiendo..");
      //getPedidos();
      print(data);
      //socket.emit(await getPedidos());

      /*  try {
    List<Pedido> nuevosPedidos = List<Pedido>.from(data.map((pedidoData) => Pedido(
      id: pedidoData['id'],
      ruta_id: pedidoData['ruta_id'],
      cliente_id: pedidoData['cliente_id'],
      cliente_nr_id: pedidoData['cliente_nr_id'],
      monto_total: pedidoData['monto_total'],
      fecha: pedidoData['fecha'],
      tipo: pedidoData['tipo'],
      estado: pedidoData['estado'],
      seleccionado: false,
    )));

    setState(() {
      agendados = nuevosPedidos;
    });
  } catch (error) {
    print('Error al actualizar la vista: $error');
  }*/
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-16.4055657, -71.5719081),
                  initialZoom: 13.2,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      ...marcadores,
                      //...expressmarker,
                      // ...normalmarker,
                    ],
                  ),
                ],
              ),

              // AGENDADOS
              Positioned(
                top: MediaQuery.of(context).size.height / 9,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  width: 250,
                  height: MediaQuery.of(context).size.height / 1.2,
                  decoration: BoxDecoration(
                      //  color: Colors.white.withOpacity(0.7),
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      /*Text(
                        "${MediaQuery.of(context).size.width} x ${MediaQuery.of(context).size.height}",
                        style: TextStyle(
                            color: Colors.purple, fontWeight: FontWeight.bold),
                      ),*/
                      Text(
                        "Agendados: ${agendados.length}",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 6, 53, 91)),
                      ),
                      Container(
                        width: 300,
                        height: MediaQuery.of(context).size.height / 1.3,
                        //color: Colors.grey,
                        child: ListView.builder(
                            key: _listKey,
                            itemCount: agendados.length,
                            itemBuilder: ((context, index) {
                              return Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(6),
                                height: 180,
                                decoration: BoxDecoration(
                                    color:
                                        agendados[index].estado == 'pendiente'
                                            ? Color.fromARGB(255, 58, 108, 149)
                                            : Color.fromARGB(255, 12, 46, 14)
                                                .withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Pedido : N° ${agendados[index].id}",
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.normal)),
                                    Text("Cliente: ${agendados[index].nombre}",
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.normal)),
                                    Text(
                                        "Telefono:${agendados[index].telefono}",
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.normal)),
                                    Text("Monto: S/.${agendados[index].total}",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                        )),
                                    Text("Fecha: ${agendados[index].fecha}",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                        )),
                                    Text(
                                      "Estado: ${agendados[index].estado}",
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: agendados[index].estado ==
                                                  'pendiente'
                                              ? Color.fromARGB(
                                                  255, 186, 115, 135)
                                              : agendados[index].estado ==
                                                      'en proceso'
                                                  ? Colors.amber
                                                  : Colors.black,
                                          fontWeight: FontWeight.w700),
                                    )
                                  ],
                                ),
                              );
                            })),
                      ),
                    ],
                  ),
                ),
              ),

              // SISTEMA DE PEDIDO
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  // color: Colors.grey,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Inicio()));
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            const Color.fromARGB(255, 58, 108, 149)
                                .withOpacity(0.8))),
                    child: const Text(
                      "<< Sistema de Pedido",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              // SISTEMA DE SUPERVISIÓN
              Positioned(
                top: 10,
                left: 210,
                child: Container(
                  height: 50,
                  //color: Colors.grey,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Update()));
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            const Color.fromARGB(255, 58, 108, 149)
                                .withOpacity(0.8))),
                    child: const Text(
                      "Sistema de Supervisión >>",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              /*
              // HOY
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    //color: Colors.white
                  ),
                  // color: Color.fromARGB(255, 221, 214, 214),
                  //height: 180,
                  width: MediaQuery.of(context).size.width / 2.05,
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color.fromARGB(255, 2, 51, 92)
                                    .withOpacity(0.8)),
                            child: Text(
                              "Hoy: ${hoypedidos.length}",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            )),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          _scrollController3.jumpTo(
                              _scrollController3.position.pixels +
                                  details.primaryDelta!);
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController3,
                          scrollDirection: Axis.horizontal,
                          reverse: false,
                          child: Row(
                            children: List.generate(
                              hoypedidos.length,
                              (index) => Container(
                                margin: const EdgeInsets.only(left: 10),
                                padding: const EdgeInsets.all(8),
                                //color: Colors.purple,
                                child: Card(
                                  elevation: 8,
                                  borderOnForeground: true,
                                  color: hoypedidos[index].estado == 'pendiente'
                                      ? Color.fromARGB(255, 1, 44, 79)
                                          .withOpacity(0.75)
                                      : const Color.fromARGB(255, 15, 59, 16)
                                          .withOpacity(0.75),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Pedido : N° ${hoypedidos[index].id}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        Text(
                                          "Ruta N°:${hoypedidos[index].ruta_id}",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "Cliente:${hoypedidos[index].nombre}",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          "Telefono:${hoypedidos[index].telefono}",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          "Monto: S/.${hoypedidos[index].total}",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          "Fecha: ${hoypedidos[index].fecha}",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                            "Estado: ${hoypedidos[index].estado}",
                                            style: TextStyle(
                                              color: hoypedidos[index].estado ==
                                                      'pendiente'
                                                  ? Colors.white
                                                  : hoypedidos[index].estado ==
                                                          'en proceso'
                                                      ? Colors.amber
                                                      : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // EXPRESS
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    //color: Colors.white
                  ),
                  // color: Color.fromARGB(255, 221, 214, 214),
                  // height: 180,
                  width: MediaQuery.of(context).size.width / 2.05,
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              "Express: ${hoyexpress.length}",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color.fromARGB(255, 254, 254, 254),
                                  fontWeight: FontWeight.w500),
                            )),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          _scrollController2.jumpTo(
                              _scrollController2.position.pixels +
                                  details.primaryDelta!);
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController2,
                          scrollDirection: Axis.horizontal,
                          reverse: false,
                          child: Row(
                            children: List.generate(
                              hoyexpress.length,
                              (index) => Container(
                                margin: const EdgeInsets.only(left: 10),
                                padding: const EdgeInsets.all(8),
                                child: Card(
                                  elevation: 8,
                                  borderOnForeground: true,
                                  color: hoyexpress[index].estado == 'pendiente'
                                      ? Color.fromARGB(255, 246, 188, 15)
                                          .withOpacity(0.7)
                                      : Color.fromARGB(255, 18, 84, 20)
                                          .withOpacity(0.7),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Pedido : N° ${hoyexpress[index].id}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "Ruta N°:${hoyexpress[index].ruta_id}",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                            "Cliente:${hoyexpress[index].nombre}",
                                            style: TextStyle(
                                              color: Colors.white,
                                            )),
                                        Text(
                                            "Telefono:${hoyexpress[index].telefono}",
                                            style: TextStyle(
                                              color: Colors.white,
                                            )),
                                        Text(
                                            "Monto: S/.${hoyexpress[index].total}",
                                            style: TextStyle(
                                              color: Colors.white,
                                            )),
                                        Text(
                                            "Fecha: ${hoyexpress[index].fecha}",
                                            style: TextStyle(
                                              color: Colors.white,
                                            )),
                                        Text(
                                          "Estado: ${hoyexpress[index].estado}",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

                */

              // CONDUCTORES
              Positioned(
                top: MediaQuery.of(context).size.height / 8,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  width: 190,
                  height: MediaQuery.of(context).size.height / 1.2,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Text(
                        "Conductores: ${conductorget.length}",
                        style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 30, 63, 91),
                            fontWeight: FontWeight.w500),
                      ),
                      Container(
                        width: 195,
                        height: 500,
                        child: ListView.builder(
                            itemCount: conductorget.length,
                            itemBuilder: ((context, index) {
                              return Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  height: 100,
                                  decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 58, 108, 149),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: ListTile(
                                    trailing: Checkbox(
                                      checkColor: Colors.white,
                                      value: conductorget[index].seleccionado,
                                      onChanged: (value) {
                                        setState(() {
                                          conductorget[index].seleccionado =
                                              value ?? false;
                                          obtenerConductor = conductorget
                                              .where((element) =>
                                                  element.seleccionado)
                                              .toList();
                                          if (value == true) {
                                            setState(() {
                                              conductorid =
                                                  conductorget[index].id;
                                            });
                                            print("conductor id ");
                                            print(conductorid);
                                          }
                                        });
                                      },
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Conductor : N° ${conductorget[index].id}",
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.normal),
                                        ),
                                        Text(
                                          "Nombre: ${conductorget[index].nombres}",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ],
                                    ),
                                  ) /*,*/
                                  );
                            })),
                      ),
                    ],
                  ),
                ),
              ),

              // SELECCIONADOS
              Positioned(
                left: (MediaQuery.of(context).size.width - 500) / 2,
                height: 150,
                width: 500,
                child: Container(
                  padding: const EdgeInsets.all(5),

                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white),
                  // color: Color.fromARGB(255, 221, 214, 214),

                  child: Column(
                    children: [
                      Center(
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              "Seleccionados: ${pedidoSeleccionado.length}",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontWeight: FontWeight.w500),
                            )),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          _scrollController1.jumpTo(
                              _scrollController1.position.pixels +
                                  details.primaryDelta!);
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController1,
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            children: List.generate(
                              pedidoSeleccionado.length,
                              (index) => Container(
                                margin: const EdgeInsets.only(left: 10),
                                padding: const EdgeInsets.all(2),
                                //color: Colors.purple,
                                child: Card(
                                  elevation: 8,
                                  borderOnForeground: true,
                                  color: const Color.fromARGB(255, 58, 108, 149)
                                      .withOpacity(0.8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Pedido : N° ${pedidoSeleccionado[index].id}",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w300),
                                        ),
                                        Text(
                                            "Ruta: ${pedidoSeleccionado[index].ruta_id}",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w300))
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              for (var i = 0;
                                  i < pedidoSeleccionado.length;
                                  i++) {
                                pedidoSeleccionado[i].estado = 'pendiente';
                              }
                              pedidoSeleccionado = [];
                            });
                          },
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  Color.fromARGB(255, 58, 108, 149)
                                      .withOpacity(0.8))),
                          child: Text(
                            "Deshacer",
                            style: TextStyle(color: Colors.white),
                          ))
                    ],
                  ),
                ),
              ),

              // INFORME
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(100)),
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text(
                      "Informe",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Colors.amber.withOpacity(0.8))),
                  ),
                ),
              ),
              // CREAR
              Positioned(
                right: 110,
                top: 10,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(100)),
                  child: ElevatedButton(
                    onPressed: (pedidoSeleccionado.isNotEmpty &&
                            obtenerConductor.isNotEmpty)
                        ? () async {
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title:
                                    Center(child: const Text('¿ Crear ruta ?')),
                                actions: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // CANCELAR
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            for (var i = 0;
                                                i < pedidoSeleccionado.length;
                                                i++) {
                                              pedidoSeleccionado[i].estado =
                                                  'pendiente';
                                            }
                                            for (var i = 0;
                                                i < obtenerConductor.length;
                                                i++) {
                                              obtenerConductor[i].seleccionado =
                                                  false;
                                            }
                                            pedidoSeleccionado = [];
                                            obtenerConductor = [];
                                          });
                                          Navigator.pop(context, 'CANCELAR');
                                        },
                                        style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.amber)),
                                        child: const Text(
                                          'Cancelar',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),

                                      // CONFIRMAR
                                      ElevatedButton(
                                        onPressed: () async {
                                          // Muestra el indicador de progreso
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                          );

                                          print(obtenerConductor);
                                          await crearobtenerYactualizarRuta(
                                            userProvider.user?.id,
                                            conductorid,
                                            0,
                                            0,
                                            "en proceso",
                                          );

                                          for (var i = 0;
                                              i < obtenerConductor.length;
                                              i++) {
                                            setState(() {
                                              obtenerConductor[i].seleccionado =
                                                  false;
                                            });
                                          }

                                          // Limpiar y ocultar el indicador de progreso
                                          Navigator.pop(context);
                                          setState(() {
                                            pedidoSeleccionado = [];
                                            obtenerConductor = [];
                                          });

                                          // Actualizar la interfaz de usuario
                                          _listKey.currentState
                                              ?.setState(() {});

                                          Navigator.pop(context, 'CONFIRMAR');
                                          setState(() {});
                                        },
                                        style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    Color.fromARGB(
                                                        255, 58, 108, 149))),
                                        child: const Text(
                                          'Crear',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      "Crear",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        const Color.fromARGB(255, 58, 108, 149)
                            .withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
