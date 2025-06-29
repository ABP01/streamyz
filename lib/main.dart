import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:streamyz/views/auth/login.dart';
import 'package:streamyz/views/home/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ztrdsbebnvbaqehxjxff.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0cmRzYmVibnZiYXFlaHhqeGZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3NzI1MDQsImV4cCI6MjA2NjM0ODUwNH0.6RCSrUi2psCGgJxa_8CWR2PywcF9ZCUdw1qZIo1cEfo',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streamyz',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        fontFamily: GoogleFonts.poppins().fontFamily,
        primaryColor: Colors.deepOrangeAccent[700],
      ),
      home: session == null ? LoginPage() : HomePage(),
    );
  }
}
