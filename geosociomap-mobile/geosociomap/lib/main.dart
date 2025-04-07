// import 'package:geosociomap/screens/login_screen.dart';
// import 'package:geosociomap/screens/signup_screen.dart';
// import 'package:geosociomap/screens/welcome.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geosociomap/hive/hiveService.dart';
import 'package:geosociomap/screens/auth_screen.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await MongoDatabase.connect();
  WidgetsFlutterBinding.ensureInitialized();
  // String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
  final hiveService = HiveService();
  await hiveService.initHive();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.sarabun(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ),
      ),  
      home: const AuthPage(),
    );
  }
}
