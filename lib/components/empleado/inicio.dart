import 'package:desktopapp/components/empleado/armado.dart';
import 'package:desktopapp/components/empleado/armadodo2.dart';
import 'package:desktopapp/components/empleado/login1.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktopapp/components/provider/user_provider.dart';


class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String foto;
  final int? promoID;
  int cantidadInt;
  double descuentoDouble;
  double? monto;
  String observacion;
  TextEditingController cantidad;
  TextEditingController descuento;
  TextEditingController nombreAutorizador;
  TextEditingController cargoAutorizador;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.foto,
    required this.promoID,
    this.cantidadInt = 0,
    this.descuentoDouble = 0.00,
    this.monto = 0,
    this.observacion = '',
    TextEditingController? cantidad,
    TextEditingController? descuento,
    TextEditingController? nombreAutorizador,
    TextEditingController? cargoAutorizador,
  })  : cantidad = cantidad ?? TextEditingController(),
        descuento = descuento ?? TextEditingController(),
        nombreAutorizador =
            nombreAutorizador ?? TextEditingController(), // Inicialización aquí
        cargoAutorizador = cargoAutorizador ?? TextEditingController();
}

class Promo {
  final int id;
  final String nombre;
  final double precio;
  final String descripcion;
  final String fecha_limite;
  final String foto;
  int cantidadInt;
  double descuentoDouble;
  double? monto;
  String observacion;
  TextEditingController? cantidad;
  TextEditingController? descuento;
  TextEditingController nombreAutorizador;
  TextEditingController cargoAutorizador;

