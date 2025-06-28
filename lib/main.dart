import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:streamyz/views/auth/login.dart';
import 'package:streamyz/views/auth/signup.dart';
import 'package:streamyz/views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streamyz',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        fontFamily: GoogleFonts.poppins().fontFamily,
        primaryColor: Colors.deepOrangeAccent[700],
      ),
      home: FirebaseAuth.instance.currentUser == null ? LoginPage() : HomePage(),
    );
  }
}
