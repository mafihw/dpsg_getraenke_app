import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/home_screen.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:dpsg_app/screens/not_verified_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

void main() async {
  GetIt.instance.registerSingleton<Backend>(Backend());
  await GetIt.instance<Backend>().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
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
    if (GetIt.instance<Backend>().isLoggedIn) {
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
      screen = LoginScreen();
    }
    return MaterialApp(
      home: screen,
      theme: ThemeData(colorScheme: kColorScheme),
    );
  }
}
