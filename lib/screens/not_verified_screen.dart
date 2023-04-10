import 'package:dpsg_app/screens/home_screen.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';

import '../connection/backend.dart';

class NotVerifiedScreen extends StatefulWidget {
  NotVerifiedScreen([this.fromRegistration]);
  bool? fromRegistration = false;

  @override
  State<NotVerifiedScreen> createState() => _NotVerifiedScreenState();
}

class _NotVerifiedScreenState extends State<NotVerifiedScreen> {
  bool currentlyRefreshing = false;
  @override
  Widget build(BuildContext context) {
    widget.fromRegistration ??= false;
    if (currentlyRefreshing) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
        backgroundColor: colors(context).background,
      );
    } else {
      return Scaffold(
        backgroundColor: colors(context).background,
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
                        color: colors(context).primary,
                        size: 96,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Konto nicht bestätigt',
                        style: TextStyle(fontSize: 36),
                      ),
                      if (widget.fromRegistration!)
                        const Text(
                          'Deine Registrierung war erfolgreich.',
                          textAlign: TextAlign.center,
                        ),
                      const Text(
                        'Bitte warte bis dein Konto von einem Administrator bestätigt wurde',
                        textAlign: TextAlign.center,
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
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                            (Route<dynamic> route) => false);
                      },
                      icon: const Icon(Icons.logout)),
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
                                  builder: (context) => const HomeScreen()),
                              (route) => false);
                        } else {
                          Future.delayed(const Duration(seconds: 8), () {
                            setState(() {
                              currentlyRefreshing = false;
                            });
                          });
                        }
                      },
                      icon: const Icon(Icons.refresh)),
                ],
              )
            ],
          ),
        ),
      );
    }
  }
}
