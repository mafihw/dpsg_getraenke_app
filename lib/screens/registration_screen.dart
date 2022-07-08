import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:dpsg_app/connection/backend.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameTextController = TextEditingController();
  final TextEditingController emailTextController = TextEditingController();
  final TextEditingController passwordTextController = TextEditingController();
  final TextEditingController confirmPasswordTextController = TextEditingController();
  final PageController pageController = PageController();

  late FocusNode nameFocusNode = FocusNode();
  late FocusNode emailFocusNode = FocusNode();
  late FocusNode passwordFocusNode = FocusNode();
  late FocusNode confirmPasswordFocusNode = FocusNode();

  bool currentlyLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: const Text('Registrierung'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 20),
                child:
                SingleChildScrollView(
                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Hero(
                        tag: 'icon_hero',
                        child: Image(
                          image: AssetImage('assets/icon_2500px.png'),
                          height: 150.0,
                        ),
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                      SizedBox(
                        height: 50,
                        child: PageView(
                          /// [PageView.scrollDirection] defaults to [Axis.horizontal].
                          /// Use [Axis.vertical] to scroll vertically.
                          controller: pageController,
                          onPageChanged: (page) {
                            switch (page) {
                              case (0):
                                nameFocusNode.requestFocus();
                                break;
                              case (1):
                                emailFocusNode.requestFocus();
                                break;
                              case (2):
                                passwordFocusNode.requestFocus();
                                break;
                              case (3):
                                confirmPasswordFocusNode.requestFocus();
                                break;
                            }
                          },
                          children: <Widget>[
                            TextField(
                              controller: nameTextController,
                              keyboardType: TextInputType.name,
                              autofocus: true,
                              focusNode: nameFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Name',
                              ),
                              onEditingComplete: (){
                                pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutSine);
                              },
                            ),
                            TextField(
                              controller: emailTextController,
                              keyboardType: TextInputType.emailAddress,
                              focusNode: emailFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Email',
                              ),
                              onEditingComplete: (){
                                pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutSine);
                              },
                            ),
                            TextField(
                              controller: passwordTextController,
                              obscureText: true,
                              focusNode: passwordFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Passwort',
                              ),
                              onEditingComplete: (){
                                pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutSine);
                              },
                            ),
                            TextField(
                              controller: confirmPasswordTextController,
                              obscureText: true,
                              focusNode: confirmPasswordFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Passwort wiederholen',
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                              onPressed: () {
                                backButtonPressed();
                              },
                              child: Text('zurück')),
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
                                : const Text('Registrieren'),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                    ])
                ),
              ),
            )),
        onWillPop: () {
          return backButtonPressed();
        }
    );
  }

  Future<bool> backButtonPressed() {
    if(pageController.page == 0){
      return Future.value(true);
    } else {
      pageController.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutSine);
      return Future.value(false);
    }
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
