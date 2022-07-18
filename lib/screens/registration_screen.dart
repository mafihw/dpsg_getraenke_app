import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/not_verified_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
  final TextEditingController confirmPasswordTextController =
      TextEditingController();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 35.0, vertical: 20),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
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
                              onEditingComplete: () {
                                pageController.nextPage(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOutSine);
                              },
                            ),
                            TextField(
                              controller: emailTextController,
                              keyboardType: TextInputType.emailAddress,
                              focusNode: emailFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Email',
                              ),
                              onEditingComplete: () {
                                pageController.nextPage(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOutSine);
                              },
                            ),
                            TextField(
                              controller: passwordTextController,
                              obscureText: true,
                              focusNode: passwordFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Passwort',
                              ),
                              onEditingComplete: () {
                                pageController.nextPage(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOutSine);
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
                                if (await GetIt.instance<Backend>().register(
                                  emailTextController.text,
                                  passwordTextController.text,
                                  nameTextController.text,
                                )) {
                                  if (GetIt.instance<Backend>()
                                          .loggedInUser!
                                          .role !=
                                      'none') {
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => HomeScreen()),
                                        (route) => false);
                                  } else {
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                NotVerifiedScreen(true)),
                                        (route) => false);
                                  }
                                  setState(() {
                                    currentlyLoggingIn = false;
                                  });
                                } else {
                                  const snackBar = SnackBar(
                                    content:
                                        Text('Registrierung fehlgeschlagen!'),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
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
                    ])),
              ),
            )),
        onWillPop: () {
          return backButtonPressed();
        });
  }

  Future<bool> backButtonPressed() {
    if (pageController.page == 0) {
      return Future.value(true);
    } else {
      pageController.previousPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutSine);
      return Future.value(false);
    }
  }
}
