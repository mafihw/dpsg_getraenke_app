import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/drink_screen.dart';
import 'package:dpsg_app/screens/welcome_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _update() {
    GetIt.I<Backend>().checkConnection();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: CustomAppBar(
        appBarTitle: 'DPSG Gladbach Getränke',
        onIconPress: _update,
      ),
      drawer: CustomDrawer(updateHomeScreen: _update),
      body: WelcomeScreen(),
      bottomNavigationBar: CustomBottomBar(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kSecondaryColor,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DrinkScreen(userId: GetIt.I<Backend>().loggedInUserId!),
            ),
          );
          setState(() {});
        },
        icon: const Icon(FontAwesomeIcons.wineBottle),
        label: const Text("Getränk buchen"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
