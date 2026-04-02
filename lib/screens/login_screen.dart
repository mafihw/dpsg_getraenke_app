import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/not_verified_screen.dart';
import 'package:dpsg_app/screens/registration_screen.dart';
import 'package:dpsg_app/shared/about_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
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
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('DPSG Gladbach Getränke'),
        actions: [
          IconButton(
            onPressed: () => displayAboutDialog(context),
            icon: const Icon(Icons.info),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Container()),
              const Hero(
                tag: 'icon_hero',
                child: Image(
                  image: AssetImage('assets/icon_500px.png'),
                  height: 150.0,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailTextController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordTextController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Passwort'),
                onSubmitted: (c) => login(),
              ),
              const SizedBox(height: 20),
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
                    child: Text('Registrieren'),
                  ),
                  OutlinedButton.icon(
                    icon: currentlyLoggingIn ? null : Icon(Icons.login),
                    onPressed: login,
                    label: currentlyLoggingIn
                        ? SizedBox(
                            height: 25,
                            width: 82,
                            child: Center(
                              child: SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          )
                        : const Text('Anmelden'),
                  ),
                ],
              ),
              Expanded(flex: 2, child: Container()),
              if (kIsWeb)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Jetzt die App herunterladen!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Offline Getränke buchen, Freunde hinzufügen und mehr.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            const url =
                                'https://app.dpsg-gladbach.de/download/';
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text(
                            'App herunterladen',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Verfügbar für iOS und Android.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void login() async {
    if (!currentlyLoggingIn) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        currentlyLoggingIn = true;
      });
      if (await GetIt.instance<Backend>().login(
        emailTextController.text,
        passwordTextController.text,
      )) {
        await GetIt.instance<Backend>().refreshData();
        if (GetIt.instance<Backend>().loggedInUser!.role != 'none') {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: ((context) => NotVerifiedScreen())),
            );
          }
        }
        setState(() {
          currentlyLoggingIn = false;
        });
      } else {
        if (!mounted) return;
        SnackBar snackBar = SnackBar(
          content: Text(
            'Login fehlgeschlagen!',
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
}
