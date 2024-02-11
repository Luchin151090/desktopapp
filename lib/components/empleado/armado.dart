import 'package:desktopapp/components/empleado/inicio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart' as map;
import 'dart:async';
import 'package:desktopapp/components/empleado/vista.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

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

class Coordenadas<T1, T2> {
  final T1 latitud;
  final T2 longitud;

  Coordenadas({
    required this.latitud,
    required this.longitud,
  });
}

class Armado extends StatefulWidget {
  const Armado({super.key});

  @override
  State<Armado> createState() => _ArmadoState();
}

class _ArmadoState extends State<Armado> {
  LatLng currentLcocation = LatLng(0, 0);
  late ScrollController _scrollController; // = ScrollController();
  ScrollController _scrollControllerAgendados = ScrollController();
  ScrollController _scrollControllerExpress = ScrollController();
  ScrollController _scrollControllerSelection = ScrollController();
  late io.Socket socket;
  List<Pedido> hoypedidos = [];
  List<Pedido> hoyexpress = [];
  List<Pedido> agendados = [];
  List<Pedido> agendadosParaHoy = [];
  List<Pedido> obtenerPedidoSeleccionado = [];
  late int conductorid;
  late int rutaIdLast;
  List<Conductor> obtenerConductor = [];
  List<Conductor> conductores = [];
  List<Coordenadas> coordenadas = [];
  late DateTime fechaparseadas;
  DateTime now = DateTime.now();

  final List<LatLng> routePoints = [
    LatLng(-16.4055657, -71.5719081),
    LatLng(-16.4050152, -71.5705073),
    LatLng(-16.4022842, -71.5651442),
    LatLng(-16.4086712, -71.5579809),
  ];

  List<LatLng> multipuntos = [];

  var direccion = '';
  String api = dotenv.env['API_URL'] ?? '';
  String apiPedidos =
      '/api/pedido'; //'https://aguasolfinal-dev-qngg.2.us-1.fl0.io/api/pedido';
  String apiConductores =
      '/api/user_conductor'; // 'https://aguasolfinal-dev-qngg.2.us-1.fl0.io/api/user_conductor';
  String apiRutaCrear =
      '/api/ruta'; //'https://aguasolfinal-dev-qngg.2.us-1.fl0.io/api/ruta';
  String apiLastRuta =
      '/api/rutalast'; //'https://aguasolfinal-dev-qngg.2.us-1.fl0.io/api/rutalast';
  String apiUpdateRuta =
      '/api/pedidoruta'; //'https://aguasolfinal-dev-qngg.2.us-1.fl0.io/api/pedidoruta';
  final TextEditingController _searchController = TextEditingController();
  //final TextEditingController _distrito = TextEditingController();
  //final TextEditingController _ubicacion = TextEditingController();

  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    connectToServer();
    //Timer.periodic(const Duration(seconds: 0),(Timer timer) {
    getPedidos();
    // });

