import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 5,
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: ((context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              )),
            ),
            if (kIsWeb)
              Badge(
                smallSize: 15,
                largeSize: 15,
                child: IconButton(
                  icon: const Icon(Icons.system_security_update),
                  onPressed: () {
                    showDownloadDialog(context);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: const Text('App herunterladen')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Einige Funktionen, wie Offline-Buchungen, sind nur in der App verfügbar. Tippe hier um die App auf deinem Smartphone zu installieren:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
              icon: const Icon(Icons.download, size: 18),
              label: const Text(
                'App herunterladen',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () async {
                Navigator.pop(context);
                const url = 'https://app.dpsg-gladbach.de/download/';
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 10),
            const Text(
              '(Verfügbar für Android und iOS)',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nicht jetzt'),
          ),
        ],
      ),
    );
  }
}
