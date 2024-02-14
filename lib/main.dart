import 'package:desktopapp/components/empleado/login1.dart';
import 'package:desktopapp/components/empleado/updatearruta.dart';
import 'package:desktopapp/components/provider/ruta_provider.dart';
import 'package:desktopapp/components/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';


Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        
        ChangeNotifierProvider(
          create:(_) => RutaProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // transitionOnUserGestures: false,
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: const Update(),
      ),
    );
  }
}

// Resto del código sigue siendo el mismo...
