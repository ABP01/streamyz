import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      // body: Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       const Text(
      //         'This is the Signup page',
      //       ),
      //       ElevatedButton(
      //         onPressed: () {
      //           // Navigate to the login page
      //           Navigator.pushNamed(context, '/login');
      //         },
      //         child: const Text('Go to Login'),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}