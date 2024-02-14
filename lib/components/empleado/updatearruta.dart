import 'package:desktopapp/components/empleado/armadodo2.dart';
import 'package:desktopapp/components/empleado/colores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/retry.dart';
import 'package:latlong2/latlong.dart';

import 'package:windows_notification/windows_notification.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;

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

  final double? latitud;
  final double? longitud;
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
  // List<Pedido>pedidos; // LISTA DE PEDIDOS

  bool seleccionado; // Nuevo campo para rastrear la selección

  Conductor(
      {required this.id,
      required this.nombres,
      required this.apellidos,
      required this.licencia,
      required this.dni,
      required this.fecha_nacimiento,
      //  this.pedidos = const [],
      this.seleccionado = false});
}

class Update extends StatefulWidget {
  const Update({Key? key}) : super(key: key);

  @override
  State<Update> createState() => _UpdateState();
}

class _UpdateState extends State<Update> {
  // List<Pedido> pedidosget = [];
  List<Conductor> conductorget = [];
  late io.Socket socket;
  DateTime now = DateTime.now();
  ScrollController _scrollController2 = ScrollController(); //HOY
  ScrollController _scrollController3 = ScrollController();

  LatLng currentLcocation = LatLng(0, 0);

  //List<LatLng> puntosget = [];
  List<LatLng> puntosnormal = [];
  List<LatLng> puntosexpress = [];

  // MARCADORES
  // List<Marker> marcadores = [];
  List<Marker> expressmarker = [];
  List<Marker> normalmarker = [];

  List<Pedido> hoypedidos = [];
  List<Pedido> hoyexpress = [];
  List<Pedido> agendados = [];

  List<Pedido> pedidoSeleccionado = [];

  @override
  void initState() {
    super.initState();
    initAsync();
    /* getConductores();
    connectToServer();
    getPedidosXConductor();*/
  }

  Future<void> initAsync() async {
    connectToServer();
    await getConductores(); // Esperar a que se completen las operaciones asíncronas

    getPedidosXConductor();
  }

