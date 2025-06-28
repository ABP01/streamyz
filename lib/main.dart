import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/views/signup.dart';

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
        primaryColor: Colors.deepOrangeAccent[700],
      ),
      home: const Signup(),
    );
  }
}
