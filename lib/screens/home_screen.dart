import 'package:dpsg_app/screens/drink_screen.dart';
import 'package:dpsg_app/screens/welcome_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  void _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: CustomAppBar(appBarTitle: 'DPSG Gladbach Getränke'),
      drawer: CustomDrawer(updateHomeScreen: _update),
      body: WelcomeScreen(),
      bottomNavigationBar: CustomBottomBar(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kSecondaryColor,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DrinkScreen(),
            ),
          );
          setState(() {});
        },
        icon: const Icon(FontAwesomeIcons.wineBottle),
        label: const Text("Getränk buchen"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      //TODO: remove if has no important function
      //onDrawerChanged: (_) => setState(() {}),
    );
  }
}
