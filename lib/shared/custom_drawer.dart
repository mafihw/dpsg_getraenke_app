import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

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
    final listTiles = <Widget>[];

    listTiles.add(ListTile(
      title: const Text('Item 1'),
      onTap: () {
        // Update the state of the app.
        // ...
      },
    ));

    listTiles.add(ListTile(
      title: const Text('Item 3'),
      onTap: () {
        // Update the state of the app.
        // ...
      },
    ));
    return listTiles;
  }
}