    getConductores();
  }

  void actualizarObtenidos() {
    setState(() {
      int contador = 0;

      obtenerPedidoSeleccionado = [...hoypedidos, ...hoyexpress, ...agendados]
          .where((element) => element.seleccionado)
          .toList();

      coordenadas = obtenerPedidoSeleccionado
          .where(
              (element) => element.latitud != null && element.longitud != null)
          .map((element) => Coordenadas(
              latitud: element.latitud!, longitud: element.longitud!))
          .toList();
      // LSITA DE COORDENADAS
      print("Coordenadas");
      print(coordenadas.length);
      if (coordenadas.length > 0) {
        for (var i = 0; i < coordenadas.length; i++) {
          print("${coordenadas[i].latitud},${coordenadas[i].longitud}");
          multipuntos
              .add(LatLng(coordenadas[i].latitud, coordenadas[i].longitud));
        }
      }

      for (LatLng coordinate in multipuntos) {
        markers.add(
          Marker(
            width: 50.0,
            height: 50.0,
            point: coordinate,
            child: Row(
              children: [
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      //color: Colors.green,
                      image: DecorationImage(
                          image: AssetImage('lib/imagenes/pocionverde.png'),
                          fit: BoxFit.fill)),
                ),
                Container(
                  child: Text(
                    "$contador",
                    style: TextStyle(
                        fontSize: 20,
                        color: Color.fromARGB(255, 72, 69, 152),
                        fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
          ),
        );
        contador++;
      }
    });
  }

  // POST RUTA
  Future<dynamic> createRuta(
      empleado_id, conductor_id, distancia, tiempo) async {
    await http.post(Uri.parse(api+apiRutaCrear),
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
        Uri.parse(api+apiLastRuta + '/' + empleadoId.toString()),
        headers: {"Content-type": "application/json"});

    setState(() {
      rutaIdLast = json.decode(res.body)['id'];
    });
    print("LAST RUTA EMPLEAD");
    print(rutaIdLast);
  }

  // UPDATE PEDIDO-RUTA
  Future<dynamic> updatePedidoRuta(ruta_id, estado) async {
    for (var i = 0; i < obtenerPedidoSeleccionado.length; i++) {
      await http.put(
          Uri.parse(api+apiUpdateRuta + '/' + obtenerPedidoSeleccionado[i].id.toString()),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({"ruta_id": ruta_id, "estado": estado}));
    }
    print("RUTA ACTUALIZADA A ");
    print(ruta_id);
  }

  // CREAR Y OBTENER
  Future<void> crearobtenerYactualizarRuta(
      empleadoId, conductorid, distancia, tiempo, estado) async {
    await createRuta(empleadoId, conductorid, distancia, tiempo);
    await lastRutaEmpleado(empleadoId);
    await updatePedidoRuta(rutaIdLast, estado);
    socket.emit('Termine de Updatear', 'si');
  }

  // GET CONDUCTORES
  Future<dynamic> getConductores() async {
    print(">>>>> CONDUCTORES");
    var res = await http.get(Uri.parse(api+apiConductores),
        headers: {"Content-type": "application/json"});
    try {
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
          conductores = tempConductor;
        });
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  // GET PEDIDOS
  Future<dynamic> getPedidos() async {
    print("1) Getpedidos");
    var res = await http.get(Uri.parse(api+apiPedidos),
        headers: {"Content-type": "application/json"});
    //timeout: Duration(seconds: 10);
    try {
      if (res.statusCode == 200) {
        var data = json.decode(res.body);

        List<Pedido> pedidos = data.map<Pedido>((data) {
          return Pedido(
            id: data['id'],
            ruta_id: data['ruta_id'] ?? 0,
            nombre: data['nombre'],
            apellidos: data['apellidos'],
            telefono: data['telefono'],
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
        }).toList();

        setState(() {
          // SI LOS PEDIDOS CON FECHA DE AYER,+
          for (var i = 0; i < pedidos.length; i++) {
            fechaparseadas = DateTime.parse(pedidos[i].fecha.toString());
            if (pedidos[i].estado == 'pendiente') {
              if (pedidos[i].tipo == 'normal') {
                if (fechaparseadas.year == now.year &&
                    fechaparseadas.month == now.month &&
                    fechaparseadas.day == now.day) {
                  if (fechaparseadas.hour < 13) {
                    hoypedidos.add(pedidos[i]);
                  }
                } else {
                  agendados.add(pedidos[i]);
                }
              } else if (pedidos[i].tipo == 'express') {
                hoyexpress.add(pedidos[i]);
              }
            }
          }

          print("--------AGENDADOS-----");
          print(agendados);
        });
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
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

        Pedido nuevoPedido = Pedido(
          id: data['id'],
          ruta_id: data['ruta_id'] ?? 0,
          nombre: data['nombre'],
          apellidos: data['apellidos'],
          telefono: data['telefono'],
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
              }
            } else {
              agendados.add(nuevoPedido);
            }
          } else if (nuevoPedido.tipo == 'express') {
            print(nuevoPedido);

            hoyexpress.add(nuevoPedido);
          }
        }
        // SI EL PEDIDO TIENE FECHA DE HOY Y ES NORMAL
      });

      // Desplaza automáticamente hacia el último elemento
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOutQuart,
      );

      _scrollControllerExpress.animateTo(
        _scrollControllerExpress.position.maxScrollExtent,
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

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 191, 195, 199),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: SingleChildScrollView(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SISTEMA DE PEDIDO
                  Row(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 20, left: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      Inicio(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOut;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    var offsetAnimation =
                                        animation.drive(tween);
                                    return SlideTransition(
                                        position: offsetAnimation,
                                        child: child);
                                  },
                                ),
                              );
                            },
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    const Color.fromARGB(255, 33, 76, 110))),
                            child: const Text("<< Sistema de Pedido",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 20, left: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Vista()),
                              );
                            },
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    const Color.fromARGB(255, 33, 76, 110))),
                            child: const Text("Supervision >>",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ]),

                  // TITULOS
                  Container(
                    // color: Colors.grey,
                    margin: const EdgeInsets.only(top: 20, left: 20),
                    child: Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sistema de Ruteo",
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 50),
                          height: 50,
                          width: 80,
                          child: Lottie.asset('lib/imagenes/hangloose.json'),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    // color: Colors.grey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // AGENDADOS
                                Container(
                                  //color: Colors.amber,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.amber),
                                  margin: const EdgeInsets.only(left: 20),
                                  padding: const EdgeInsets.all(15),
                                  width: 500, // MediaQuery
                                  height: 500,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    //crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pedidos Agendados : ${agendados.length}",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      TextField(
                                        controller: _searchController,
                                        onChanged: (value) {
                                          setState(
                                              () {}); // Actualiza el estado al cambiar el texto
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Buscar',
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: () {
                                              // Puedes realizar acciones de búsqueda aquí si es necesario
                                            },
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          reverse: true,
                                          scrollDirection: Axis.vertical,
                                          //controller: _scrollControllerAgendados,
                                          itemCount: agendados.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                             
                                              margin:
                                                  const EdgeInsets.only(top: 5),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color: Color.fromARGB(
                                                      255, 255, 255, 255)),
                                              child: ListTile(
                                                trailing: Checkbox(
                                                  value: agendados[index]
                                                      .seleccionado,
                                                  onChanged: (agendados[index]
                                                              .estado !=
                                                          'en proceso')
                                                      ? (value) {
                                                          setState(() {
                                                            agendados[index]
                                                                    .seleccionado =
                                                                value ?? false;
                                                            obtenerPedidoSeleccionado =
                                                                agendados
                                                                    .where((element) =>
                                                                        element
                                                                            .seleccionado)
                                                                    .toList();
                                                            if (value == true) {
                                                              agendados[index]
                                                                      .estado =
                                                                  "en proceso";

                                                              // AQUI DEBO TAMBIEN HACER "update pedido set estado = en proceso"
                                                              // esto con la finalidad de que se maneje el estado en la database

                                                              actualizarObtenidos();
                                                            } else {
                                                              agendados[index]
                                                                      .estado =
                                                                  'pendiente';
                                                              // AQUI DEBO TAMBIEN HACER "update pedido set estado = pendiente"
                                                              // esto con la finalidad de que se maneje el estado en la database
                                                              actualizarObtenidos();
                                                            }
                                                          });
                                                        }
                                                      : null,
                                                ),
                                                title: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Pedido N°: ${agendados[index].id}',
                                                      style: const TextStyle(
                                                        color: Colors.purple,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Cliente: ${agendados[index].nombre},${agendados[index].apellidos}',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                    Text(
                                                        'Telefono ${agendados[index].telefono}'),
                                                    Text(
                                                        "Distrito:${agendados[index].distrito}"),
                                                    Text(
                                                      'Monto Total: ${agendados[index].total}',
                                                      style: const TextStyle(),
                                                    ),
                                                    Text(
                                                      'Estado: ${agendados[index].estado.toUpperCase()}',
                                                      style: TextStyle(
                                                          color: agendados[index]
                                                                      .estado ==
                                                                  'pendiente'
                                                              ? const Color.fromARGB(
                                                                  255, 244, 54, 152)
                                                              : agendados[index].estado ==
                                                                      'en proceso'
                                                                  ? Color.fromARGB(
                                                                      255, 2, 129, 47)
                                                                  : agendados[index].estado ==
                                                                          'entregado'
                                                                      ? const Color.fromARGB(
                                                                          255,
                                                                          9,
                                                                          135,
                                                                          13)
                                                                      : Colors
                                                                          .black,
                                                          fontSize:
                                                              agendados[index].estado ==
                                                                      'en proceso'
                                                                  ? 20
                                                                  : 15,
                                                          fontWeight: agendados[index]
                                                                      .estado ==
                                                                  'pendiente'
                                                              ? FontWeight.w500
                                                              : FontWeight.bold),
                                                    ),
                                                    Text(
                                                      'Fecha: ${agendados[index].fecha}',
                                                      style: TextStyle(),
                                                    ),
                                                    Text(
                                                        'Tipo:${agendados[index].tipo}')
                                                  ],
                                                ),
                                                /*trailing: Row(*/
                                              ),
                                            );
                                            //  }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    // HOY
                                    Container(
                                      //color: Colors.amber,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: Color.fromARGB(
                                              255, 209, 94, 132)),
                                      margin: const EdgeInsets.only(left: 20),
                                      padding: const EdgeInsets.all(15),
                                      width: 250,
                                      height: 350,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        //crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Pedidos Hoy : ${hoypedidos.length}",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          ),
                                          TextField(
                                            controller: _searchController,
                                            onChanged: (value) {
                                              setState(
                                                  () {}); // Actualiza el estado al cambiar el texto
                                            },
                                            decoration: InputDecoration(
                                              labelStyle: const TextStyle(
                                                  color: Colors.white),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors
                                                        .grey), // Cambia el color del cursor cuando el TextField no está enfocado
                                              ),
                                              labelText: 'Buscar cliente',
                                              suffixIcon: IconButton(
                                                icon: const Icon(
                                                  Icons.search,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  // Puedes realizar acciones de búsqueda aquí si es necesario
                                                },
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                              reverse: true,
                                              controller: _scrollController,
                                              itemCount: hoypedidos.length,
                                              itemBuilder: (context, index) {
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 10),
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  child: ListTile(
                                                    trailing: Checkbox(
                                                      value: hoypedidos[index]
                                                          .seleccionado,
                                                      onChanged:
                                                          (hoypedidos[index]
                                                                      .estado !=
                                                                  'en proceso')
                                                              ? (value) {
                                                                  setState(() {
                                                                    hoypedidos[index]
                                                                            .seleccionado =
                                                                        value ??
                                                                            false;
                                                                    obtenerPedidoSeleccionado = hoypedidos
                                                                        .where((element) =>
                                                                            element.seleccionado)
                                                                        .toList();
                                                                    if (value ==
                                                                        true) {
                                                                      hoypedidos[index]
                                                                              .estado =
                                                                          "en proceso";
                                                                      // AQUI DEBO TAMBIEN HACER "update pedido set estado = en proceso"
                                                                      // esto con la finalidad de que se maneje el estado en la database
                                                                      actualizarObtenidos();
                                                                    } else {
                                                                      hoypedidos[index]
                                                                              .estado =
                                                                          'pendiente';
                                                                      // AQUI DEBO TAMBIEN HACER "update pedido set estado = pendiente"
                                                                      // esto con la finalidad de que se maneje el estado en la database
                                                                      actualizarObtenidos();
                                                                    }
                                                                  });
                                                                }
                                                              : null,
                                                    ),
                                                    title: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Pedido ID: ${hoypedidos[index].id}',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.purple,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500),
                                                        ),
                                                        Text(
                                                          'Cliente: ${hoypedidos[index].nombre},${hoypedidos[index].apellidos}',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        Text(
                                                            'Telefono: ${hoypedidos[index].telefono}'),
                                                        Text(
                                                            "Distrito: ${hoypedidos[index].distrito}"),
                                                        Text(
                                                            'Monto Total: ${hoypedidos[index].total}'),
                                                        Text(
                                                          'Estado: ${hoypedidos[index].estado.toUpperCase()}',
                                                          style: TextStyle(
                                                              color: hoypedidos[index].estado ==
                                                                      'pendiente'
                                                                  ? const Color.fromARGB(
                                                                      255, 244, 54, 152)
                                                                  : hoypedidos[index].estado ==
                                                                          'en proceso'
                                                                      ? Color.fromARGB(
                                                                          255,
                                                                          2,
                                                                          129,
                                                                          47)
                                                                      : hoypedidos[index].estado ==
                                                                              'entregado'
                                                                          ? const Color.fromARGB(
                                                                              255,
                                                                              9,
                                                                              135,
                                                                              13)
                                                                          : Colors
                                                                              .black,
                                                              fontSize:
                                                                  hoypedidos[index].estado ==
                                                                          'en proceso'
                                                                      ? 20
                                                                      : 15,
                                                              fontWeight: hoypedidos[index]
                                                                          .estado ==
                                                                      'pendiente'
                                                                  ? FontWeight.w500
                                                                  : FontWeight.bold),
                                                        ),
                                                        Text(
                                                            'Fecha: ${hoypedidos[index].fecha}'),
                                                        Text(
                                                            'Tipo: ${hoypedidos[index].tipo}'),
                                                      ],
                                                    ),
                                                    /*trailing: Row(*/
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // EXPRESS
                                    Container(
                                      //color: Colors.amber,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color:
                                            Color.fromARGB(255, 209, 94, 132),
                                      ),
                                      //margin: const EdgeInsets.only(left: 20),
                                      padding: const EdgeInsets.all(15),
                                      width: 250,
                                      height: 350,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        //crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Pedidos Express : ${hoyexpress.length}",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          ),
                                          TextField(
                                            controller: _searchController,
                                            onChanged: (value) {
                                              setState(
                                                  () {}); // Actualiza el estado al cambiar el texto
                                            },
                                            decoration: InputDecoration(
                                              labelStyle: const TextStyle(
                                                  color: Colors.white),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors
                                                        .grey), // Cambia el color del cursor cuando el TextField no está enfocado
                                              ),
                                              labelText: 'Buscar',
                                              suffixIcon: IconButton(
                                                icon: const Icon(
                                                  Icons.search,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  // Puedes realizar acciones de búsqueda aquí si es necesario
                                                },
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                              controller:
                                                  _scrollControllerExpress,
                                              reverse: true,
                                              itemCount: hoyexpress.length,
                                              itemBuilder: (context, index) {
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 10),
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  child: ListTile(
                                                    trailing: Checkbox(
                                                      value: hoyexpress[index]
                                                          .seleccionado,
                                                      onChanged:
                                                          (hoyexpress[index]
                                                                      .estado !=
                                                                  'en proceso')
                                                              ? (value) {
                                                                  setState(() {
                                                                    hoyexpress[index]
                                                                            .seleccionado =
                                                                        value ??
                                                                            false;
                                                                    obtenerPedidoSeleccionado = hoyexpress
                                                                        .where((element) =>
                                                                            element.seleccionado)
                                                                        .toList();
                                                                    if (value ==
                                                                        true) {
                                                                      hoyexpress[index]
                                                                              .estado =
                                                                          "en proceso";
                                                                      // AQUI DEBO TAMBIEN HACER "update pedido set estado = en proceso"
                                                                      // esto con la finalidad de que se maneje el estado en la database
                                                                      actualizarObtenidos();
                                                                    } else {
                                                                      hoyexpress[index]
                                                                              .estado =
                                                                          'pendiente';
                                                                      // AQUI DEBO TAMBIEN HACER "update pedido set estado = pendiente"
                                                                      // esto con la finalidad de que se maneje el estado en la database
                                                                      actualizarObtenidos();
                                                                    }
                                                                  });
                                                                }
                                                              : null,
                                                    ),
                                                    title: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Pedido ID: ${hoyexpress[index].id}',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.purple,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        Text(
                                                          'Cliente: ${hoyexpress[index].nombre}, ${hoyexpress[index].apellidos}',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        Text(
                                                            'Telefono: ${hoyexpress[index].telefono}'),
                                                        Text(
                                                            "Distrito: ${hoyexpress[index].distrito}"),
                                                        Text(
                                                            'Monto Total: ${hoyexpress[index].total}'),
                                                        Text(
                                                          'Estado: ${hoyexpress[index].estado.toUpperCase()}',
                                                          style: TextStyle(
                                                              color: hoyexpress[index].estado ==
                                                                      'pendiente'
                                                                  ? const Color.fromARGB(
                                                                      255, 244, 54, 152)
                                                                  : hoyexpress[index].estado ==
                                                                          'en proceso'
                                                                      ? Color.fromARGB(
                                                                          255,
                                                                          2,
                                                                          129,
                                                                          47)
                                                                      : hoyexpress[index].estado ==
                                                                              'entregado'
                                                                          ? const Color.fromARGB(
                                                                              255,
                                                                              9,
                                                                              135,
                                                                              13)
                                                                          : Colors
                                                                              .black,
                                                              fontSize:
                                                                  hoyexpress[index].estado ==
                                                                          'en proceso'
                                                                      ? 20
                                                                      : 15,
                                                              fontWeight: hoyexpress[index]
                                                                          .estado ==
                                                                      'pendiente'
                                                                  ? FontWeight.w500
                                                                  : FontWeight.bold),
                                                        ),
                                                        Text(
                                                            'Fecha: ${hoyexpress[index].fecha}'),
                                                        Text(
                                                            'Tipo: ${hoyexpress[index].tipo}'),
                                                      ],
                                                    ),
                                                    /*trailing: Row(*/
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
                              ],
                            ),

                            // MAPA
                            Container(
                              padding: const EdgeInsets.all(10),
                              //margin: const EdgeInsets.only(top: 20, left: 20),
                              width: 1020,
                              height: 850,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 16, 63, 100),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                            options: MapOptions(
                                              initialCenter: LatLng(-16.4055657,
                                                  -71.5719081), //multipuntos.first, //? LatLng(0.0,0.0) :multipuntos.first ,
                                              initialZoom: 12.8,
                                            ),
                                            children: [
                                              TileLayer(
                                                urlTemplate:
                                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                userAgentPackageName:
                                                    'com.example.app',
                                              ),
                                              PolylineLayer(
                                                polylines: [
                                                  Polyline(
                                                    points: multipuntos,
                                                    color: Colors.blue,
                                                    strokeWidth:
                                                        10.0, // Ajusta el ancho de la línea según tus preferencias
                                                    isDotted:
                                                        true, // Cambia a true si quieres una línea punteada
                                                    // isPolygon: false,
                                                  ),
                                                ],
                                              ),
                                              MarkerLayer(
                                                
                                                markers: [
                                                  
                                                // AÑADO LOS MARCADORES CON SPREAD
                                                // DE LOS PEDIDOS
                                                ...markers,
                                                // Y AÑADO UN MARCADOR ESPECIFICO
                                                map.Marker(
                                                  
                                                  point: LatLng(-16.4055657,
                                                      -71.5719081), // Ejemplo de una posición diferente
                                                  width: 25,
                                                  height: 25,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            50),
                                                    // height: 80,
                                                    // width: 80,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        color: Colors.grey,
                                                        image: DecorationImage(
                                                            image: AssetImage(
                                                                'lib/imagenes/logo_sol.png'),
                                                            fit: BoxFit.cover)),
                                                  ),
                                                ),
                                              ]
                                                  /* [
                                                  map.Marker(
                                                    point: LatLng(-16.5,-71.8),
                                                    width: 40,
                                                    height: 50,
                                                    child: Container(
                                                      height: 30,
                                                      width: 30,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          color: Colors.green,
                                                          image: DecorationImage(
                                                              image: AssetImage(
                                                                  'lib/imagenes/pocionverde.png'),
                                                              fit:
                                                                  BoxFit.fill)),
                                                    ),
                                                  ),
                                                ],*/
                                                  ),
                                            ]),
                                        Positioned(
                                          bottom:
                                              16.0, // Ajusta la posición vertical según tus necesidades
                                          right:
                                              16.0, // Ajusta la posición horizontal según tus necesidades
                                          child: FloatingActionButton(
                                            onPressed: () {
                                              // Acciones al hacer clic en el FloatingActionButton
                                            },
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 53, 102, 142),
                                            child: const Icon(Icons.my_location,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  ElevatedButton(
                                      onPressed: () {
                                        for (var i = 0;
                                            i < agendados.length;
                                            i++) {
                                          // aca digo que todos los pedidos se reviertan a false
                                          // y esten pendinte
                                          // ---ASI QUE FILTRO ESE PEDIDO
                                          if (agendados[i].estado ==
                                                  'en proceso' &&
                                              agendados[i].seleccionado ==
                                                  true) {
                                            agendados[i].seleccionado = false;
                                            agendados[i].estado = 'pendiente';
                                          }

                                          //   agendados[i].seleccionado =false;
                                          // agendados[i].estado = 'pendiente';
                                        }
                                        for (var i = 0;
                                            i < hoypedidos.length;
                                            i++) {
                                          // aca digo que todos los pedidos se reviertan a false
                                          // y esten pendinte
                                          // ---ASI QUE FILTRO ESE PEDIDO
                                          if (hoypedidos[i].estado ==
                                                  'en proceso' &&
                                              hoypedidos[i].seleccionado ==
                                                  true) {
                                            hoypedidos[i].seleccionado = false;
                                            hoypedidos[i].estado = 'pendiente';
                                          }

                                          //   agendados[i].seleccionado =false;
                                          // agendados[i].estado = 'pendiente';
                                        }
                                        for (var i = 0;
                                            i < hoyexpress.length;
                                            i++) {
                                          // aca digo que todos los pedidos se reviertan a false
                                          // y esten pendinte
                                          // ---ASI QUE FILTRO ESE PEDIDO
                                          if (hoyexpress[i].estado ==
                                                  'en proceso' &&
                                              hoyexpress[i].seleccionado ==
                                                  true) {
                                            hoyexpress[i].seleccionado = false;
                                            hoyexpress[i].estado = 'pendiente';
                                          }

                                          //   agendados[i].seleccionado =false;
                                          // agendados[i].estado = 'pendiente';
                                        }
                                        setState(() {
                                          obtenerPedidoSeleccionado = [];
                                          multipuntos = [];
                                          markers = [];
                                        });

                                        setState(() {});
                                      },
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Color.fromARGB(
                                                      255, 200, 244, 53))),
                                      child: Text(
                                        "Deshacer",
                                        style: TextStyle(color: Colors.black),
                                      )),
                                ],
                              ),
                            ),

                            // PEDIDOS-CONDUCTORES
                            Column(
                              //crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // PEDIDOS SELECCIONADOS
                                Container(
                                  padding: const EdgeInsets.all(25),
                                  //   margin:const EdgeInsets.only(top: 20, left: 20),
                                  height: 300,
                                  width: 350,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color:
                                        const Color.fromARGB(255, 16, 63, 100),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Pedidos Seleccionados : ${obtenerPedidoSeleccionado.length}",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          
                                          reverse: true,
                                          itemCount:
                                              obtenerPedidoSeleccionado.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                                margin: const EdgeInsets.only(
                                                    top: 10),
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                        255, 59, 166, 63),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Pedido ID: ${obtenerPedidoSeleccionado[index].id} ",
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    Text(
                                                      "Cliente: ${obtenerPedidoSeleccionado[index].nombre}, ${obtenerPedidoSeleccionado[index].apellidos}",
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    Text(
                                                      "Ruta ID: ${obtenerPedidoSeleccionado[index].ruta_id}",
                                                      style: const TextStyle(
                                                          color: Colors.purple),
                                                    ),
                                                    Text(
                                                      "Monto Total: ${obtenerPedidoSeleccionado[index].total}",
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    Text(
                                                      "Fecha: ${obtenerPedidoSeleccionado[index].fecha}",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color.fromARGB(
                                                            255, 44, 42, 22),
                                                      ),
                                                    ),
                                                    Text(
                                                        "Tipo: ${obtenerPedidoSeleccionado[index].tipo}",
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          color: Colors.yellow,
                                                        ))
                                                  ],
                                                ));
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),

                                // CONDUCTORES
                                Container(
                                  width: 350,
                                  height: 400,
                                  //margin: const EdgeInsets.only(top: 20, left: 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color:
                                        const Color.fromARGB(255, 16, 63, 100),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Conductores Disponibles : ${conductores.length}",
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.white),
                                      ),
                                      const SizedBox(
                                        height: 19,
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: conductores.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                                margin: const EdgeInsets.only(
                                                    top: 10),
                                                padding:
                                                    const EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                        255, 59, 166, 63),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                child: ListTile(
                                                  title: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "C1:${conductores[index].id}",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Text(
                                                        "Nombres:${conductores[index].nombres}",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Text(
                                                        "Apellidos:${conductores[index].apellidos}",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Text(
                                                        "Dni:${conductores[index].dni}",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      )
                                                    ],
                                                  ),
                                                  trailing: Checkbox(
                                                    value: conductores[index]
                                                        .seleccionado,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        conductores[index].seleccionado =value ?? false;
                                                        obtenerConductor = conductores.where((element) =>element .seleccionado).toList();

                                                        if (value == true) {
                                                          setState(() {
                                                            conductorid =
                                                                conductores[
                                                                        index]
                                                                    .id;
                                                          });
                                                          print(
                                                              "CONDUCTOR ID SELECCIIONADO");
                                                          print(conductorid);
                                                          /*conductores[index]
                                                                      .estado =
                                                                  "Go >>";*/
                                                          // AQUI DEBO TAMBIEN HACER "update pedido set estado = en proceso"
                                                          // esto con la finalidad de que se maneje el estado en la database
                                                          //actualizarObtenidos();
                                                        } else {
                                                          /* conductores[index]
                                                                      .estado =
                                                                  'Ready >>';*/
                                                          // AQUI DEBO TAMBIEN HACER "update pedido set estado = pendiente"
                                                          // esto con la finalidad de que se maneje el estado en la database
                                                          //actualizarObtenidos();
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ));
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),

                                //BOTONES
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // BOTON CREAR
                                    Container(
                                      // margin: const EdgeInsets.only(left: 20),
                                      height: 150,
                                      width: 150,
                                      // color: Colors.black,
                                      child: ElevatedButton(
                                        onPressed:
                                            obtenerConductor.isNotEmpty &&
                                                    obtenerPedidoSeleccionado
                                                        .isNotEmpty
                                                ? () async {
                                                    showDialog<String>(
                                                        context: context,
                                                        builder:
                                                            (BuildContext
                                                                    context) =>
                                                                AlertDialog(
                                                                  title: const Text(
                                                                      'Crear Ruta - Conductor'),
                                                                  content:
                                                                      const Text(
                                                                          '¿Crear?'),
                                                                  actions: <Widget>[
                                                                    // CANCELAR
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        for (var i =
                                                                                0;
                                                                            i < agendados.length;
                                                                            i++) {
                                                                          // aca digo que todos los pedidos se reviertan a false
                                                                          // y esten pendinte
                                                                          // ---ASI QUE FILTRO ESE PEDIDO
                                                                          if (agendados[i].estado == 'en proceso' &&
                                                                              agendados[i].seleccionado == true) {
                                                                            agendados[i].seleccionado =
                                                                                false;
                                                                            agendados[i].estado =
                                                                                'pendiente';
                                                                          }

                                                                          //   agendados[i].seleccionado =false;
                                                                          // agendados[i].estado = 'pendiente';
                                                                        }
                                                                        for (var i =
                                                                                0;
                                                                            i < hoypedidos.length;
                                                                            i++) {
                                                                          // aca digo que todos los pedidos se reviertan a false
                                                                          // y esten pendinte
                                                                          // ---ASI QUE FILTRO ESE PEDIDO
                                                                          if (hoypedidos[i].estado == 'en proceso' &&
                                                                              hoypedidos[i].seleccionado == true) {
                                                                            hoypedidos[i].seleccionado =
                                                                                false;
                                                                            hoypedidos[i].estado =
                                                                                'pendiente';
                                                                          }

                                                                          //   agendados[i].seleccionado =false;
                                                                          // agendados[i].estado = 'pendiente';
                                                                        }
                                                                        for (var i =
                                                                                0;
                                                                            i < hoyexpress.length;
                                                                            i++) {
                                                                          // aca digo que todos los pedidos se reviertan a false
                                                                          // y esten pendinte
                                                                          // ---ASI QUE FILTRO ESE PEDIDO
                                                                          if (hoyexpress[i].estado == 'en proceso' &&
                                                                              hoyexpress[i].seleccionado == true) {
                                                                            hoyexpress[i].seleccionado =
                                                                                false;
                                                                            hoyexpress[i].estado =
                                                                                'pendiente';
                                                                          }

                                                                          //   agendados[i].seleccionado =false;
                                                                          // agendados[i].estado = 'pendiente';
                                                                        }

                                                                        for (var i =
                                                                                0;
                                                                            i < conductores.length;
                                                                            i++) {
                                                                          conductores[i].seleccionado =
                                                                              false;
                                                                        }
                                                                        setState(
                                                                            () {
                                                                          obtenerPedidoSeleccionado =
                                                                              [];
                                                                          obtenerConductor =
                                                                              [];
                                                                        });
                                                                        //await getPedidos();

                                                                        setState(
                                                                            () {});

                                                                        Navigator.pop(
                                                                            context,
                                                                            'Cancelar');
                                                                      },
                                                                      //
                                                                      child: const Text(
                                                                          'Cancelar'),
                                                                    ),

                                                                    // CONFIRMAR
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () async {
                                                                        // PROCESO EL PEDIDO
                                                                        await crearobtenerYactualizarRuta(
                                                                            1,
                                                                            conductorid,
                                                                            50,
                                                                            3,
                                                                            "en proceso");

                                                                        // LIMPIO LOS SELECCIONADOS
                                                                        setState(
                                                                            () {
                                                                          obtenerPedidoSeleccionado =
                                                                              [];
                                                                          obtenerConductor =
                                                                              [];
                                                                        });

                                                                        // Y DEVUELVO A DESELECCIONAR PARA QUE NO SE ACUMULE O
                                                                        // ARRASTREE EL CHECKBOX ANTIGUO
                                                                        for (var i =
                                                                                0;
                                                                            i < agendados.length;
                                                                            i++) {
                                                                          agendados[i].seleccionado =
                                                                              false;
                                                                          agendados[i].estado ==
                                                                              'en proceso';
                                                                        }
                                                                        for (var i =
                                                                                0;
                                                                            i < hoypedidos.length;
                                                                            i++) {
                                                                          hoypedidos[i].seleccionado =
                                                                              false;
                                                                          hoypedidos[i].estado ==
                                                                              'en proceso';
                                                                        }
                                                                        for (var i =
                                                                                0;
                                                                            i < hoyexpress.length;
                                                                            i++) {
                                                                          hoyexpress[i].seleccionado =
                                                                              false;
                                                                          hoyexpress[i].estado ==
                                                                              'en proceso';
                                                                        }

                                                                        // IGUAL . DESELECCIONO EL CHOFER, PARA QUE NO ARRASTRE
                                                                        for (var i =
                                                                                0;
                                                                            i < conductores.length;
                                                                            i++) {
                                                                          conductores[i].seleccionado =
                                                                              false;
                                                                        }
                                                                        // ACTUALIZO LA VISTA AL USUARIO
                                                                        // await getPedidos();
                                                                        setState(
                                                                            () {});

                                                                        Navigator.pop(
                                                                            context,
                                                                            'SI');
                                                                      },
                                                                      child: const Text(
                                                                          'SI'),
                                                                    ),
                                                                  ],
                                                                ));

                                                    // create ruta - empleadoid,conductorid,distancia,tiempo
                                                  }
                                                : null,
                                        child: Text(
                                          "Crear \u{2795}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 35),
                                        ),
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                            const Color.fromARGB(
                                                255, 16, 63, 100),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // INFORME PDF
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                          //color: Colors.amber,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        child: Text(
                                          "Info-PDF",
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 26, 44, 78),
                                              fontSize: 29,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.amber)),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // SUPERVISION
                  Container(
                    margin: const EdgeInsets.only(top: 20, left: 20, bottom: 0),
                    child: Text(
                      "Supervisión de Rutas",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),

                  // RUTAS

                  Container(
                      margin: const EdgeInsets.only(left: 20, top: 20),
                      height: 500,
                      width: 1450,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 16, 63, 100),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          Text("Ruta del conductor",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 25)),
                          Expanded(
                            child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                reverse: true,
                                itemCount: 4,
                                itemBuilder: (context, index) {
                                  return Row(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            top: 20, left: 20),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              Color.fromARGB(255, 16, 63, 100),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        width: 900,
                                        height: 400,
                                        child: Stack(
                                          children: [
                                            FlutterMap(
                                              options: const MapOptions(
                                                initialCenter: LatLng(
                                                    -16.4055657, -71.5719081),
                                                initialZoom: 15.2,
                                              ),
                                              children: [
                                                TileLayer(
                                                  urlTemplate:
                                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                  userAgentPackageName:
                                                      'com.example.app',
                                                ),
                                                PolylineLayer(polylines: [
                                                  Polyline(
                                                      points: routePoints,
                                                      color: Colors.pinkAccent),
                                                ]),
                                                MarkerLayer(
                                                  markers: [
                                                    map.Marker(
                                                      point: currentLcocation,
                                                      width: 80,
                                                      height: 80,
                                                      child: Icon(
                                                        Icons.directions_car,
                                                        color: Colors.red,
                                                        size: 45.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Positioned(
                                              bottom:
                                                  16.0, // Ajusta la posición vertical según tus necesidades
                                              right:
                                                  16.0, // Ajusta la posición horizontal según tus necesidades
                                              child: FloatingActionButton(
                                                onPressed: () {
                                                  // Acciones al hacer clic en el FloatingActionButton
                                                },
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 53, 102, 142),
                                                child: const Icon(
                                                    Icons.my_location,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 400,
                                        height: 400,
                                        padding: const EdgeInsets.all(20),
                                        margin: const EdgeInsets.only(
                                            top: 20, left: 20),
                                        decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 59, 166, 63),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                child: Text(
                                                  "Conductor : Paul Perez Perez",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Container(
                                                child: Text(
                                                  "AUTO : T-KING",
                                                  style: TextStyle(
                                                      color: Colors.yellow,
                                                      fontSize: 25),
                                                ),
                                              ),
                                              Container(
                                                child: Text(
                                                  "PLACA : XV-234",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 25),
                                                ),
                                              ),
                                              Container(),
                                            ]),
                                      ),
                                    ],
                                  );
                                }),
                          ),
                        ],
                      )),
                  const SizedBox(
                    width: 30,
                  ),

                  // COPPYRIGHT
                  Container(
                    //Text('Click \u{2795} to add')
                    margin: const EdgeInsets.all(30),
                    child: Center(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 50,
                            height: 50,
                            child: Image.asset('lib/imagenes/logo_sol.png')),
                        Text(" v.1.0.0 ", style: TextStyle(fontSize: 20)),
                        Text(
                          "Copyright \u00a9 COTECSA - 2024",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w400),
                        ),
                      ],
                    )),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
