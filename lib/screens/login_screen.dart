import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/not_verified_screen.dart';
import 'package:dpsg_app/screens/registration_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
        backgroundColor: kBackgroundColor,
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
                          await GetIt.instance<Backend>().refreshData();
                          if (GetIt.instance<Backend>().loggedInUser!.role !=
                              'none') {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomeScreen()),
                                (route) => false);
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: ((context) =>
                                        NotVerifiedScreen())));
                          }
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
}
