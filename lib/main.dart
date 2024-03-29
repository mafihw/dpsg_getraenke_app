import 'dart:io';
import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/permissions.dart';
import 'package:dpsg_app/screens/home_screen.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:dpsg_app/screens/not_verified_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'connection/notification_service.dart';

const String appVersion = '1.3.0';
final navigatorKey = GlobalKey<NavigatorState>();

Future<dynamic> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload) async {}
void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  GetIt.instance.registerSingleton<LocalDB>(LocalDB());
  GetIt.instance.registerSingleton<Backend>(Backend());
  GetIt.instance.registerSingleton<PermissionSystem>(PermissionSystem());
  GetIt.instance.registerSingleton<NotificationService>(NotificationService());
  await GetIt.instance<NotificationService>().init(_onDidReceiveLocalNotification);
  await GetIt.I<LocalDB>().init();
  await GetIt.I<Backend>().init();
  await GetIt.I<PermissionSystem>().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    Widget screen;
    var backend = GetIt.instance<Backend>();
    if (backend.isLoggedIn && backend.loggedInUser != null) {
      screen = FutureBuilder<bool>(
        future: GetIt.I<Backend>().refreshData(),
        builder: ((context, snapshot) {
          if (GetIt.I<Backend>().loggedInUser!.role != 'none') {
            return HomeScreen();
          } else {
            return NotVerifiedScreen();
          }
        }),
      );
    } else {
      GetIt.I<Backend>().logout();
      screen = LoginScreen();
    }
    return MaterialApp(
        home: screen,
        navigatorKey: navigatorKey, // Setting a global key for navigator
        theme: ThemeData(
            colorScheme: kColorScheme,
            snackBarTheme: snackBarTheme,
            dialogTheme: const DialogTheme(backgroundColor: kBackgroundColor),
            checkboxTheme: CheckboxThemeData(
                fillColor: MaterialStateProperty.all(kPrimaryColor)),
        ),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [
            Locale('de'),
          ],
    );
  }
}
