import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:zego_zim/zego_zim.dart';

import 'views/home/home_page.dart';

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
