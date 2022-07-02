import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final TextEditingController emailTextController = TextEditingController();
    final TextEditingController passwordTextController = TextEditingController();
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
                      labelText: 'Password',
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(onPressed: () {}, child: Text('Register')),
                      ElevatedButton(
                          onPressed: () {
                            login(emailTextController.text, passwordTextController.text);
                          },
                          child: Text('Login')),
                    ],
                  )
            ]),
          ),
        ));
  }

  void login(String email, String password) async {
    final response = await http.post(
        Uri.parse('http://api.dpsg-gladbach.de:3000/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json'
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password
        })
    );
    developer.log(response.statusCode.toString());
    developer.log(response.body);
    if(response.statusCode == 200){
      final directory = await getApplicationDocumentsDirectory();
      final path = await directory.path;
      final file = await File('$path/loginInformation.txt');

      file.writeAsString(response.body);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const HomeScreen()));
    }

  }
}
