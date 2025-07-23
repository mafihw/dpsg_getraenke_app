import 'dart:async';
import 'dart:io';
import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/permissions.dart';
import 'package:dpsg_app/screens/home_screen.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:dpsg_app/screens/not_verified_screen.dart';
import 'package:dpsg_app/screens/outdated_version_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const String appVersion = '1.4.1';
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  GetIt.instance.registerSingleton<LocalDB>(LocalDB());
  GetIt.instance.registerSingleton<Backend>(Backend());
  GetIt.instance.registerSingleton<PermissionSystem>(PermissionSystem());
  await GetIt.I<LocalDB>().init();
  await GetIt.I<Backend>().init();
  await GetIt.I<PermissionSystem>().init();
  ColorScheme colorScheme = await GetIt.I<LocalDB>().getColorScheme();
  runApp(MyApp(colorScheme: colorScheme));
}

class MyApp extends StatefulWidget {
  final ColorScheme colorScheme;
  const MyApp({super.key, required this.colorScheme});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _settingsSubsciption;
  ColorScheme? colorScheme;

  @override
  void initState() {
    colorScheme = widget.colorScheme;
    _settingsSubsciption = GetIt.I<LocalDB>().settingsStream.stream.listen((
      event,
    ) {
      if (event.containsKey('colorScheme')) {
        setState(() {
          colorScheme = kColorSchemes
              .firstWhere(
                (item) => item.name == event['colorScheme'],
                orElse: () => kColorSchemes.first,
              )
              .colorScheme;
        });
      }
    });
    if (GetIt.I<Backend>().isLoggedIn &&
        GetIt.I<Backend>().loggedInUser == null) {
      GetIt.I<Backend>().logout();
    }
    super.initState();
  }

  @override
  dispose() {
    _settingsSubsciption?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    var backend = GetIt.instance<Backend>();
    if (backend.isLoggedIn &&
        backend.loggedInUser != null &&
        !backend.versionIncompatible) {
      if (GetIt.I<Backend>().loggedInUser!.role != 'none') {
        screen = const HomeScreen();
      } else {
        screen = NotVerifiedScreen();
      }
    } else if (!backend.versionIncompatible) {
      screen = LoginScreen();
    } else {
      screen = OutdatedVersionScreen();
    }
    return MaterialApp(
      home: screen,
      navigatorKey: navigatorKey, // Setting a global key for navigator
      theme: ThemeData(
        colorScheme: colorScheme!,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: colorScheme!.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme!.primaryContainer,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(colorScheme!.primary),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            elevation: 2,
            side: BorderSide(style: BorderStyle.none),
            foregroundColor: colorScheme!.onPrimary,
            backgroundColor: colorScheme!.primary,
            disabledBackgroundColor: colorScheme!.primary.withValues(
              alpha: 0.22,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: colorScheme!.primaryContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme!.onSurface.withAlpha(80),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme!.onSurface, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme!.onSurface.withAlpha(80),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme!.onSurface.withAlpha(80),
              width: 1,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: colorScheme!.onSecondary,
            backgroundColor: colorScheme!.secondary,
            disabledBackgroundColor: colorScheme!.primary.withValues(
              alpha: 0.22,
            ),
          ),
        ),
      ),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('de')],
    );
  }
}
