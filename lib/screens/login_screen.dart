import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailTextController = TextEditingController();
  final TextEditingController passwordTextController = TextEditingController();

  bool currentlyLoggingIn = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Login'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 20),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              const Hero(
                tag: 'icon_hero',
                child: Image(
                  image: AssetImage('assets/icon_2500px.png'),
                  height: 150.0,
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: emailTextController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller: passwordTextController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrationScreen(),
                        ),
                      );
                  },
                      child: Text('Registrieren')),
                  ElevatedButton(
                    onPressed: () async {
                      if (!currentlyLoggingIn) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          currentlyLoggingIn = true;
                        });
                        if (await GetIt.instance<Backend>().login(
                            emailTextController.text,
                            passwordTextController.text)) {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomeScreen()),
                              (route) => false);
                          setState(() {
                            currentlyLoggingIn = false;
                          });
                        } else {
                          const snackBar = SnackBar(
                            content: Text('Login fehlgeschlagen!'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          setState(() {
                            currentlyLoggingIn = false;
                          });
                        }
                      }
                    },
                    child: currentlyLoggingIn
                        ? SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                                color: Colors.blue.shade800))
                        : const Text('Anmelden'),
                  ),
                ],
              )
            ]),
          ),
        ));
  }

  void login(String email, String password) async {
    final response = await http.post(
        Uri.parse('http://api.dpsg-gladbach.de:3000/auth/login'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body:
            jsonEncode(<String, String>{'email': email, 'password': password}));
    developer.log(response.statusCode.toString());
    developer.log(response.body);
    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final path = await directory.path;
      final file = await File('$path/loginInformation.txt');

      file.writeAsString(response.body);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
  }
}