  Promo({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.fecha_limite,
    required this.foto,
    this.cantidadInt = 0,
    this.descuentoDouble = 0.00,
    this.monto = 0,
    this.observacion = '',
    TextEditingController? cantidad,
    TextEditingController? descuento,
    TextEditingController? nombreAutorizador,
    TextEditingController? cargoAutorizador,
  })  : cantidad = cantidad ?? TextEditingController(), // Inicialización aquí
        descuento = descuento ?? TextEditingController(),
        nombreAutorizador =
            nombreAutorizador ?? TextEditingController(), // Inicialización aquí
        cargoAutorizador = cargoAutorizador ?? TextEditingController();
}

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var direccion = '';
  final TextEditingController _nombres = TextEditingController();
  final TextEditingController _apellidos = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _distrito = TextEditingController();
  final TextEditingController _latitud = TextEditingController();
  final TextEditingController _longitud = TextEditingController();
  final TextEditingController _ruc = TextEditingController();

  late double temperatura = 0.0;
  final now = DateTime.now();
  // Formato para obtener el nombre del mes
  final monthFormat = DateFormat('MMMM');

  // Lista de productos

  List<dynamic> listPromosSeleccionadas = [];
  List<dynamic> listFinalProductosSeleccionados = [];
  List<dynamic> listFinalProductosSeleccionadosConDSCT = [];
  List<dynamic> listSeleccionados = [];
  List<dynamic> listElementos = [];

  String apiUrl = dotenv.env['API_URL'] ?? '';
  String apiClima =
      "https://api.openweathermap.org/data/2.5/weather?q=Arequipa&appid=08607bf479e5f47f5b768154953d10f6";
  String apiProducts = '/api/products';
  String apiProductsbyPromos = '/api/productsbypromo/';
  String apiClienteNR = '/api/clientenr';
  String apiPromos = '/api/promocion';
  String apiPedidos = '/api/pedido';
  String apiProductoPromocion = '/api/prod_prom';
  String apiDetallePedido = '/api/detallepedido';
  String apiLastClienteNR = '/api/last_clientenr/';
  DateTime tiempoActual = DateTime.now();
  double montoMinimo = 10;
  int empleadoID = 1;
  int lastClienteNR = 0;
  double montoTotalPedido = 0;
  double descuentoTotalPedido = 0;
  String observacionFinal = '';
  String? tipo = 'normal';

  List<DropdownMenuItem<String>> get dropdownItems {
    return [
      const DropdownMenuItem(
        value: 'normal',
        child: Text('Normal  (+ S/.0.00)'),
      ),
      const DropdownMenuItem(
        value: 'express',
        child: Text('Express (+ S/.4.00)'),
      ),
    ];
  }

  Future<dynamic> getProducts() async {
    var res = await http.get(Uri.parse(apiUrl + apiProducts),
        headers: {"Content-type": "application/json"});

    try {
      if (res.statusCode == 200) {
        //
        var data = json.decode(res.body);
        List<Producto> tempProductos = data.map<Producto>((mapa) {
          return Producto(
            id: mapa['id'],
            nombre: mapa['nombre'],
            descripcion: mapa['descripcion'],
            precio: mapa['precio'].toDouble(),
            foto: '$apiUrl/images/${mapa['foto']}',
            promoID: null,
          );
        }).toList();
        for (var i = 0; i < tempProductos.length; i++) {
          listElementos.add(tempProductos[i]);
          print("-------LISTAAAPRO");
          print(listElementos);
        }
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> getPromos() async {
    var res = await http.get(Uri.parse(apiUrl + apiPromos),
        headers: {"Content-type": "application/json"});

    try {
      if (res.statusCode == 200) {
        //
        var data = json.decode(res.body);
        List<Promo> tempPromos = data.map<Promo>((mapa) {
          return Promo(
              id: mapa['id'],
              nombre: mapa['nombre'],
              descripcion: mapa['descripcion'],
              precio: mapa['precio'].toDouble(),
              fecha_limite: mapa['fecha_limite'].toString(),
              foto: '$apiUrl/images/${mapa['foto']}');
        }).toList();
        for (var i = 0; i < tempPromos.length; i++) {
          listElementos.add(tempPromos[i]);
        }
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> getTemperature() async {
    try {
      var res = await http.get(Uri.parse(apiClima),
          headers: {"Content-type": "application/json"});
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        print("${now}");
        //
        print("${data['main']['temp']}");
        setState(() {
          temperatura = data['main']['temp'] - 273.15;
        });
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  //LLAMA A LA FUNCION DE CREADO DE PEDIDO Y DEATALLE DE PEDIDO EN ORDEN
  Future<void> calculoDeSeleccionadosYMontos() async {
    print(
        '2) Ingresa a al for que en el que se separan de los elementos elegidos, promos y poductos');
    print(
        '   esta es la longitud de la lista de elementos: ${listElementos.length}');
    print(listElementos);

    for (var i = 0; i < listElementos.length; i++) {
      if (listElementos[i].cantidad.text.isNotEmpty) {
        listSeleccionados.add(listElementos[i]);
        if (listElementos[i] is Promo) {
          listPromosSeleccionadas.add(listElementos[i]);
        } else if (listElementos[i] is Producto) {
          listFinalProductosSeleccionados.add(listElementos[i]);
        }
      }
    }

    for (var i = 0; i < listSeleccionados.length; i++) {}
    print(
        '3) Esto son los elemetos seleccionados: ${listSeleccionados.length}');
    print(
        '4) esta es la cantidad de seleccionados que son PRODUCTOS: ${listFinalProductosSeleccionados.length}');
    print(
        '5) esta es la cantidad de seleccionados que son PROMOS: ${listPromosSeleccionadas.length}');

    for (var i = 0; i < listPromosSeleccionadas.length; i++) {
      print('-------------------------------------------------');
      print('FOR PARA LLAMAR A GET PRODUCTOS DE PROMO');
      print('5.1) este es el valor de i: $i');
      await getProductoDePromo(
          int.parse(listPromosSeleccionadas[i].cantidad.text),
          listPromosSeleccionadas[i].monto,
          listPromosSeleccionadas[i].observacion,
          listPromosSeleccionadas[i].descuentoDouble,
          listPromosSeleccionadas[i].id);
    }

    print(
        '5.5) Luego de hacer el for se actualiza la cantidad de produtos: ${listFinalProductosSeleccionados.length}');

    for (var i = 0; i < listFinalProductosSeleccionados.length; i++) {
      print('+++++++++++++++++++++');
      print(
          '     Esta es la cantidad de producto: ${listFinalProductosSeleccionados[i].cantidadInt}');
      print(
          '     Este es el descuento: ${listFinalProductosSeleccionados[i].descuentoDouble}');
      print(
          '     Este es el monto total por producto: ${listFinalProductosSeleccionados[i].monto}');
      setState(() {
        descuentoTotalPedido +=
            listFinalProductosSeleccionados[i].descuentoDouble;
        montoTotalPedido += listFinalProductosSeleccionados[i].monto;
      });

      if (listFinalProductosSeleccionados[i].descuentoDouble != 0.00) {
        setState(() {
          listFinalProductosSeleccionadosConDSCT
              .add(listFinalProductosSeleccionados[i]);
        });
      }
      print('     Este es el monto total: $montoTotalPedido');
      print('     Este es el descuento total: $descuentoTotalPedido');
    }

    print(
        "     esta es la longitu de prod con desc ${listFinalProductosSeleccionadosConDSCT.length}");

    for (var i = 0; i < listFinalProductosSeleccionadosConDSCT.length; i++) {
      var salto = '\n';
      if (i == 0) {
        setState(() {
          observacionFinal =
              "${listFinalProductosSeleccionadosConDSCT[i].observacion}";
        });
      } else {
        setState(() {
          observacionFinal =
              "$observacionFinal$salto${listFinalProductosSeleccionadosConDSCT[i].observacion}";
        });
      }
    }
    print('     Esta es la observacion final: $observacionFinal');
  }

  Future<void> pedidoCancelado() async {
    print('11) Limpieza de variablesssss');
    setState(() {
      for (var i = 0; i < listElementos.length; i++) {
        setState(() {
          listElementos[i].cantidad.clear();
          listElementos[i].descuento.clear();
          listElementos[i].nombreAutorizador.clear();
          listElementos[i].cargoAutorizador.clear();
          listElementos[i].observacion = '';
        });
      }
      print('11.1) Ingreso al set state');
      _nombres.clear();
      _apellidos.clear();
      _direccion.clear();
      _telefono.clear();
      _email.clear();
      _distrito.clear();
      _latitud.clear();
      _longitud.clear();
      _ruc.clear();
      lastClienteNR = 0;
      montoTotalPedido = 0;
      descuentoTotalPedido = 0;
      observacionFinal = '';
      tipo = 'normal';
      print('11.2) resetear las listas');
      listSeleccionados = [];
      listFinalProductosSeleccionados = [];
      listFinalProductosSeleccionadosConDSCT = [];
      listPromosSeleccionadas = [];
    });
  }

  Future<void> crearClienteNRmPedidoyDetallePedido(empleadoID, tipo) async {
    DateTime tiempoGMTPeru = tiempoActual.subtract(const Duration(hours: 5));

    print('-------------------------------------------------');
    print('FUNCION QUE ORDENA LOS ENDPOINTS');

    if (_formKey.currentState!.validate()) {
      print('6) IF que valida que los datos del cliente NR estén llenos');
      print("6.1) datos personales");
      print("${_nombres.text} , ${_apellidos.text}");
      await createNR(
          empleadoID,
          _nombres.text,
          _apellidos.text,
          _direccion.text,
          _telefono.text,
          _email.text,
          _distrito.text,
          _latitud.text,
          _longitud.text,
          _ruc.text);
      Navigator.pop(context, 'SI');
    }

    await lastClienteNrID(empleadoID);
    print('7.4) este es el ultimo cliente no registrado: $lastClienteNR');
    print('8) creado de pedido');
    print('8.1) Este es el tiempo GMT: ${tiempoActual.toString()}');
    print('8.2) Este es el tiempo de peru: ${tiempoGMTPeru.toString()}');
    await datosCreadoPedido(
        lastClienteNR,
        tiempoGMTPeru.toString(),
        montoTotalPedido,
        descuentoTotalPedido,
        tipo,
        "pendiente",
        observacionFinal);

    print("10) creando detalles de pedidos");

    for (var i = 0; i < listFinalProductosSeleccionados.length; i++) {
      print('+++++++++++++++++++++');
      print('10.1) Dentro del FOR para creado de detalle');
      print(
          "10.2) longitud de seleccinados: ${listFinalProductosSeleccionados.length} este es i: $i");
      print(
          "      esta es el producto ID: ${listFinalProductosSeleccionados[i].id}");
      print(
          "      esta es la cantidad de producto: ${listFinalProductosSeleccionados[i].cantidadInt}");
      print(
          "      esta es la promocion ID: ${listFinalProductosSeleccionados[i].promoID}");

      await detallePedido(
          lastClienteNR,
          listFinalProductosSeleccionados[i].id,
          listFinalProductosSeleccionados[i].cantidadInt,
          listFinalProductosSeleccionados[i].promoID);
    }

    await pedidoCancelado();
  }

  //OBTIENE LOS PRODUCTOS DE UNA PROMOCION QUE FUE ELEGIDA CON DETERMINADA CANTIDAD
  Future<dynamic> getProductoDePromo(
      cantidadProm, montoProd, obsevacionProd, descuento, promoID) async {
    print('-------------------------------------------------');
    print('GET PORDUCTOS BY PROMO');
    print('5.2) Este es el api al que ingresa');
    print("$apiUrl$apiProductsbyPromos${promoID.toString()}");
    print('5.3) este es el promoID: ${promoID.toString()}');
    print('   este es el tipo de variabe: ${promoID.toString().runtimeType}');
    print('5.4) este es el cantidadProm: $cantidadProm');
    print('   este es el tipo de variabe: ${cantidadProm.runtimeType}');
    var res = await http.get(
      Uri.parse("$apiUrl$apiProductsbyPromos${promoID.toString()}"),
      headers: {"Content-type": "application/json"},
    );
    try {
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<Producto> tempProducto = data.map<Producto>((mapa) {
          return Producto(
              id: mapa['producto_id'],
              precio: 0.0,
              nombre: mapa['nombre'],
              descripcion: "",
              descuentoDouble: descuento,
              monto: montoProd,
              foto: "",
              observacion: obsevacionProd,
              cantidadInt: mapa['cantidad'] * cantidadProm,
              promoID: mapa['promocion_id']);
        }).toList();

        setState(() {
          print("5.6) Productos  de Promo contabilizados");
          print(tempProducto);
          listFinalProductosSeleccionados.addAll(tempProducto);
          //listProductos = tempProducto;
        });
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> createNR(empleadoID, nombre, apellidos, direccion, telefono,
      email, distrito, latitud, longitud, ruc) async {
    try {
      await http.post(Uri.parse(apiUrl + apiClienteNR),
          headers: {"Content-type": "application/json"},
          body: jsonEncode({
            "empleado_id": empleadoID,
            "nombre": nombre,
            "apellidos": apellidos,
            "direccion": direccion,
            "telefono": telefono,
            "email": email ?? "",
            "distrito": distrito,
            "latitud": latitud,
            "longitud": longitud,
            "ruc": ruc ?? ""
          }));
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  //CREA EL DETALLE DE PEDIDO
  Future<dynamic> detallePedido(
      clienteNrId, productoId, cantidadInt, promoID) async {
    print('---------------------------------');
    print('10.3) DATOS CREADO DE DETALLE PEDIDO');
    await http.post(Uri.parse(apiUrl + apiDetallePedido),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({
          "cliente_nr_id": clienteNrId,
          "producto_id": productoId,
          "cantidad": cantidadInt,
          "promocion_id": promoID
        }));
  }

  //FUNCION QUE OBTIENE EL LAST CLIENTE REGISTRADO
  Future<dynamic> lastClienteNrID(empleadoID) async {
    print('---------------------------------');
    print('7.1) LAST CLIENTE NR');
    print('7.2) este es el api al que ingresa');
    print(apiUrl + apiLastClienteNR + empleadoID.toString());
    var res = await http.get(
        Uri.parse(apiUrl + apiLastClienteNR + empleadoID.toString()),
        headers: {"Content-type": "application/json"});
    try {
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        setState(() {
          lastClienteNR = data[0]['id'];
        });
      }
    } catch (e) {
      print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  //CREA EL PEDIDO
  Future<dynamic> datosCreadoPedido(clienteNrId, fecha, montoTotal, descuento,
      tipo, estado, observacionProd) async {
    print('---------------------------------');
    print('9) DATOS CREADO PEDIDO');
    if (tipo == 'express') {
      montoTotal += 4;
    }
    await http.post(Uri.parse(apiUrl + apiPedidos),
        headers: {"Content-type": "application/json"},
        body: jsonEncode({
          "cliente_nr_id": clienteNrId,
          "subtotal": montoTotal.toDouble(),
          "descuento": descuento,
          "total": montoTotal.toDouble(),
          "fecha": fecha,
          "tipo": tipo,
          "estado": estado,
          "observacion": observacionProd,
        }));
  }

  @override
  void initState() {
    super.initState();
    getTemperature();
    getProducts();
    getPromos();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();


    // Formato para obtener el nombre del mes
    final monthFormat = DateFormat('MMMM');

    // Obtener el nombre del mes
    final monthName = monthFormat.format(now);

    final ancho = MediaQuery.of(context).size.width;
    final alto = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 191, 195, 199),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          physics: MediaQuery.of(context).size.height <=1536 ?
          const NeverScrollableScrollPhysics() : MediaQuery.of(context).size.height >1536
            ? BouncingScrollPhysics() : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABECERA

              Container(
                //color:Colors.grey,
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      //color:Colors.grey,
                        margin: const EdgeInsets.only(left: 20),
                        child:  Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            Text(
                              "Hola,${userProvider.user?.nombre}",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                           const Row(
                              children: [
                                Text(
                                  "Bienvenid@ a ",
                                  style: TextStyle(fontSize: 25),
                                ),
                                Text(
                                  "Agua Sol",
                                  style: TextStyle( fontSize: 25),
                                )
                              ],
                            ),
                          ],
                        )),
                    const SizedBox(
                      width: 50,
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 20),
                      width: 60,
                      height: 60,
                      // color:Colors.blueGrey,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          
                          image: const DecorationImage(
                              image: AssetImage('lib/imagenes/chica.jpg'))),
                    ),
                     Container(
                      margin: const EdgeInsets.only(left: 20),
                      //color: Colors.grey,
                      width: 150,
                      height: 50,
                      child: ElevatedButton(onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Login1()));
                      },
                       style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all((Color.fromARGB(255, 0, 41, 75)))
                       ),
                       child:const Text("Cerrar Sesión",
                       style: TextStyle(fontSize: 15,color: Colors.white),)),
                    ),

                    const SizedBox(
                      width: 150,
                    ),
                    const SizedBox(
                      width: 150,
                    ),
                   
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Text(
                            "Arequipa, ${now.day} de ${monthName} del ${now.year}",
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            "${temperatura.toStringAsFixed(1)} ° C",
                            style: TextStyle(fontSize: 40),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                //width:anchoActual,
                //height:largoActual,
              ),
              Container(
                margin: const EdgeInsets.only(left: 20),
                child: Row(
                  children: [
                    const Text(
                      "Sistema de Pedido",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Container(
                        margin: const EdgeInsets.only(left: 20),
                        width: 60,
                        height: 60,
                        child: Lottie.asset('lib/imagenes/call.json')),
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Armado2()));
                        },
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                            const Color.fromARGB(255, 135, 83, 128))),
                        child: const Text("Sistema de Ruteo >>",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),

              // CONTENIDO
              const SizedBox(
                height: 20,
              ),

              Container(
                height: 1000,
                //height: MediaQuery.of(context).size.height,
                margin: const EdgeInsets.only(left: 20),
                //color: Colors.blue,

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FORMULARIO

                    Container(
                      //color:Colors.green,
                      width:
                          MediaQuery.of(context).size.width <= 1580 ? 300 : 400,
                      height:
                          MediaQuery.of(context).size.height <= 800 ? 700 : 800,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: const Text(
                              "Datos del Cliente",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          SingleChildScrollView(
                            child: Container(
                              //  height: MediaQuery.of(context).size.height/1.45,//1.5,
                              margin: const EdgeInsets.only(bottom: 0),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _nombres,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombres',
                                          hintText: 'Ingrese sus nombres',
                                          isDense: true,
                                          labelStyle: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromARGB(255, 1, 55, 99),
                                          ),
                                          hintStyle: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El campo es obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                        controller: _apellidos,
                                        decoration: InputDecoration(
                                          labelText: 'Apellidos',
                                          hintText: 'Ingrese sus apellidos',
                                          isDense: true,
                                          labelStyle: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromARGB(255, 1, 55, 99),
                                          ),
                                          hintStyle: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El campo es obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                        controller: _direccion,
                                        decoration: InputDecoration(
                                          labelText: 'Direccion',
                                          hintText: 'Ingrese su direccion',
                                          isDense: true,
                                          labelStyle: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromARGB(255, 1, 55, 99),
                                          ),
                                          hintStyle: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El campo es obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                        controller: _telefono,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ], // Añade esta línea
                                        //maxLength: 9,
                                        decoration: InputDecoration(
                                            labelText: 'Teléfono',
                                            hintText: 'Ingrese su teléfono',
                                            isDense: true,
                                            labelStyle: TextStyle(
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 1, 55, 99),
                                            ),
                                            hintStyle: TextStyle(
                                              fontSize: 13.0,
                                              color: Colors.grey,
                                            )),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El campo es obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                        controller: _email,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          hintText: 'Ingrese su email',
                                          isDense: true,
                                          labelStyle: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromARGB(255, 1, 55, 99),
                                          ),
                                          hintStyle: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                        controller: _distrito,
                                        decoration: InputDecoration(
                                          labelText: 'Distrito',
                                          hintText: 'Ingrese su dirección',
                                          isDense: true,
                                          labelStyle: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Color.fromARGB(255, 1, 55, 99),
                                          ),
                                          hintStyle: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'El campo es obligatorio';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _latitud,
                                              decoration: InputDecoration(
                                                  labelText: 'Ubicación(Lat)',
                                                  hintText:
                                                      'Ingrese su ubicación',
                                                  isDense: true,
                                                  labelStyle: TextStyle(
                                                    fontSize: 15.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                        255, 1, 55, 99),
                                                  ),
                                                  hintStyle: TextStyle(
                                                    fontSize: 13.0,
                                                    color: Colors.grey,
                                                  )),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'El campo es obligatorio';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _longitud,
                                              decoration: const InputDecoration(
                                                  labelText: 'Ubicación(Long)',
                                                  hintText:
                                                      'Ingrese su ubicación',
                                                  isDense: true,
                                                  labelStyle: TextStyle(
                                                    fontSize: 15.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                        255, 1, 55, 99),
                                                  ),
                                                  hintStyle: TextStyle(
                                                    fontSize: 13.0,
                                                    color: Colors.grey,
                                                  )),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'El campo es obligatorio';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      TextFormField(
                                        controller: _ruc,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ], // Añade esta línea
                                        maxLength: 11,
                                        decoration: const InputDecoration(
                                            labelText: 'RUC',
                                            hintText: 'Ingrese su RUC',
                                            isDense: true,
                                            labelStyle: TextStyle(
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 1, 55, 99),
                                            ),
                                            hintStyle: TextStyle(
                                              fontSize: 13.0,
                                              color: Colors.grey,
                                            )),
                                      ),
                                      const SizedBox(
                                        height: 50,
                                      ),
                                    ],
                                  )),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 20,
                    ),

                    // PRODUCTOS

                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.width > 1536
                                                      ? 640
                                                      : MediaQuery.of(context).size.width <= 1536 ?
                                                      475 :0,
                          //color:Colors.yellow,
                          width: MediaQuery.of(context).size.width <= 1580
                              ? 420
                              : 700, // //420,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    "Lista de Productos y Promociones",
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              //listview
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  height: MediaQuery.of(context).size.width > 1536
                                                        ? 590
                                                        : MediaQuery.of(context).size.width <= 1536 ?
                                                        420 :0,
                                  width: MediaQuery.of(context).size.width <= 1930 ? 500
                                   : MediaQuery.of(context).size.width <= 1536 ? 600 : 0,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Color.fromARGB(255, 179, 59, 99)),
                                  child: ListView.builder(
                                      scrollDirection: Axis.vertical,
                                      itemCount: listElementos.length, //8
                                      itemBuilder: ((context, index) {
                                        dynamic elementoActual =
                                            listElementos[index];
                                        if (elementoActual is Producto) {
                                          // Producto
                                          Producto producto = elementoActual;
                                
                                          // CONTENEDOR PRINCIPAL
                                
                                          return Container(
                                            margin:
                                                const EdgeInsets.only(top: 10),
                                            padding: const EdgeInsets.all(10),
                                            height: 200,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: const Color.fromARGB(
                                                  255, 58, 75, 108),
                                            ),
                                            child: Row(
                                              children: [
                                                // IMAGENES DE PRODUCTO
                                                Container(
                                                  height: 150,
                                                  width: MediaQuery.of(context).size.width <2220 ? 50: 80,
                                                  decoration: BoxDecoration(
                                                      // color: Colors.grey,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                              producto.foto))),
                                                ),
                                
                                                // DESCRIPCIÓN DE PRODUCTO
                                
                                                Container(
                                                    margin: const EdgeInsets.only(
                                                        left: 20),
                                                    height: 180,
                                                    width: MediaQuery.of(context).size.width > 1536
                                                        ? 200
                                                        : MediaQuery.of(context).size.width <= 1536 ?
                                                        120 :0,
                                                    decoration: BoxDecoration(
                                                      // color: Colors.grey,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          "Presentación:${producto.nombre}",
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        Text(
                                                          "${producto.descripcion}",
                                                          style: const TextStyle(
                                                              fontSize: 20,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        Text(
                                                          "Precio: S/.${producto.precio}",
                                                          style: const TextStyle(
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              color:
                                                                  Color.fromARGB(
                                                                      255,
                                                                      100,
                                                                      237,
                                                                      105)),
                                                        ),
                                                      ],
                                                    )),
                                
                                                // ENTRADAS NUMÉRICAS
                                
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(15),
                                                  margin: const EdgeInsets.only(
                                                      left: 20),
                                                  height: 180,
                                                  width: MediaQuery.of(context)
                                                              .size
                                                              .width <=
                                                          2220
                                                      ? 150
                                                      : 250,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.center,
                                                    children: [
                                                      // CANTIDAD
                                                      TextFormField(
                                                        controller:
                                                            producto.cantidad,
                                                        keyboardType:
                                                            const TextInputType
                                                                .numberWithOptions(
                                                                decimal: true),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .allow(
                                                                  RegExp(r'^\d+'))
                                                        ],
                                                        decoration:
                                                            InputDecoration(
                                                          filled: true,
                                                          fillColor: const Color
                                                              .fromARGB(
                                                              255,
                                                              223,
                                                              225,
                                                              226), // Cambia este color según tus preferencias
                                
                                                          hintText: 'Cantidad',
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(10),
                                                          ),
                                                          hintStyle:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        ),
                                                        onChanged: (value) {
                                                          print(
                                                              "valor detectado: $value");
                                                          print(
                                                              'tipo ${value.runtimeType}');
                                                          // SETEAR DE LA LISTA MIXTA(PROD Y PROMO)
                                                          listElementos[index]
                                                              .cantidad
                                                              .text = value;
                                
                                                          if (value.isNotEmpty) {
                                                            print(
                                                                'tipo ${int.parse(value).runtimeType}');
                                                            setState(() {
                                                              listElementos[index]
                                                                      .cantidadInt =
                                                                  int.parse(
                                                                      value);
                                                              listElementos[index]
                                                                  .monto = int
                                                                      .parse(
                                                                          value) *
                                                                  listElementos[
                                                                          index]
                                                                      .precio;
                                                              print(
                                                                  'este es el monto: ${listElementos[index].monto}');
                                                            });
                                                          }
                                                        },
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                
                                                      // PRECIO
                                
                                                      TextFormField(
                                                        controller:
                                                            producto.descuento,
                                                        keyboardType:
                                                            const TextInputType
                                                                .numberWithOptions(
                                                                decimal: true),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .allow(RegExp(
                                                                  r'^\d+\.?\d{0,2}')),
                                                        ],
                                                        decoration:
                                                            InputDecoration(
                                                          filled: true,
                                                          fillColor: const Color
                                                              .fromARGB(
                                                              255,
                                                              223,
                                                              225,
                                                              226), // Cambia este color según tus preferencias
                                
                                                          hintText:
                                                              'S/. Descuento',
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(10),
                                                          ),
                                                          hintStyle:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        ),
                                                        onChanged: (value) {
                                                          print(
                                                              "0.1) descuento detectado: $value");
                                                          // SETEAR DE LA LISTA MIXTA(PROD Y PROMO)
                                                          listElementos[index]
                                                              .descuento
                                                              .text = value;
                                                          if (value.isNotEmpty) {
                                                            setState(() {
                                                              listElementos[index]
                                                                      .descuentoDouble =
                                                                  int.parse(value)
                                                                      .toDouble();
                                                              listElementos[index]
                                                                  .monto = listElementos[
                                                                          index]
                                                                      .precio *
                                                                  listElementos[
                                                                          index]
                                                                      .cantidadInt;
                                                              print(
                                                                  '0.2) este es el descuento: ${listElementos[index].descuentoDouble}');
                                                            });
                                                          } else {
                                                            print(
                                                                '0.3) no hay descuento');
                                                            setState(() {
                                                              listElementos[index]
                                                                      .descuentoDouble =
                                                                  0.00;
                                                              listElementos[index]
                                                                  .monto = listElementos[
                                                                          index]
                                                                      .precio *
                                                                  listElementos[
                                                                          index]
                                                                      .cantidadInt;
                                                              print(
                                                                  '0.4) este es el monto sin descuento: ${listElementos[index].monto}');
                                                            });
                                                          }
                                
                                                          listElementos[index]
                                                              .monto = listElementos[
                                                                      index]
                                                                  .monto -
                                                              listElementos[index]
                                                                  .descuentoDouble;
                                                          print(
                                                              '0.5) este es el monto con descuento: ${listElementos[index].monto}');
                                                        },
                                                        validator: (value) {
                                                          if (value is String) {
                                                            if (listElementos[
                                                                    index]
                                                                .cantidad
                                                                .isNotEmpty) {
                                                              if (int.parse(value)
                                                                      .toDouble() >=
                                                                  (listElementos[
                                                                              index]
                                                                          .precio *
                                                                      listElementos[
                                                                              index]
                                                                          .cantidadInt)) {
                                                                return 'El descuento debe ser menor al monto: ${listElementos[index].precio * listElementos[index].cantidadInt}';
                                                              } else {
                                                                return null;
                                                              }
                                                            } else {
                                                              return 'Primero debes poner la cantidad';
                                                            }
                                                          }
                                                          return null;
                                                        },
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      ElevatedButton(
                                                          onPressed: producto
                                                                      .descuento
                                                                      .text
                                                                      .isNotEmpty &&
                                                                  producto
                                                                      .cantidad
                                                                      .text
                                                                      .isNotEmpty
                                                              ? () {
                                                                  showModalBottomSheet(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return StatefulBuilder(builder: (BuildContext
                                                                              context,
                                                                          StateSetter
                                                                              setState) {
                                                                        return Container(
                                                                          height:
                                                                              280,
                                                                          width: MediaQuery.of(context)
                                                                              .size
                                                                              .width,
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              16.0),
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              const Text(
                                                                                'Autorizado por:',
                                                                                style: TextStyle(
                                                                                  color: Color.fromARGB(255, 3, 64, 113),
                                                                                  fontSize: 20,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10),
                                                                              TextFormField(
                                                                                controller: producto.nombreAutorizador,
                                                                                style: const TextStyle(
                                                                                  fontSize: 15,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: Color.fromARGB(255, 1, 41, 75),
                                                                                ),
                                                                                decoration: const InputDecoration(
                                                                                  filled: true,
                                                                                  fillColor: Colors.white,
                                                                                  labelText: "Nombre:",
                                                                                  labelStyle: TextStyle(
                                                                                    color: Color.fromARGB(255, 0, 48, 87),
                                                                                    fontSize: 13,
                                                                                  ),
                                                                                ),
                                                                                onChanged: (value) {
                                                                                  print('nombre detectado: $value');
                                                                                  print('tipo ${value.runtimeType}');
                                                                                  setState(() {
                                                                                    listElementos[index].nombreAutorizador.text = value;
                                                                                  });
                                                                                },
                                                                              ),
                                                                              TextFormField(
                                                                                controller: producto.cargoAutorizador,
                                                                                style: const TextStyle(
                                                                                  fontSize: 15,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: Color.fromARGB(255, 1, 41, 75),
                                                                                ),
                                                                                decoration: const InputDecoration(
                                                                                  filled: true,
                                                                                  fillColor: Colors.white,
                                                                                  labelText: "Cargo:",
                                                                                  labelStyle: TextStyle(
                                                                                    color: Color.fromARGB(255, 0, 48, 87),
                                                                                    fontSize: 13,
                                                                                  ),
                                                                                ),
                                                                                onChanged: (value) {
                                                                                  print('cargo detectado: $value');
                                                                                  print('tipo ${value.runtimeType}');
                                                                                  setState(() {
                                                                                    listElementos[index].cargoAutorizador.text = value;
                                                                                  });
                                                                                },
                                                                              ),
                                                                              const SizedBox(height: 10),
                                                                              ElevatedButton(
                                                                                onPressed: producto.cargoAutorizador.text.isNotEmpty && producto.nombreAutorizador.text.isNotEmpty
                                                                                    ? () {
                                                                                        print("datos de observacion añadidos");
                                                                                        setState(() {
                                                                                          producto.observacion = "Descuento de S/.${producto.descuentoDouble} en ${producto.nombre} aprobado por ${producto.nombreAutorizador.text} - ${producto.cargoAutorizador.text}";
                                                                                          print(producto.observacion);
                                                                                        });
                                                                                        Navigator.pop(context);
                                                                                      }
                                                                                    : null,
                                                                                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 35, 74, 106))),
                                                                                child: const Row(
                                                                                  children: [
                                                                                    Icon(
                                                                                      Icons.account_box_outlined,
                                                                                      color: Colors.blue,
                                                                                      size: 25,
                                                                                    ),
                                                                                    Text(
                                                                                      ' Confirmar',
                                                                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Color.fromARGB(255, 77, 231, 82)),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      });
                                                                    },
                                                                  );
                                                                }
                                                              : null,
                                                          child:
                                                              Text("Confirmar?"))
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else if (elementoActual is Promo) {
                                          // Promos
                                          Promo promo = elementoActual;
                                
                                          // CONTENEDOR PRINCIPAL
                                          return Container(
                                            margin:
                                                const EdgeInsets.only(top: 10),
                                            padding: const EdgeInsets.all(10),
                                            height: 200,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: const Color.fromARGB(
                                                  255, 58, 75, 108),
                                            ),
                                            child: Row(
                                              children: [
                                                // IMAGENES DE PRODUCTO
                                                Container(
                                                  height: 150,
                                                   width: MediaQuery.of(context).size.width > 1536
                                                        ? 90
                                                        : MediaQuery.of(context).size.width <= 1536 ?
                                                        80 :0,
                                                  decoration: BoxDecoration(
                                                      // color: Colors.grey,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                              promo.foto))),
                                                ),
                                
                                                // DESCRIPCIÓN DE PRODUCTO
                                
                                                Container(
                                                    margin: const EdgeInsets.only(
                                                        left: 20),
                                                    height: 180,
                                                    width: MediaQuery.of(context).size.width > 1536
                                                        ? 160
                                                        : MediaQuery.of(context).size.width <= 1536 ?
                                                        80 :0,
                                                    decoration: BoxDecoration(
                                                      // color: Colors.grey,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          "Presentación:${promo.nombre}",
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        Text(
                                                          "${promo.descripcion}",
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        Text(
                                                          "Precio: S/.${promo.precio}",
                                                          style: const TextStyle(
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              color:
                                                                  Color.fromARGB(
                                                                      255,
                                                                      205,
                                                                      237,
                                                                      100)),
                                                        ),
                                                      ],
                                                    )),
                                
                                                // ENTRADAS NUMÉRICAS
                                
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(15),
                                                  margin: const EdgeInsets.only(
                                                      left: 20),
                                                  height: 180,
                                                  width: MediaQuery.of(context).size  .width < 1536 ? 150
                                                      : MediaQuery.of(context).size.width >=1536 ? 160 :0,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.center,
                                                    children: [
                                                      // CANTIDAD
                                                      TextFormField(
                                                        controller:
                                                            promo.cantidad,
                                                        keyboardType:
                                                            TextInputType.number,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .allow(RegExp(
                                                                  r'^\d+')),
                                                        ],
                                                        decoration:
                                                            InputDecoration(
                                                          filled: true,
                                                          fillColor: const Color
                                                              .fromARGB(
                                                              255,
                                                              223,
                                                              225,
                                                              226), // Cambia este color según tus preferencias
                                
                                                          hintText: 'Cantidad',
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(10),
                                                          ),
                                                          hintStyle:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        ),
                                                        onChanged: (value) {
                                                          print(
                                                              "valor detectado: $value");
                                                          print(
                                                              'tipo ${value.runtimeType}');
                                                          // SETEAR DE LA LISTA MIXTA(PROD Y PROMO)
                                                          listElementos[index]
                                                              .cantidad
                                                              .text = value;
                                
                                                          if (value.isNotEmpty) {
                                                            print(
                                                                'tipo ${int.parse(value).runtimeType}');
                                                            setState(() {
                                                              listElementos[index]
                                                                      .cantidadInt =
                                                                  int.parse(
                                                                      value);
                                                              listElementos[index]
                                                                  .monto = int
                                                                      .parse(
                                                                          value) *
                                                                  listElementos[
                                                                          index]
                                                                      .precio;
                                                              print(
                                                                  'este es el monto: ${listElementos[index].monto}');
                                                            });
                                                          }
                                                        },
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                
                                                      // PRECIO
                                
                                                      TextFormField(
                                                        controller:
                                                            promo.descuento,
                                                        keyboardType:
                                                            const TextInputType
                                                                .numberWithOptions(
                                                                decimal: true),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .allow(RegExp(
                                                                  r'^\d+\.?\d{0,2}')),
                                                        ],
                                                        decoration:
                                                            InputDecoration(
                                                          filled: true,
                                                          fillColor: const Color
                                                              .fromARGB(
                                                              255,
                                                              223,
                                                              225,
                                                              226), // Cambia este color según tus preferencias
                                
                                                          hintText:
                                                              'S/. Descuento',
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(10),
                                                          ),
                                                          hintStyle:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        ),
                                                        onChanged: (value) {
                                                          print(
                                                              "0.1) descuento detectado: $value");
                                                          // SETEAR DE LA LISTA MIXTA(PROD Y PROMO)
                                                          listElementos[index]
                                                              .descuento
                                                              .text = value;
                                                          if (value.isNotEmpty) {
                                                            setState(() {
                                                              listElementos[index]
                                                                      .descuentoDouble =
                                                                  int.parse(value)
                                                                      .toDouble();
                                                              listElementos[index]
                                                                  .monto = listElementos[
                                                                          index]
                                                                      .precio *
                                                                  listElementos[
                                                                          index]
                                                                      .cantidadInt;
                                                              print(
                                                                  '0.2) este es el descuento: ${listElementos[index].descuentoDouble}');
                                                            });
                                                          } else {
                                                            print(
                                                                '0.3) no hay descuento');
                                                            setState(() {
                                                              listElementos[index]
                                                                      .descuentoDouble =
                                                                  0.00;
                                                              listElementos[index]
                                                                  .monto = listElementos[
                                                                          index]
                                                                      .precio *
                                                                  listElementos[
                                                                          index]
                                                                      .cantidadInt;
                                                              print(
                                                                  '0.4) este es el monto sin descuento: ${listElementos[index].monto}');
                                                            });
                                                          }
                                
                                                          listElementos[index]
                                                              .monto = listElementos[
                                                                      index]
                                                                  .monto -
                                                              listElementos[index]
                                                                  .descuentoDouble;
                                                          print(
                                                              '0.5) este es el monto con descuento: ${listElementos[index].monto}');
                                                        },
                                                        validator: (value) {
                                                          if (value is String) {
                                                            if (listElementos[
                                                                    index]
                                                                .cantidad
                                                                .isNotEmpty) {
                                                              if (int.parse(value)
                                                                      .toDouble() >=
                                                                  (listElementos[
                                                                              index]
                                                                          .precio *
                                                                      listElementos[
                                                                              index]
                                                                          .cantidadInt)) {
                                                                return 'El descuento debe ser menor al monto: ${listElementos[index].precio * listElementos[index].cantidadInt}';
                                                              } else {
                                                                return null;
                                                              }
                                                            } else {
                                                              return 'Primero debes poner la cantidad';
                                                            }
                                                          }
                                                          return null;
                                                        },
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      ElevatedButton(
                                                          onPressed:
                                                              promo.descuentoDouble >
                                                                          0 &&
                                                                      promo.cantidadInt >
                                                                          0
                                                                  ? () {
                                                                      showModalBottomSheet(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (BuildContext
                                                                                context) {
                                                                          return StatefulBuilder(builder: (BuildContext
                                                                                  context,
                                                                              StateSetter
                                                                                  setState) {
                                                                            return Container(
                                                                              height:
                                                                                  280,
                                                                              width:
                                                                                  MediaQuery.of(context).size.width,
                                                                              padding:
                                                                                  const EdgeInsets.all(16.0),
                                                                              child:
                                                                                  Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  const Text(
                                                                                    'Autorizado por:',
                                                                                    style: TextStyle(
                                                                                      color: Color.fromARGB(255, 3, 64, 113),
                                                                                      fontSize: 20,
                                                                                      fontWeight: FontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 10),
                                                                                  TextFormField(
                                                                                    controller: promo.nombreAutorizador,
                                                                                    style: const TextStyle(
                                                                                      fontSize: 15,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      color: Color.fromARGB(255, 1, 41, 75),
                                                                                    ),
                                                                                    decoration: const InputDecoration(
                                                                                      filled: true,
                                                                                      fillColor: Colors.white,
                                                                                      labelText: "Nombre:",
                                                                                      labelStyle: TextStyle(
                                                                                        color: Color.fromARGB(255, 0, 48, 87),
                                                                                        fontSize: 13,
                                                                                      ),
                                                                                    ),
                                                                                    onChanged: (value) {
                                                                                      setState(() {
                                                                                        listElementos[index].nombreAutorizador.text = value;
                                                                                      });
                                                                                    },
                                                                                  ),
                                                                                  TextFormField(
                                                                                    controller: promo.cargoAutorizador,
                                                                                    style: const TextStyle(
                                                                                      fontSize: 15,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      color: Color.fromARGB(255, 1, 41, 75),
                                                                                    ),
                                                                                    decoration: const InputDecoration(
                                                                                      filled: true,
                                                                                      fillColor: Colors.white,
                                                                                      labelText: "Cargo:",
                                                                                      labelStyle: TextStyle(
                                                                                        color: Color.fromARGB(255, 0, 48, 87),
                                                                                        fontSize: 13,
                                                                                      ),
                                                                                    ),
                                                                                    onChanged: (value) {
                                                                                      setState(() {
                                                                                        listElementos[index].cargoAutorizador.text = value;
                                                                                      });
                                                                                    },
                                                                                  ),
                                                                                  const SizedBox(height: 10),
                                                                                  ElevatedButton(
                                                                                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 1, 62, 111))),
                                                                                    onPressed: promo.cargoAutorizador.text.isNotEmpty && promo.nombreAutorizador.text.isNotEmpty
                                                                                        ? () {
                                                                                            print("datos de observacion añadidos");
                                                                                            setState(() {
                                                                                              promo.observacion = "Descuento aprobado por ${promo.nombreAutorizador.text} - ${promo.cargoAutorizador.text}";
                                                                                              print(promo.observacion);
                                                                                            });
                                                                                            Navigator.pop(context);
                                                                                          }
                                                                                        : null,
                                                                                    child: const Row(
                                                                                      children: [
                                                                                        Icon(
                                                                                          Icons.account_box_outlined,
                                                                                          color: Colors.blue,
                                                                                          size: 25,
                                                                                        ),
                                                                                        Text(
                                                                                          ' Confirmar',
                                                                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Color.fromARGB(255, 77, 231, 82)),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            );
                                                                          });
                                                                        },
                                                                      );
                                                                    }
                                                                  : null,
                                                          child:
                                                              Text("Confirmar?"))
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return Container(
                                            child: Text("NO PRODUCTS"),
                                          );
                                        }
                                
                                        // Producto producto = listProducts[index];
                                      })),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 15, bottom: 15),
                          child: const Text(
                            "Tipo de Pedido",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        Container(
                          height: 50,
                          width: MediaQuery.of(context).size.width <= 1580
                              ? 420
                              : 500,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey),
                          child: Center(
                            child: DropdownButton<String>(
                              value: tipo,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              hint: const Text('Seleccionar Tipo de Pedido'),
                              icon: const Icon(Icons.arrow_drop_down_circle),
                              onChanged: (value) {
                                setState(() {
                                  tipo = value;
                                });
                              },
                              items: dropdownItems,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      width: 20,
                    ),

                    // UBICACIÓN

                    Container(
                     // color:Colors.red,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              "Ubicación",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          Container(
                              padding: const EdgeInsets.all(10),
                              width: 500,
                              height:MediaQuery.of(context).size.width > 1536 ?
                               700 : MediaQuery.of(context).size.width <=1536 ?
                               530 : 0,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.grey),
                              // padding: const EdgeInsets.all(9),

                              //padding: const EdgeInsets.all(20),
                              child: OpenStreetMapSearchAndPick(
                                buttonTextStyle: TextStyle(fontSize: 12),
                                buttonColor:
                                    const Color.fromARGB(255, 40, 69, 92),
                                buttonText: 'Obtener coordenadas',
                                onPicked: (pickedData) {
                                  setState(() {
                                    //direccion = pickedData.addressName;
                                    String road =
                                        pickedData.address['road'] ?? '';
                                    String neighbourhood =
                                        pickedData.address['neighbourhood'] ??
                                            '';
                                    String city =
                                        pickedData.address['city'] ?? '';
                                    var latitude = pickedData.latLong.latitude;
                                    var longitude =
                                        pickedData.latLong.longitude;

                                    _direccion.text = '$road $neighbourhood';
                                    _distrito.text = '$city';
                                    _latitud.text = '$latitude';
                                    _longitud.text = '$longitude';
                                  });
                                  print(pickedData.latLong.latitude);
                                  print(pickedData.latLong.longitude);
                                  print(pickedData.address);
                                  print(pickedData.addressName);
                                  print("-----------------");
                                  print(pickedData.address['city']);
                                  print("---OBJETO DIRECCIÓN---");
                                  print(pickedData.address.values);
                                },
                              )),
                        ],
                      ),
                    ),

                    // BOTONES REGISTROS
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      height: 600,
                      //color:Colors.cyan,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              height: 200,
                              width: 200,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if(_formKey.currentState!.validate()){
                                               await calculoDeSeleccionadosYMontos();
                                        showDialog<String>(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                AlertDialog(
                                                  title: const Text(
                                                      'Vas a registrar el pedido'),
                                                  content: const Text(
                                                      '¿Estas segur@?'),
                                                  actions: <Widget>[
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        pedidoCancelado();
                                                        Navigator.pop(context,
                                                            'Cancelar');
                                                      },
                                                      child: const Text(
                                                          'Cancelar'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: listFinalProductosSeleccionados
                                                                  .isNotEmpty &&
                                                              montoTotalPedido >=
                                                                  montoMinimo
                                                          ? () async {
                                                              print(
                                                                  '1) Se presiona el botón de registar');
                                                              await crearClienteNRmPedidoyDetallePedido(
                                                                  empleadoID,
                                                                  tipo);
                                                            }
                                                          : null,
                                                      child: const Text('SI'),
                                                    ),
                                                  ],
                                                ));
                                      }
                                    
                                  },
                             
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        const Color.fromARGB(
                                            255, 35, 74, 106))),
                                child: const Text(
                                  '¿ Registrar ?',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 25),
                                ),
                              )),
                          Container(
                            margin: const EdgeInsets.only(top: 70),
                            height: 320,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(20),
                                image: const DecorationImage(
                                    image: AssetImage(
                                        'lib/imagenes/botellasuper.jpg'),
                                    fit: BoxFit.cover)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /**/
            ],
          ),
        ),
      )),
    );
  }
}
