import 'package:dpsg_app/screens/home_screen.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';

import '../connection/backend.dart';

class NotVerifiedScreen extends StatefulWidget {
  final bool? fromRegistration;
  const NotVerifiedScreen({super.key, this.fromRegistration});

  @override
  State<NotVerifiedScreen> createState() => _NotVerifiedScreenState();
}

class _NotVerifiedScreenState extends State<NotVerifiedScreen> {
  bool currentlyRefreshing = false;
  @override
  Widget build(BuildContext context) {
    final bool fromRegistration = widget.fromRegistration ?? false;
    if (currentlyRefreshing) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      );
    } else {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        body: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.userLock,
                        color: Theme.of(context).colorScheme.primary,
                        size: 96,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Konto nicht bestätigt',
                        style: TextStyle(
                          fontSize: 36,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (fromRegistration)
                        Text(
                          'Deine Registrierung war erfolgreich.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      Text(
                        'Bitte warte bis dein Konto von einem Administrator bestätigt wurde',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      GetIt.instance<Backend>().logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                  ),
                  IconButton(
                    onPressed: () async {
                      setState(() {
                        currentlyRefreshing = true;
                      });
                      await GetIt.instance<Backend>().refreshData();

                      if (GetIt.instance<Backend>().loggedInUser!.role !=
                          'none') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      } else {
                        Future.delayed(const Duration(seconds: 8), () {
                          setState(() {
                            currentlyRefreshing = false;
                          });
                        });
                      }
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}
