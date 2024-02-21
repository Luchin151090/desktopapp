import 'dart:math';
import 'dart:typed_data';

import 'package:desktopapp/components/empleado/armadodo2.dart';
import 'package:desktopapp/components/empleado/colores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:lottie/lottie.dart' as lottie;

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
  int? ruta;
  // List<Pedido>pedidos; // LISTA DE PEDIDOS

  bool seleccionado; // Nuevo campo para rastrear la selección

  Conductor(
      {required this.id,
      required this.nombres,
      required this.apellidos,
      required this.licencia,
      required this.dni,
      required this.fecha_nacimiento,
      required this.ruta,
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
  String api = dotenv.env['API_URL'] ?? '';
  String apipedidos = '/api/pedido';
  double latitudtemp = 0.0;
  double longitudtemp = 0.0;
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

  List<Pedido> pedidosget = [];
  List<LatLng> puntosget = [];

  late DateTime fechaparseadas;

  String conductoresRuta = '/api/conductor_ruta';
  String pedidosConductor = '/api/conductorPedidos/';
  String updatePedidoRuta = '/api/pedidoruta/';

  List<Conductor> obtenerConductor = [];
  int conductorid = 0;
  List<Pedido> pedidosXConductor = [];
  Map<Conductor, List<Pedido>> mapaConductorXPedido = {};

  List<Marker> marcadorAsignado = [];

  // TEXTCONTROLLER
  TextEditingController _ruta = TextEditingController();

  @override
  void initState() {
    super.initState();

    //getConductores();
    initAsync();
    /* getConductores();
    connectToServer();
    getPedidosXConductor();*/
  }

  Future<void> initAsync() async {
    await getConductores(); // Esperar a que se completen las operaciones asíncronas
    connectToServer();
    getPedidos();
    getPedidosXConductor();
  }

  void getPedidosXConductor() async {
    print("-------gettt----------");
    print(conductorget.length);
    List<LatLng> puntosxconductor = [];
    List<Pedido> iterarPedido = [];
    for (var i = 0; i < conductorget.length; i++) {
      List<Pedido> pedidostemp =
          await obtenerPedidosPorConductor(conductorget[i].id);
      setState(() {
        mapaConductorXPedido[conductorget[i]] = pedidostemp;
        iterarPedido = pedidostemp;
      });

      print(mapaConductorXPedido[conductorget[i]]);

      // mostrar el conjunto de asignados x conductor
    }

    for (var k = 0; k < conductorget.length; k++) {
      int count = 1;
      for (var i = 0; i < iterarPedido.length; i++) {
        puntosxconductor.add(LatLng(
            (iterarPedido[i].latitud ?? 0.0) + (count * 0.003),
            (iterarPedido[i].longitud ?? 0.0) + (count * 0.002)));
        marcadorAsignado.add(Marker(
            height: 70,
            width: 70,
            point: puntosxconductor[i],
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: iterarPedido[i].estado == 'en proceso'
                      ? containerColors[k % containerColors.length]
                      : iterarPedido[i].estado == 'entregado'
                          ? Colors.grey
                          : iterarPedido[i].estado == 'truncado'
                              ? Colors.red
                              : Colors.black,
                  border: Border.all(width: 2.5, color: Colors.white)),
              child: Center(
                  child: Text(
                "$count",
                style: TextStyle(fontSize: 28, color: Colors.white),
              )),
            )));
        count++;
      }
    }
  }

  void marcadoresPut(tipo) {
    if (tipo == 'normal') {
      int count = 1;

      print("----puntos normal-------");

      // AQUI ITERA LAS COORDENADAS DE LA LISTA PUNTOSNORMAL
      // PARA QUE POR CADA ITERACION MUESTRE UN MARCADOR

      final Map<LatLng, Pedido> mapaLatPedido = {};

      for (var i = 0; i < puntosnormal.length; i++) {
        double offset = count * 0.000001;
        LatLng coordenada = puntosnormal[i];
        Pedido pedido = hoypedidos[i];

        mapaLatPedido[LatLng(coordenada.latitude, coordenada.longitude)] =
            pedido;

        print("${coordenada.latitude} - ${coordenada.longitude}");
        normalmarker.add(
          Marker(
            // LE AÑADO MAS TOLERANCIA PARA QUE SEA VISIBLE

            point: LatLng(coordenada.latitude, coordenada.longitude),
            width: 200,
            height: 200,
            child: GestureDetector(
              onTap: () {
                print(mapaLatPedido[
                        LatLng(coordenada.latitude, coordenada.longitude)]
                    ?.id);
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
                  //color: sinSeleccionar,
                  height: 90,
                  width: 90,
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.white,
                            border: Border.all(width: 3, color: const Color.fromARGB(255, 19, 72, 115))),
                        child: Center(
                            child: Text(
                          "${count}",
                          style: const TextStyle(
                              fontSize: 19,
                              color: Colors.black,
                              fontWeight: FontWeight.w600),
                        )),
                      ),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                                image: AssetImage('lib/imagenes/bluefinal.png'))),
                      ),
                    ],
                  ) /*Icon(Icons.location_on_outlined,
              size: 40,color: Colors.blueAccent,)*/
                  ),
            ),
          ),
        );

        count++;
      }
      print("Pedido seleccionado");
      print(pedidoSeleccionado);
    } else if (tipo == 'express') {
      int count = 1;
      print("----puntos express-------");

      final Map<LatLng, Pedido> mapaLatPedidox = {};

      for (var i = 0; i < puntosexpress.length; i++) {
        double offset = count * 0.000001;
        LatLng coordenadax = puntosexpress[i];
        Pedido pedidox = hoyexpress[i];

        mapaLatPedidox[LatLng(coordenadax.latitude, coordenadax.longitude)] =
            pedidox;

        setState(() {
          expressmarker.add(
            Marker(
              point: LatLng(coordenadax.latitude + offset,
                  coordenadax.longitude + offset),
              width: 200,
              height: 200,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    mapaLatPedidox[
                            LatLng(coordenadax.latitude, coordenadax.longitude)]
                        ?.estado = 'en proceso';
                    Pedido? pedidoencontradox = mapaLatPedidox[
                        LatLng(coordenadax.latitude, coordenadax.longitude)];
                    pedidoSeleccionado.add(pedidoencontradox!);
                  });
                },
                child: Container(
                    //color: sinSeleccionar,
                    height: 90,
                    width: 90,
                    child: Column(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.white.withOpacity(0.5),
                              border:
                                  Border.all(width: 3, color: const Color.fromARGB(255, 116, 92, 23))),
                          child: Center(
                              child: Text(
                            "${count}",
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          )),
                        ),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                  image: AssetImage('lib/imagenes/amberfinal.png'))),
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
              if (pedidosget[i].tipo == 'normal') {
                // SI ES NORMAL
                if (fechaparseadas.year == now.year &&
                    fechaparseadas.month == now.month &&
                    fechaparseadas.day == now.day) {
                  if (fechaparseadas.hour < 13) {
                    setState(() {
                      latitudtemp =
                          (pedidosget[i].latitud ?? 0.0) + (0.000001 * count);
                      longitudtemp =
                          (pedidosget[i].longitud ?? 0.0) + (0.000001 * count);
                      LatLng tempcoord = LatLng(latitudtemp, longitudtemp);
                      // SETEANDO PUNTOS NORMAL

                      puntosnormal.add(tempcoord);

                      pedidosget[i].latitud = latitudtemp;
                      pedidosget[i].longitud = longitudtemp;
                      hoypedidos.add(pedidosget[i]);
                    });
                    setState(() {
                      // ACTUALIZAMOS LA VISTA
                    });
                  }
                }
              } else if (pedidosget[i].tipo == 'express') {
                setState(() {
                  latitudtemp =
                      (pedidosget[i].latitud ?? 0.0) + (0.000001 * count);
                  longitudtemp =
                      (pedidosget[i].longitud ?? 0.0) + (0.000001 * count);
                  LatLng tempcoordexpress = LatLng(latitudtemp, longitudtemp);
                  // OBTENER COORDENADAS DE LOS EXPRESS

                  puntosexpress.add(tempcoordexpress);

                  pedidosget[i].latitud = latitudtemp;
                  pedidosget[i].longitud = longitudtemp;
                  hoyexpress.add(pedidosget[i]);
                });
                setState(() {
                  // ACTUALIZAMOS LA VISTA
                });
              }
            }
            setState(() {});
            count++;
          }
        });
        marcadoresPut("normal");
        setState(() {
          // ACTUALIZAMOS LA VISTA
        });
        marcadoresPut("express");
        setState(() {
          // ACTUALIZAMOS LA VISTA
        });

        // OBTENER COORDENADAS DE LOS PEDIDOS
        // for (var i = 0; i < pedidosget.length; i++) {}
        print("PUNTOS GET");
        print(puntosget);
      }
    } catch (e) {
      throw Exception('Error $e');
    }
  }

  Future<dynamic> updatePedido(int idpedido, int rutaid) async {
    print("$idpedido");
    print("$rutaid");
    if (idpedido != 0) {
      print("---------update");
      print("$idpedido");
      print("$rutaid");

      try {
        await http.put(Uri.parse(api + updatePedidoRuta + idpedido.toString()),
            headers: {"Content-type": "application/json"},
            body: jsonEncode({"ruta_id": rutaid, "estado": "en proceso"}));
      } catch (e) {
        throw Exception('$e');
      }
    } else {
      print("$idpedido");
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
              if (fechaparseada.hour < 19) {
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
            } /*else {
              agendados.add(nuevoPedido);
            }*/
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

  Future<dynamic> getConductores() async {
    try {
      var res = await http.get(Uri.parse(api + conductoresRuta),
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
              fecha_nacimiento: data['fecha_nacimiento'],
              ruta: data['ruta']);
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
                  initialZoom: 14.0,
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
                      ...marcadorAsignado,
                    ],
                  ),
                ],
              ),

              // CONDUCTORES
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 20),
                    width: MediaQuery.of(context).size.width / 8,
                    height: MediaQuery.of(context).size.height > 793 ? 700 :
                      MediaQuery.of(context).size.height<= 793  ? 500 : 0,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: ListView.builder(
                        itemCount: conductorget.length,
                        itemBuilder: (context, index1) {
                          /// LISTVIEW PRINCIPAL

                          return Container(
                              margin: const EdgeInsets.only(top: 10, right: 20),
                              padding: const EdgeInsets.all(5),
                              height: 500,
                              decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 58, 108, 149)
                                      .withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white),
                                    child: Text(
                                      "Conductor N° ${conductorget[index1].id}",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: containerColors[
                                            index1 % containerColors.length],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 5),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white),
                                    child: Text(
                                      "Ruta N° ${conductorget[index1].ruta}",
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    height: 280,
                                    child: ListView.builder(
                                        itemCount: mapaConductorXPedido[
                                                    conductorget[index1]]
                                                ?.length ??
                                            0, // conductormatriz[index1].length
                                        itemBuilder: (context, index2) {
                                          // LISTVIEW SECUNDARIO
                                          return Container(
                                            margin:
                                                const EdgeInsets.only(top: 3),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                                color: mapaConductorXPedido[
                                                                    conductorget[
                                                                        index1]]
                                                                ?[index2]
                                                            .estado ==
                                                        'en proceso'
                                                    ? const Color.fromARGB(
                                                        255, 67, 77, 129)
                                                    : mapaConductorXPedido[conductorget[index1]]
                                                                    ?[index2]
                                                                .estado ==
                                                            'entregado'
                                                        ? Colors.grey
                                                        : mapaConductorXPedido[conductorget[index1]]
                                                                        ?[
                                                                        index2]
                                                                    .estado ==
                                                                'truncado'
                                                            ? Colors.red
                                                            : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Pedido N° ${mapaConductorXPedido[conductorget[index1]]?[index2].id}",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Text(
                                                    "Estado: ${mapaConductorXPedido[conductorget[index1]]?[index2].estado}",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        "Nombre: ${mapaConductorXPedido[conductorget[index1]]?[index2].nombre}",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                    Text(
                                                        "Teléfono: ${mapaConductorXPedido[conductorget[index1]]?[index2].telefono}",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                )
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
                     color: Colors.white
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
                    color: Colors.white
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
                                color: Color.fromARGB(255, 58, 108, 149)
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
                          const Color.fromARGB(255, 58, 108, 149)
                              .withOpacity(0.8)),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 280,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  height: 250,
                  width: 200,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                          width: 180,
                          height: 50,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Color.fromARGB(255, 58, 108, 149)
                              ),
                          child: Center(
                            child: Text("Asignar Ruta",style: TextStyle(color: Colors.white,fontSize: 24),))),
                      Container(
                        height: 70,
                        width: 100,
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 230, 229, 229),
                            borderRadius: BorderRadius.circular(10)),
                        child: TextField(
                          controller: _ruta,
                          showCursor: false,
                          style: TextStyle(fontSize: 40),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 100,
                        child: ElevatedButton(
                            onPressed: () async {
                              print("...ruteandoo....");
                              if (_ruta.text.isNotEmpty &&
                                  pedidoSeleccionado.isNotEmpty) {
                                for (var i = 0;
                                    i < pedidoSeleccionado.length;
                                    i++) {
                                  setState(() {
                                    print(int.parse(_ruta.text));
                                    print("id pedido");
                                    print(pedidoSeleccionado[i].id);
                                    pedidoSeleccionado[i].ruta_id =
                                        int.parse(_ruta.text);
                                  });
                                  await updatePedido(pedidoSeleccionado[i].id,
                                      int.parse(_ruta.text));
                                }
                              }

                              setState(() {
                                // ACTUALIZAMOS LA VISTA
                                pedidoSeleccionado = [];
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Color.fromARGB(255, 58, 108, 149))
                            ),
                            child: Icon(Icons.check,color: Colors.white,)),
                      ),
                    ],
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
