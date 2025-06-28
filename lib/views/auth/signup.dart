import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  String? email;
  String? password;
  String? username;

  GlobalKey<FormState> key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: Form(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Username",
                ),
                validator: ValidationBuilder().maxLength(10).build(),
                onChanged: (value) {
                  username = value;
                },
              ),
              SizedBox(height: 20),

              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Email",
                ),
                validator: ValidationBuilder().email().maxLength(50).build(),
                onChanged: (value) {
                  email = value;
                },
              ),

              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                ),
                validator: ValidationBuilder()
                    .maxLength(15)
                    .minLength(6)
                    .build(),
                onChanged: (value) {
                  password = value;
                },
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    if (key.currentState?.validate() ?? false) {
                      print(email);
                      try {
                        await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                              email: email!,
                              password: password!,
                            );
                        print("User Created");
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'weak-password') {
                          print('The password provided is too weak.');
                        } else if (e.code == 'email-already-in-use') {
                          print('The account already exists for that email.');
                        } else {
                          print('Error: \\${e.message}');
                        }
                      } catch (e) {
                        print("Error: $e");
                      }
                    }
                  },
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
