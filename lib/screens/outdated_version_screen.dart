import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OutdatedVersionScreen extends StatefulWidget {
  const OutdatedVersionScreen({super.key});

  @override
  State<OutdatedVersionScreen> createState() => _OutdatedVersionScreenState();
}

class _OutdatedVersionScreenState extends State<OutdatedVersionScreen> {
  @override
  Widget build(BuildContext context) {
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
                      FontAwesomeIcons.triangleExclamation,
                      color: Theme.of(context).colorScheme.primary,
                      size: 96,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Veraltete App-Version',
                      style: TextStyle(
                        fontSize: 36,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),

                    Text(
                      'Deine Version der App ist leider veraltet. Bitte aktualisiere die App, um fortzufahren.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async => await launchUrlString(
                        'https://app.dpsg-gladbach.de',
                        mode: LaunchMode.externalApplication,
                      ),
                      label: Text('Update jetzt herunterladen'),
                      icon: Icon(Icons.download_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
