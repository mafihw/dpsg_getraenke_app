import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/login_screen.dart';
import 'package:dpsg_app/screens/profile_screen.dart';
import 'package:dpsg_app/screens/purchases_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';

import '../screens/users_screen.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      backgroundColor: kBackgroundColor,
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: kMainColor,
            ),
            child: Image(
              image: AssetImage('assets/icon_2500px.png'),
            ),
          ),
          ...addListTilesToDrawer()
        ],
      ),
    );
  }

  List<Widget> addListTilesToDrawer() {
    final listTiles = <Widget>[
      ListTile(
        leading: Icon(Icons.history),
        title: const Text('Kürzliche Buchungen'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PurchasesScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: Icon(Icons.fingerprint),
        title: const Text('Profil'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyProfileScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: Icon(FontAwesomeIcons.syringe),
        title: const Text('Promillerechner'),
        onTap: () {},
      ),
      ListTile(
        leading: Icon(Icons.settings),
        title: const Text('Einstellungen'),
        onTap: () {},
      ),
      ExpansionTile(
        title: Text("Verwaltung"),
        leading: Icon(FontAwesomeIcons.lockOpen),
        children: [
          ListTile(
            leading: Icon(Icons.manage_accounts),
            title: const Text('Nutzer'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserAdministrationScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.wineBottle),
            title: const Text('Getränke'),
            onTap: () {},
          ),
        ],
      ),
      ListTile(
        leading: Icon(Icons.logout),
        title: const Text('Abmelden'),
        onTap: () {
          GetIt.instance<Backend>().logout();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false);
        },
      ),
    ];
    return listTiles;
  }
}
