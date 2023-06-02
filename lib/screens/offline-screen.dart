import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class OfflineCheck extends StatefulWidget {
  const OfflineCheck({Key? key, required this.builder}) : super(key: key);
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
      CircularProgressIndicator()
    ],
  ));
  @override
  Widget build(BuildContext context) {
    final offlineWidget = OfflineWarning(
      refresh: () {
        setState(() {});
      },
    );
    return GetIt.I<Backend>().isOnline
        ? widget.builder.call(context)
        : offlineWidget;
  }
}

class OfflineWarning extends StatefulWidget {
  const OfflineWarning({Key? key, required this.refresh}) : super(key: key);
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
          const Icon(
            Icons.cloud_off,
            color: kPrimaryColor,
            size: 72,
          ),
          const Center(
            child: Text(
              'Offline-Modus',
              textScaleFactor: 1.5,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          OutlinedButton.icon(
            label: const Text('Erneut verbinden'),
            onPressed: () async {
              setState(() {
                refreshCounter++;
              });
              if (!connecting) {
                connecting = true;
                await GetIt.I<Backend>()
                    .checkConnection()
                    .then((value) => {setState(() => connecting = false)});
                widget.refresh.call();
              }
            },
            icon: AnimatedRotation(
              child: const Icon(Icons.refresh),
              turns: refreshCounter / 1,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          AnimatedOpacity(
            opacity: refreshCounter > 5 ? 1 : 0,
            duration: const Duration(seconds: 2),
            child: const Text(
              'Wenn du eine Verbindung hast, aber die App trotzdem nicht funktioniert, melde dich bitte bei den Verantwortlichen!',
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
