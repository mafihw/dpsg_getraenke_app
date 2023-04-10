import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/not_verified_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
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

  late FocusNode nameFocusNode = FocusNode();
  late FocusNode emailFocusNode = FocusNode();
  late FocusNode passwordFocusNode = FocusNode();
  late FocusNode confirmPasswordFocusNode = FocusNode();

  bool _nameValid = true;
  bool _mailValid = true;
  bool _passwordValid = true;
  bool _passwordCheckValid = true;

  bool currentlyLoggingIn = false;

  bool validation() {
    return nameTextController.text.isNotEmpty &&
        RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(emailTextController.text) &&
        passwordTextController.text.length >= 8 &&
        confirmPasswordTextController.text == passwordTextController.text;
  }

  bool validateName() {
    _nameValid = nameTextController.text.isNotEmpty;
    return _nameValid;
  }

  bool validateMail() {
    _mailValid = RegExp(
            r'''(?:[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])''')
        .hasMatch(emailTextController.text);
    return _mailValid;
  }

  bool validatePassword() {
    _passwordValid = passwordTextController.text.length >= 8 ||
        passwordTextController.text.isEmpty;
    return _passwordValid;
  }

  bool validatePasswordConfirm() {
    _passwordCheckValid =
        confirmPasswordTextController.text == passwordTextController.text;
    return _passwordCheckValid;
  }

  @override
  Widget build(BuildContext context) {
    var validBorder = OutlineInputBorder(
      borderSide: BorderSide(color: colors(context).onBackground, width: 1.0),
    );

    var invalidBorder = OutlineInputBorder(
      borderSide: BorderSide(color: colors(context).error, width: 1.0),
    );
    return Scaffold(
        backgroundColor: colors(context).background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Registrierung'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Hero(
                    tag: 'icon_hero',
                    child: Image(
                      image: AssetImage('assets/icon_500px.png'),
                      height: 150.0,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    textInputAction: TextInputAction.next,
                    controller: nameTextController,
                    keyboardType: TextInputType.name,
                    autofocus: true,
                    focusNode: nameFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      focusedBorder: _nameValid ? validBorder : invalidBorder,
                      enabledBorder: _nameValid ? validBorder : invalidBorder,
                    ),
                    onChanged: (value) {
                      setState(() {
                        validateName();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    textInputAction: TextInputAction.next,
                    controller: emailTextController,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: emailFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      focusedBorder: _mailValid ? validBorder : invalidBorder,
                      enabledBorder: _mailValid ? validBorder : invalidBorder,
                    ),
                    onChanged: (value) {
                      setState(() {
                        validateMail();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    textInputAction: TextInputAction.next,
                    controller: passwordTextController,
                    obscureText: true,
                    focusNode: passwordFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      focusedBorder:
                          _passwordValid ? validBorder : invalidBorder,
                      enabledBorder:
                          _passwordValid ? validBorder : invalidBorder,
                    ),
                    onChanged: (value) {
                      setState(() {
                        validatePassword();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    textInputAction: TextInputAction.done,
                    controller: confirmPasswordTextController,
                    obscureText: true,
                    focusNode: confirmPasswordFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Passwort wiederholen',
                      focusedBorder:
                          _passwordCheckValid ? validBorder : invalidBorder,
                      enabledBorder:
                          _passwordCheckValid ? validBorder : invalidBorder,
                    ),
                    onChanged: (value) {
                      setState(() {
                        validatePasswordConfirm();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                          onPressed: () {
                            backButtonPressed();
                          },
                          child: Text('Zurück')),
                      ElevatedButton(
                        onPressed: validation()
                            ? () async {
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
                                              builder: (context) =>
                                                  HomeScreen()),
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
                              }
                            : null,
                        child: currentlyLoggingIn
                            ? SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                    color: colors(context).tertiary))
                            : const Text('Registrieren'),
                      ),
                    ],
                  )
                ]),
          ),
        ));
  }

  Future<bool> backButtonPressed() {
    Navigator.pop(context);
    return Future.value(false);
  }
}
