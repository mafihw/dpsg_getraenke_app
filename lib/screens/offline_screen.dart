import 'package:dpsg_app/connection/backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';

class OfflineCheck extends StatefulWidget {
  const OfflineCheck({super.key, required this.builder});
  final Widget Function(BuildContext context) builder;
  @override
  State<OfflineCheck> createState() => _OfflineCheckState();
}

class _OfflineCheckState extends State<OfflineCheck> {
  final waitingWidget = Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Wir stellen eine Verbindung her ... '),
        ),
        CircularProgressIndicator(),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    // On web, bypass offline checking and always show the builder
    if (kIsWeb) {
      return widget.builder.call(context);
    }

    final offlineWidget = OfflineWarning(
      refresh: () {
        setState(() {});
      },
    );
    return GetIt.I<Backend>().isOnlineMode
        ? widget.builder.call(context)
        : offlineWidget;
  }
}

class OfflineWarning extends StatefulWidget {
  const OfflineWarning({super.key, required this.refresh});
  final Function refresh;

  @override
  State<OfflineWarning> createState() => _OfflineWarningState();
}

class _OfflineWarningState extends State<OfflineWarning>
    with TickerProviderStateMixin {
  int refreshCounter = 0;
  bool connecting = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 72,
          ),
          Center(
            child: Text(
              'Offline-Modus',
              textScaler: TextScaler.linear(1.5),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            label: const Text('Erneut verbinden'),
            onPressed: () async {
              setState(() {
                refreshCounter++;
              });
              if (!connecting) {
                connecting = true;
                await GetIt.I<Backend>().checkConnection();
                if (!GetIt.I<Backend>().isTokenValid) {
                  await GetIt.I<Backend>().refreshToken();
                }
                setState(() => connecting = false);
                widget.refresh.call();
              }
            },
            icon: AnimatedRotation(
              turns: refreshCounter / 1,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              child: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: refreshCounter > 3 ? 1 : 0,
            duration: const Duration(seconds: 2),
            child: Text(
              'Wenn du eine Verbindung hast, aber die App trotzdem nicht funktioniert, melde dich bitte bei den Verantwortlichen!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
