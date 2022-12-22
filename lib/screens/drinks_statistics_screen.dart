import 'dart:convert';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/drink_statistics.dart';
import 'package:dpsg_app/screens/offline-screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../model/drink.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';
import 'inventory_drink_screen.dart';

class DrinkStatisticsScreen extends StatefulWidget {
  const DrinkStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<DrinkStatisticsScreen> createState() => _DrinkStatisticsScreenState();
}

class _DrinkStatisticsScreenState extends State<DrinkStatisticsScreen> {
  final TextEditingController _searchTextController = TextEditingController();

  void performRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Getränkestatistiken"),
      drawer: CustomDrawer(),
      body: OfflineCheck(builder: (context) {
        return FutureBuilder(
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              List<Widget> drinkCards = [];
              snapshot.data!.forEach((element) {
                DrinkStatistics? drinkStatistics;
                drinkStatistics = DrinkStatistics.fromJson(element);

                if (_searchTextController.text.isEmpty ||
                    drinkStatistics.drink.name
                        .toLowerCase()
                        .contains(_searchTextController.text.toLowerCase())) {
                  drinkCards.add(buildDrinkCard(
                      drinkStatistics: drinkStatistics,
                      onTap: () {
                        showCustomModalSheet(drinkStatistics!);
                      }));
                }
              });
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchTextController,
                      decoration: InputDecoration(
                        hintText: 'Suche',
                        suffixIcon: IconButton(
                          icon: Icon(_searchTextController.text.isEmpty
                              ? Icons.person_search
                              : Icons.delete),
                          onPressed: () {
                            setState(() {
                              _searchTextController.clear();
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        ),
                      ),
                      onChanged: (query) {
                        setState(() {});
                      },
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ...drinkCards
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              if (snapshot.hasError) {
                return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                      Icon(Icons.search_off, size: 150),
                      SizedBox(height: 20),
                      SizedBox(
                          width: 250,
                          child: Text('Keine Getränke gefunden...',
                              style: TextStyle(fontSize: 25),
                              textAlign: TextAlign.center))
                    ]));
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            }
          },
          future: GetIt.instance<Backend>().get('/statistics/drink'),
        );
      }),
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: CustomBottomBar(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kSecondaryColor,
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text("Zurück"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      resizeToAvoidBottomInset: false,
    );
  }

  Widget buildDrinkCard(
      {required DrinkStatistics drinkStatistics, required Function onTap}) {
    final child = Row(
      children: [
        Icon(drinkStatistics.drink.active ? Icons.water_drop : Icons.close),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              drinkStatistics.drink.name,
              style: TextStyle(fontSize: 20),
            ),
            Text(
              "Datum: " +
                  (drinkStatistics.date == null ? "-" : DateFormat('dd.MM.yyyy')
                      .format(drinkStatistics.date!.toLocal())),
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "letzte Zählung: " + drinkStatistics.amountActual.toString() + " Fl.",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "seitdem gebucht: " +
                  drinkStatistics.amountPurchased.toString() +
                  " Fl.",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "Bestand erwartet: " +
                  (drinkStatistics.amountActual - drinkStatistics.amountPurchased).toString() +
                  " Fl.",
              style: TextStyle(fontSize: 14),
            )
          ]),
        ),
      ],
    );
    return buildCard(child: child, onTap: onTap);
  }

  Widget buildSettingCard(
      {required IconData icon, required String name, required Function onTap}) {
    final child = Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, size: 40),
        Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(name,
                style: TextStyle(fontSize: 20), textAlign: TextAlign.center))
      ],
    );
    return buildCard(child: child, onTap: onTap);
  }

  Widget buildCard({required child, required Function onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kMainColor,
      child: InkWell(
        onTap: () => onTap(),
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: child,
        ),
      ),
    );
  }

  showCustomModalSheet(DrinkStatistics drinkStatistics) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: kBackgroundColor,
      context: context,
      builder: (context) => Wrap(children: [
        Center(
          child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(drinkStatistics.drink.name,
                  style: TextStyle(fontSize: 30))),
        ),
        const Padding(
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: Divider(thickness: 2)),
        buildSettingCard(
            icon: Icons.shopping_cart,
            name: 'Einkauf hinzufügen',
            onTap: () {
              addNewDrinks(drinkStatistics.drink);
              setState(() {});
            }),
        buildSettingCard(
            icon: Icons.add_to_home_screen_outlined,
            name: 'Bestand eintragen',
            onTap: () {
              addNewStock(drinkStatistics.drink);
              setState(() {});
            }),
        buildSettingCard(
            icon: Icons.history,
            name: 'Bestandsverlauf anzeigen',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          InventoryDrinkScreen(drink: drinkStatistics.drink)));
              setState(() {});
            }),
        SizedBox(height: 15),
      ]),
    );
  }

  Future<void> addNewDrinks(Drink drink) async {
    TextEditingController _TextEditingController = new TextEditingController();
    await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: Text('Einkauf hinzufügen',
                style: TextStyle(fontSize: 25), textAlign: TextAlign.center),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Menge:", style: TextStyle(fontSize: 20)),
                SizedBox(
                    width: 100,
                    child: TextFormField(
                      autofocus: true,
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.right,
                      controller: _TextEditingController,
                      keyboardType: TextInputType.numberWithOptions(
                          signed: false, decimal: false),
                      autovalidateMode: AutovalidateMode.always,
                      decoration: InputDecoration(suffixText: 'Fl.'),
                    ))
              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                child: Text('Abbrechen'),
                onPressed: () {
                  Navigator.pop(context);
                  return;
                },
              ),
              ElevatedButton(
                child: Text('Bestätigen'),
                onPressed: () async {
                  try {
                    if (int.parse(_TextEditingController.text) > 0) {
                      final body = {
                        'drinkId': drink.id,
                        'amount': int.parse(_TextEditingController.text)
                      };
                      await GetIt.I<Backend>()
                          .post('/newDrinks', jsonEncode(body));
                    }
                  } finally {
                    Navigator.pop(context);
                    return;
                  }
                },
              ),
            ],
          );
        });
  }

  Future<void> addNewStock(Drink drink) async {
    TextEditingController _TextEditingController = new TextEditingController();
    await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: Text('Bestand eintragen',
                style: TextStyle(fontSize: 25), textAlign: TextAlign.center),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Menge:", style: TextStyle(fontSize: 20)),
                SizedBox(
                    width: 100,
                    child: TextFormField(
                      autofocus: true,
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.right,
                      controller: _TextEditingController,
                      keyboardType: TextInputType.numberWithOptions(
                          signed: false, decimal: false),
                      autovalidateMode: AutovalidateMode.always,
                      decoration: InputDecoration(suffixText: 'Fl.'),
                    ))
              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                child: Text('Abbrechen'),
                onPressed: () {
                  Navigator.pop(context);
                  return;
                },
              ),
              ElevatedButton(
                child: Text('Bestätigen'),
                onPressed: () async {
                  try {
                    if (int.parse(_TextEditingController.text) > 0) {
                      final body = {
                        'amount': int.parse(_TextEditingController.text)
                      };
                      await GetIt.I<Backend>().post(
                          '/inventory/' + drink.id.toString(),
                          jsonEncode(body));
                    }
                  } finally {
                    Navigator.pop(context);
                    return;
                  }
                },
              ),
            ],
          );
        });
  }
}
