
import 'package:flutter/material.dart';
import 'package:desktopapp/components/model/user_model.dart';
class UserProvider extends ChangeNotifier {
  // CREAS UNA INSTANCIA DE LA CLASE
  UserModel? _user;

  // OBTIENES EL USUARIO
  UserModel? get user => _user;

  // ACTUALIZAS EL VALOR DEL OBJETO Y NOTIFICAMOS A LOS RECEPTORES
  void updateUser(UserModel newUser) {
    _user = newUser;
    notifyListeners();
  }
}