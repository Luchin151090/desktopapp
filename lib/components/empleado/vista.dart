import 'package:flutter/material.dart';
import 'package:desktopapp/components/empleado/armado.dart';
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Vista extends StatefulWidget {
  const Vista({super.key});

  @override
  State<Vista> createState() => _VistaState();
}

class _VistaState extends State<Vista> {
  LatLng currentLcocation = LatLng(0, 0);
  late ScrollController _scrollController; // = ScrollController();
  ScrollController _scrollControllerExpress = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Pedido> hoypedidos = [];
  List<Pedido> hoyexpress = [];
  List<Pedido> obtenerPedidoSeleccionado = [];
  final List<LatLng> routePoints = [
    LatLng(-16.4055657, -71.5719081),
    LatLng(-16.4050152, -71.5705073),
    LatLng(-16.4022842, -71.5651442),
    LatLng(-16.4086712, -71.5579809),
  ];
  void actualizarObtenidos() {
    setState(() {
      obtenerPedidoSeleccionado = [
        ...hoypedidos,
        ...hoyexpress,
      ].where((element) => element.seleccionado).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 140, 150, 160),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: SingleChildScrollView(
                  child: Column(
                      //mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            //mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 20, left: 20),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          print(MediaQuery.of(context)
                                              .size
                                              .width);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const Armado()),
                                          );
                                        },
                                        style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    const Color.fromARGB(
                                                        255, 33, 76, 110))),
                                        child: Text("<< Armado",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.027)),
                                      ),
                                    ),
                                    Container(
                                      //color: Colors.amber,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: Color.fromARGB(
                                              255, 209, 94, 132)),
                                      margin: const EdgeInsets.only(
                                          top: 20, left: 20),
                                      padding: const EdgeInsets.all(15),
                                      width:
                                          (MediaQuery.of(context).size.height) *
                                              0.47,
                                      height:
                                          (MediaQuery.of(context).size.height) *
                                              0.5,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        //crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Pedidos Hoy : ${hoypedidos.length}",
                                            style: TextStyle(
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.027,
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
                                      margin: const EdgeInsets.only(
                                          top: 20, left: 20, bottom: 20),
                                      padding: const EdgeInsets.all(15),
                                      width:
                                          (MediaQuery.of(context).size.height) *
                                              0.47,
                                      height:
                                          (MediaQuery.of(context).size.height) *
                                              0.5,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        //crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Pedidos Express : ${hoyexpress.length}",
                                            style: TextStyle(
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.027,
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
                                    )
                                  ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 20, left: 20, bottom: 0),
                                      child: Text(
                                        "Supervisión de Rutas",
                                        style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.027),
                                      ),
                                    ),
                                    Container(
                                        margin: const EdgeInsets.only(
                                            left: 20, top: 20, bottom: 0),
                                        height:
                                            MediaQuery.of(context).size.height,
                                        width:
                                            (MediaQuery.of(context).size.width *
                                                0.73),
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 16, 63, 100),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Column(
                                          children: [
                                            Text("Ruta del conductor",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.027)),
                                            Expanded(
                                              child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  reverse: true,
                                                  itemCount: 4,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return Row(
                                                      children: [
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 20,
                                                                  left: 20),
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(10),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    16,
                                                                    63,
                                                                    100),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          width: (MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.49),
                                                          height: 400,
                                                          child: Stack(
                                                            children: [
                                                              FlutterMap(
                                                                options:
                                                                    MapOptions(
                                                                  initialCenter: LatLng(
                                                                      -16.4055657,
                                                                      -71.5719081),
                                                                  initialZoom:
                                                                      15.2,
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
                                                                            points:
                                                                                routePoints,
                                                                            color:
                                                                                Colors.pinkAccent),
                                                                      ]),
                                                                  MarkerLayer(
                                                                    markers: [
                                                                      map.Marker(
                                                                        point:
                                                                            currentLcocation,
                                                                        width:
                                                                            80,
                                                                        height:
                                                                            80,
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .directions_car,
                                                                          color:
                                                                              Colors.red,
                                                                          size:
                                                                              45.0,
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
                                                                child:
                                                                    FloatingActionButton(
                                                                  onPressed:
                                                                      () {
                                                                    // Acciones al hacer clic en el FloatingActionButton
                                                                  },
                                                                  backgroundColor:
                                                                      const Color
                                                                          .fromARGB(
                                                                          255,
                                                                          53,
                                                                          102,
                                                                          142),
                                                                  child: const Icon(
                                                                      Icons
                                                                          .my_location,
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Container(
                                                          width: (MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width) *
                                                              0.19,
                                                          height: 400,
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(20),
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 20,
                                                                  left: 20),
                                                          decoration: BoxDecoration(
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      59,
                                                                      166,
                                                                      63),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20)),
                                                          child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Container(
                                                                  child: Text(
                                                                    "Conductor : Paul Perez Perez",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontSize:
                                                                            MediaQuery.of(context).size.height *
                                                                                0.027,
                                                                        fontWeight:
                                                                            FontWeight.w500),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  child: Text(
                                                                    "AUTO : T-KING",
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .yellow,
                                                                      fontSize: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          0.027,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  child: Text(
                                                                    "PLACA : XV-234",
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize: MediaQuery.of(context)
                                                                              .size
                                                                              .height *
                                                                          0.027,
                                                                    ),
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
                                  ]),
                            ])
                      ]),
                ))));
  }
}