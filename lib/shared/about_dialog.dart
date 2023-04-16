import 'package:dpsg_app/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

displayAboutDialog(context) {
  showAboutDialog(
      context: context,
      applicationIcon: Image.asset(
        'assets/icon_500px.png',
        width: 40,
      ),
      applicationName: 'DPSG Gladbach',
      applicationVersion: appVersion,
      children: [
        TextButton(
          child: const Text('Internetseite'),
          onPressed: () => launchUrl(Uri.parse('https://www.dpsg-gladbach.de'),
              mode: LaunchMode.externalApplication),
        ),
        TextButton(
          child: const Text('Datenschutzerklärung'),
          onPressed: () => launchUrl(
              Uri.parse('https://www.dpsg-gladbach.de/app-datenschutz'),
              mode: LaunchMode.externalApplication),
        ),
      ]);
}
