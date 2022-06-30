import 'package:dpsg_app/screens/drink_screen.dart';
import 'package:dpsg_app/screens/welcome_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
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
      appBar: CustomAppBar(appBarTitle: 'DPSG Gladbach Getränke'),
      drawer: CustomDrawer(),
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
}
