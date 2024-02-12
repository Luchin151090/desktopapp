import 'package:desktopapp/components/empleado/armadodo2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class Update extends StatefulWidget {
  const Update({Key? key}) : super(key: key);
  @override
  State<Update> createState() => _UpdateState();
}
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: onSelectNotification,
  );
}

Future<void> onSelectNotification(String? payload) async {
  if (payload != null) {
    debugPrint('Notificación seleccionada con payload: $payload');
  }
}

void mostrarNotificacion(String tipo) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    'channel_description',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Nuevo Pedido $tipo',
    '¡Ha llegado un nuevo pedido $tipo!',
    platformChannelSpecifics,
    payload: tipo,
  );
}

void procesarNuevoPedido(dynamic data) {
  String tipo = data['tipo'];
  // Tu lógica para procesar el nuevo pedido

  // Muestra la notificación
  mostrarNotificacion(tipo);
}
class _UpdateState extends State<Update> {
  // VARIABLES

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: Colors.amber,
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [],
              ),
            ],
          ),
           // SISTEMA DE PEDIDO
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
                                .withOpacity(0.8))),
                  ),
                ),
              ),
               // SISTEMA DE PEDIDO
              Positioned(
                top: 80,
                left: 10,
                child: Container(
                  height: 50,
                  width: 150,
                  color: Colors.amber,

                ),
              ),
              ElevatedButton(
          onPressed: () {
            // Simula la llegada de un nuevo pedido normal
            procesarNuevoPedido({'tipo': 'normal'});
          },
          child: Text('Simular Pedido Normal'),
        ),

        ],
      ),
    )));
  }
}
