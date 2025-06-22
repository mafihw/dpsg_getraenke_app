import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/not_verified_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'home_screen.dart';

final emailValidationPattern = RegExp(
  r'''(?:[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])''',
);

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

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

  InputBorder? getInvalidBorder(BuildContext context) =>
      Theme.of(context).inputDecorationTheme.focusedBorder?.copyWith(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.0,
        ),
      );

  bool currentlyLoggingIn = false;

  bool validation() {
    return nameTextController.text.isNotEmpty &&
        RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
        ).hasMatch(emailTextController.text) &&
        passwordTextController.text.length >= 8 &&
        confirmPasswordTextController.text == passwordTextController.text;
  }

  bool validateName() {
    _nameValid = nameTextController.text.isNotEmpty;
    return _nameValid;
  }

  bool validateMail() {
    _mailValid = emailValidationPattern.hasMatch(emailTextController.text);
    return _mailValid;
  }

  bool validatePassword() {
    _passwordValid =
        passwordTextController.text.length >= 8 ||
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Registrierung')),
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
                  focusedBorder: _nameValid ? null : getInvalidBorder(context),
                  enabledBorder: _nameValid ? null : getInvalidBorder(context),
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
                  focusedBorder: _mailValid ? null : getInvalidBorder(context),
                  enabledBorder: _mailValid ? null : getInvalidBorder(context),
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
                  focusedBorder: _passwordValid
                      ? null
                      : getInvalidBorder(context),
                  enabledBorder: _passwordValid
                      ? null
                      : getInvalidBorder(context),
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
                  focusedBorder: _passwordCheckValid
                      ? null
                      : getInvalidBorder(context),
                  enabledBorder: _passwordCheckValid
                      ? null
                      : getInvalidBorder(context),
                ),
                onChanged: (value) {
                  setState(() {
                    validatePasswordConfirm();
                  });
                },
                onSubmitted: (value) {
                  if (validation()) {
                    registration();
                  }
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
                    child: const Text('Zurück'),
                  ),
                  OutlinedButton(
                    onPressed: validation() ? registration : null,
                    child: currentlyLoggingIn
                        ? SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                              color: Colors.blue.shade800,
                            ),
                          )
                        : const Text('Registrieren'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void registration() async {
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
        if (GetIt.instance<Backend>().loggedInUser!.role != 'none') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => NotVerifiedScreen(fromRegistration: true),
            ),
            (route) => false,
          );
        }
        setState(() {
          currentlyLoggingIn = false;
        });
      } else {
        SnackBar snackBar = SnackBar(
          content: Text(
            'Registrierung fehlgeschlagen!',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          currentlyLoggingIn = false;
        });
      }
    }
  }

  Future<bool> backButtonPressed() {
    Navigator.pop(context);
    return Future.value(false);
  }
}