  void getPedidosXConductor() async {
    print("-------gettt----------");
    print(conductorget.length);
    for (var i = 0; i < conductorget.length; i++) {
      mapaConductorXPedido[conductorget[i]] =
          await obtenerPedidosPorConductor(conductorget[i].id);
      print(mapaConductorXPedido[conductorget[i]]);
    }
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

  void marcadoresPut(tipo) {
    if (tipo == 'normal') {
      for (LatLng coordenadas in puntosnormal) {
        print("----puntos normal-------");
        //print(puntosget);
        print(puntosnormal.length);

        setState(() {
          normalmarker.add(
            Marker(
              point: coordenadas,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  print("SELECCIONADO: ${coordenadas}");

                  // Buscar el pedido correspondiente a las coordenadas
                  Pedido pedidoEncontrado = hoypedidos.firstWhere(
                    (pedido) =>
                        _isCoordenadaIgual(
                            pedido.latitud ?? 0.0, coordenadas.latitude) &&
                        _isCoordenadaIgual(
                            pedido.longitud ?? 0.0, coordenadas.longitude),
                    orElse: () => Pedido(
                        id: 0,
                        subtotal: 0.0,
                        descuento: 0.0,
                        total: 0.0,
                        fecha: '',
                        tipo: '',
                        estado: '',
                        latitud: 0.0,
                        longitud: 0.0,
                        nombre: '',
                        apellidos: '',
                        telefono:
                            ''), // Valor predeterminado si no se encuentra
                  );
                  print("encontrado");
                  print(pedidoEncontrado);

                  // Verificar que se encontró un pedido antes de agregarlo

                  // ignore: unnecessary_null_comparison
                  if (pedidoEncontrado != null) {
                    print("pedido encontrado");
                    print(pedidoEncontrado);
                    setState(() {
                      pedidoSeleccionado.add(pedidoEncontrado);
                      pedidoEncontrado.estado = 'en proceso';
                    });

                    //  getUbicacionSeleccionada();
                  }
                  setState(() {});
                },
                child: Container(
                    //color: sinSeleccionar,
                    height: 60,
                    width: 60,
                    child: Image.asset(
                        'lib/imagenes/azul.png') /*Icon(Icons.location_on_outlined,
              size: 40,color: Colors.blueAccent,)*/
                    ),
              ),
            ),
          );
        });
      }
    } else if (tipo == 'express') {
      for (LatLng coordenadas in puntosexpress) {
        print("----puntos express-------");
        //print(puntosget);
        print("tamaño de puntos express");
        print(puntosexpress.length);

        setState(() {
          expressmarker.add(
            Marker(
              point: coordenadas,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  print("SELECCIONADO: ${coordenadas}");

                  // Buscar el pedido correspondiente a las coordenadas
                  Pedido pedidoEncontradoExpress = hoyexpress.firstWhere(
                    (pedido) =>
                        _isCoordenadaIgual(
                            pedido.latitud ?? 0.0, coordenadas.latitude) &&
                        _isCoordenadaIgual(
                            pedido.longitud ?? 0.0, coordenadas.longitude),
                    orElse: () => Pedido(
                        id: 0,
                        subtotal: 0.0,
                        descuento: 0.0,
                        total: 0.0,
                        fecha: '',
                        tipo: '',
                        estado: '',
                        latitud: 0.0,
                        longitud: 0.0,
                        nombre: '',
                        apellidos: '',
                        telefono:
                            ''), // Valor predeterminado si no se encuentra
                  );
                  print("encontrado");
                  print(pedidoEncontradoExpress);

                  // Verificar que se encontró un pedido antes de agregarlo

                  // ignore: unnecessary_null_comparison
                  if (pedidoEncontradoExpress != null) {
                    setState(() {
                      //  seleccionadosUbicaciones.add(coordenadas);
                      pedidoSeleccionado.add(pedidoEncontradoExpress);
                      pedidoEncontradoExpress.estado = 'en proceso';
                    });

                    //  getUbicacionSeleccionada();
                  }
                },
                child: Container(
                    //color: sinSeleccionar,
                    height: 80,
                    width: 40,
                    child: Image.asset(
                        'lib/imagenes/amber.png') /*Icon(Icons.location_on_outlined,
              size: 40,color: Colors.blueAccent,)*/
                    ),
              ),
            ),
          );
        });
      }
    }

    // print("seUbica");
    // print(seleccionadosUbicaciones);
    print("Pedido seleccionado");
    print(pedidoSeleccionado);
  }

  // WEB SOCKET
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

    // CREATE PEDIDO WS://API/PRODUCTS
    socket.on('nuevoPedido', (data) {
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

              /// SERA NECESARIO APLICAR LA LOGICA EN ESTA VISTA????????????????????????????
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
    });

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

  final _winNotifyPlugin = WindowsNotification(
    applicationId:
        r"{D65231B0-B2F1-4857-A4CE-A8E7C6EA7D27}\WindowsPowerShell\v1.0\powershell.exe",
  );

  Future<String> getImageBytes(String assetPath) async {
    final supportDir = await getApplicationSupportDirectory();
    final bytes = await rootBundle.load(assetPath);
    final imageFile =
        File("${supportDir.path}/${DateTime.now().millisecond}.png");
    await imageFile.create();
    await imageFile.writeAsBytes(bytes.buffer.asUint8List());
    return imageFile.path;
  }

  var numero = 9.9090;
  String api = dotenv.env['API_URL'] ?? '';
  String conductores = '/api/user_conductor';
  String pedidosConductor = '/api/conductorPedidos/';

  List<Conductor> obtenerConductor = [];
  int conductorid = 0;
  List<Pedido> pedidosXConductor = [];
  Map<Conductor, List<Pedido>> mapaConductorXPedido = {};

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
        print("--------------");
        print(conductorget);
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<dynamic> obtenerPedidosPorConductor(int idConductor) async {
    print("-{------------}");
    var res = await http.get(
      Uri.parse(api + pedidosConductor + idConductor.toString()),
      headers: {"Content-type": "application/json"},
    );
    try {
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
        return tempPedido;
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                      ...normalmarker,
                      ...expressmarker,
                    ],
                  ),
                ],
              ),

              // CONDUCTORES
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                    margin: const EdgeInsets.only(right: 20),
                    width: MediaQuery.of(context).size.width / 5,
                    height: MediaQuery.of(context).size.height,
                    //color: Colors.amber,
                    child: ListView.builder(
                        itemCount: conductorget.length,
                        itemBuilder: (context, index1) {
                          /// LISTVIEW PRINCIPAL

                          return Container(
                              margin: const EdgeInsets.only(top: 10, right: 20),
                              height: 550,
                              decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Column(
                                children: [
                                  ListTile(
                                    trailing: Checkbox(
                                      value: conductorget[index1].seleccionado,
                                      onChanged: (value) {
                                        setState(() {
                                          conductorget[index1].seleccionado =
                                              value ?? false;
                                          obtenerConductor = conductorget
                                              .where((element) =>
                                                  element.seleccionado)
                                              .toList();
                                          if (value == true) {
                                            setState(() {
                                              conductorid =
                                                  conductorget[index1].id;
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
                                          "Conductor : N° ${conductorget[index1].id}",
                                          style: TextStyle(
                                              color: containerColors[index1 %
                                                  containerColors.length],

                                              /// containerColors[index % containerColors.length],
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "Nombre:${conductorget[index1].nombres}",
                                          style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w400),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 350,
                                    child: ListView.builder(
                                        itemCount: mapaConductorXPedido[
                                                conductorget[index1]]
                                            ?.length ?? 0, // conductormatriz[index1].length
                                        itemBuilder: (context, index2) {
                                          // LISTVIEW SECUNDARIO
                                          return Container(
                                            margin:
                                                const EdgeInsets.only(top: 3),
                                            padding: const EdgeInsets.all(9),
                                            color: Colors.white,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                    "Pedido N° ${mapaConductorXPedido[conductorget[index1]]?[index2].id}"),
                                                Text(
                                                    "Estado:  ${mapaConductorXPedido[conductorget[index1]]?[index2].estado}")
                                              ],
                                            ),
                                          );
                                        }),
                                  )
                                ],
                              ) /*,*/
                              );
                        })),
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

              // BOTON SISTEMA DE PEDIDO
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Armado2()));
                    },
                    child: Text(
                      "<< Sistema de Armado",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          const Color.fromARGB(255, 1, 33, 60)
                              .withOpacity(0.8)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
