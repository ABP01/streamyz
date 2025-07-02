import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:zego_zim/zego_zim.dart';

import 'views/home/home_page.dart';

Future<void> main() async {
  var appID = 646767905;
  var appSign = "e344270b3a92a09da043bb179a9642f3827bd0d35d6caf4553fa22d4a8419e26";
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Suppression de l'initialisation et de la connexion ZEGOCLOUD

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streamyz',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          // Redirection vers la page d'accueil après connexion Firebase
          return const HomePage();
        } else {
          // Redirige vers la page de login si besoin
          return const Scaffold(
            body: Center(child: Text('Veuillez vous connecter.')),
          );
        }
      },
    );
  }
}
