
import 'package:flutter/material.dart';
import 'package:desktopapp/components/model/user_model.dart';
class RutaProvider extends ChangeNotifier {
  // CREAS UNA INSTANCIA DE LA CLASE
  int _idruta =0;

  // OBTIENES EL USUARIO
  int get ruta => _idruta;

  // ACTUALIZAS EL VALOR DEL OBJETO Y NOTIFICAMOS A LOS RECEPTORES
  void updateUser(int newIdRuta) {
    _idruta = newIdRuta;
    notifyListeners();
  }
}