import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/views/home/home_page.dart';
import 'package:zego_zim/zego_zim.dart';

import 'views/auth/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initZegoCloud();
  runApp(const MyApp());
}

void initZegoCloud() {
  final appConfig = ZIMAppConfig()
    ..appID = 646767905
    ..appSign =
        'e344270b3a92a09da043bb179a9642f3827bd0d35d6caf4553fa22d4a8419e26';
  ZIM.create(appConfig);
}

// Corrected the ZIM login method to use the proper arguments and removed unused variables.
Future<void> connectZegoUser(String userID, String userName) async {
  ZIMLoginConfig loginConfig = ZIMLoginConfig();
  ZIM.getInstance()!.login(userID, loginConfig);
  debugPrint('ZEGOCLOUD login success');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streamyz',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF6F00), // Orange
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFFF6F00), // Orange
          secondary: const Color(0xFF001F3F), // Bleu marine
          background: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF001F3F), // Bleu marine
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6F00), // Orange
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF001F3F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6F00), width: 2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFF6F00),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF001F3F),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Color(0xFF001F3F)),
        ),
      ),
      home: const LoginPage(), // Set LoginPage as the initial screen
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
          // Connexion ZEGOCLOUD à chaque login Firebase
          final user = snapshot.data!;
          connectZegoUser(user.uid, user.displayName ?? user.email ?? user.uid);
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
