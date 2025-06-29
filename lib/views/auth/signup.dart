import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_page.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  GlobalKey<FormState> key = GlobalKey<FormState>();
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

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
                controller: _usernameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Username",
                ),
                validator: ValidationBuilder().maxLength(10).build(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Email",
                ),
                validator: ValidationBuilder().email().build(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                ),
                validator: ValidationBuilder()
                    .maxLength(15)
                    .minLength(6)
                    .build(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    print("Sign up button clicked");
                    if (key.currentState?.validate() ?? false) {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;
                      final username = _usernameController.text.trim();
                      print("Form validated: email=$email, username=$username");
                      if (email.isEmpty ||
                          password.isEmpty ||
                          username.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez remplir tous les champs.'),
                          ),
                        );
                        return;
                      }
                      try {
                        print("Attempting to sign up user");
                        final authResponse = await Supabase.instance.client.auth
                            .signUp(email: email, password: password);
                        final user = authResponse.user;
                        print("Sign up response: user=${user?.id}");
                        if (user != null) {
                          print("Inserting user data into database");
                          final insertResponse = await Supabase.instance.client
                              .from('users')
                              .insert({
                                'id': user.id,
                                'email': email,
                                'username': username,
                                'created_at': DateTime.now().toIso8601String(),
                              });
                          print("Insert response: error=${insertResponse.error}");
                          if (insertResponse.error == null) {
                            if (mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Le compte est créé, mais une erreur est survenue lors de l\'enregistrement des données Supabase.',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      } on AuthException catch (e) {
                        print("AuthException: ${e.message}");
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.message)));
                      } catch (e) {
                        print("Unexpected error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Une erreur s\'est produite.'),
                          ),
                        );
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
