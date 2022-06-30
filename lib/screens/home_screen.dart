import 'package:dpsg_app/screens/drink_screen.dart';
import 'package:dpsg_app/screens/welcome_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('DPSG Gladbach Getränke'),
        leading: Hero(
          tag: 'icon_hero',
          child: TextButton(
            onPressed: () {},
            child: Image(
              image: AssetImage('assets/icon_2500px.png'),
            ),
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.logout)),
        ],
      ),
      drawer: Drawer(
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
      ),
      body: WelcomeScreen(),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: ((context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    )),
              ),
              IconButton(
                icon: const Icon(
                  Icons.person,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
        elevation: 5,
        color: kMainColor,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kSecondaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DrinkScreen(),
            ),
          );
        },
        icon: const Icon(FontAwesomeIcons.wineBottle),
        label: const Text("Getränk buchen"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  List<Widget> addListTilesToDrawer(){
    final listTiles = <Widget>[];

    listTiles.add(
        ListTile(
          title: const Text('Item 1'),
          onTap: () {
            // Update the state of the app.
            // ...
          },
        )
    );

    listTiles.add(
        ListTile(
          title: const Text('Item 3'),
          onTap: () {
            // Update the state of the app.
            // ...
          },
        )
    );
    return listTiles;
  }
}
