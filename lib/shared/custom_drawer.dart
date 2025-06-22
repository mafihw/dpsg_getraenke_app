import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/permissions.dart';
import 'package:dpsg_app/screens/drinks_administration_screen.dart';
import 'package:dpsg_app/screens/drinks_statistics_screen.dart';
import 'package:dpsg_app/screens/friends_screen.dart';
import 'package:dpsg_app/screens/general_statistics_screen.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:dpsg_app/screens/new_drinks_screen.dart';
import 'package:dpsg_app/screens/payments_screen.dart';
import 'package:dpsg_app/screens/profile_screen.dart';
import 'package:dpsg_app/screens/purchases_screen.dart';
import 'package:dpsg_app/shared/about_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';

import '../connection/database.dart';
import '../screens/users_screen.dart';

class CustomDrawer extends StatefulWidget {
  final Function()? updateHomeScreen;

  const CustomDrawer({super.key, this.updateHomeScreen});

  @override
  State<CustomDrawer> createState() =>
      _CustomDrawerState(updateHomeScreen: updateHomeScreen);
}

class _CustomDrawerState extends State<CustomDrawer> {
  final Function()? updateHomeScreen;

  _CustomDrawerState({this.updateHomeScreen});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Image(image: AssetImage('assets/icon_500px.png')),
          ),
          NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: Expanded(
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                addRepaintBoundaries: false,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [...addListTilesToDrawer()],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> addListTilesToDrawer() {
    final listTiles = <Widget>[
      ListTile(
        leading: Icon(Icons.home),
        title: const Text('Übersicht'),
        onTap: () {
          Navigator.pop(context);
          Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
          if (updateHomeScreen != null) updateHomeScreen!();
        },
      ),
      ListTile(
        leading: Icon(Icons.history),
        title: const Text('Kürzliche Buchungen'),
        onTap: () async {
          Navigator.pop(context);
          Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
          final userId = await GetIt.I<LocalDB>().getLoggedInUserId();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PurchasesScreen(userId: userId),
            ),
          );
          if (updateHomeScreen != null) updateHomeScreen!();
        },
      ),
      ListTile(
        leading: Icon(Icons.payments),
        title: const Text('Zahlungen'),
        onTap: () async {
          Navigator.pop(context);
          Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
          final userId = await GetIt.I<LocalDB>().getLoggedInUserId();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentsScreen(userId: userId),
            ),
          );
          if (updateHomeScreen != null) updateHomeScreen!();
        },
      ),
      ListTile(
        leading: Icon(Icons.fingerprint),
        title: const Text('Profil'),
        onTap: () async {
          Navigator.pop(context);
          Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyProfileScreen()),
          );
          if (updateHomeScreen != null) updateHomeScreen!();
        },
      ),
      ListTile(
        leading: const Icon(Icons.people),
        title: const Text('Freundschaften'),
        onTap: () async {
          Navigator.pop(context);
          Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FriendsScreen()),
          );
          if (updateHomeScreen != null) updateHomeScreen!();
        },
      ),
      /*ListTile(
        leading: Icon(FontAwesomeIcons.syringe),
        title: const Text('Promillerechner'),
        onTap: () {},
      ),
      ListTile(
        leading: Icon(Icons.settings),
        title: const Text('Einstellungen'),
        onTap: () {},
      ),*/
      ...getAdminListTiles(),
      ListTile(
        leading: const Icon(Icons.info_outline_rounded),
        title: const Text('Rechtliches'),
        onTap: () => displayAboutDialog(context),
      ),
      ListTile(
        leading: Icon(Icons.logout),
        title: const Text('Abmelden'),
        onTap: () {
          GetIt.instance<Backend>().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        },
      ),
    ];
    return listTiles;
  }

  List<Widget> getAdminListTiles() {
    final adminListTiles = <Widget>[];
    if (GetIt.I<PermissionSystem>().userHasPermission(
          Permission.canGetAllUsers,
        ) ||
        GetIt.I<PermissionSystem>().userHasPermission(
          Permission.canEditDrinks,
        )) {
      adminListTiles.add(
        ExpansionTile(
          title: Text("Verwaltung"),
          leading: Icon(FontAwesomeIcons.lockOpen),
          children: [
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canGetAllUsers,
            ))
              ListTile(
                leading: Icon(Icons.manage_accounts),
                title: const Text('Nutzer'),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) => route.isFirst,
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserAdministrationScreen(),
                    ),
                  );
                  if (updateHomeScreen != null) updateHomeScreen!();
                },
              ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canEditDrinks,
            ))
              ListTile(
                leading: Icon(FontAwesomeIcons.wineBottle),
                title: const Text('Getränke'),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) => route.isFirst,
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DrinkAdministrationScreen(),
                    ),
                  );
                  if (updateHomeScreen != null) updateHomeScreen!();
                },
              ),
          ],
        ),
      );
      adminListTiles.add(
        ExpansionTile(
          title: Text("Statistiken"),
          leading: Icon(FontAwesomeIcons.chartLine),
          children: [
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canSeeAllPurchases,
            ))
              ListTile(
                leading: Icon(Icons.bar_chart),
                title: const Text('Allgemein'),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) => route.isFirst,
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GeneralStatisticsScreen(),
                    ),
                  );
                  if (updateHomeScreen != null) updateHomeScreen!();
                },
              ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canEditDrinks,
            ))
              ListTile(
                leading: Icon(Icons.view_in_ar),
                title: const Text('Bestand'),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) => route.isFirst,
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DrinkStatisticsScreen(),
                    ),
                  );
                  if (updateHomeScreen != null) updateHomeScreen!();
                },
              ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canSeeAllPurchases,
            ))
              ListTile(
                leading: Icon(Icons.history),
                title: const Text('Buchungen'),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) => route.isFirst,
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PurchasesScreen()),
                  );
                  if (updateHomeScreen != null) updateHomeScreen!();
                },
              ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canSeeAllPurchases,
            ))
              ListTile(
                leading: Icon(Icons.add_home_outlined),
                title: const Text('Einkäufe'),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) => route.isFirst,
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewDrinksScreen()),
                  );
                  if (updateHomeScreen != null) updateHomeScreen!();
                },
              ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canSeeAllPurchases,
            ))
              ListTile(
                leading: Icon(Icons.payments),
                title: const Text('Zahlungen'),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) => route.isFirst,
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentsScreen()),
                  );
                  if (updateHomeScreen != null) updateHomeScreen!();
                },
              ),
          ],
        ),
      );
    }
    return adminListTiles;
  }
}
