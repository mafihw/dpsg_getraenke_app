import 'dart:convert';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/offline-screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:get_it/get_it.dart';

import '../model/drink.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

class DrinkAdministrationScreen extends StatefulWidget {
  const DrinkAdministrationScreen({Key? key}) : super(key: key);

  @override
  State<DrinkAdministrationScreen> createState() =>
      _DrinkAdministrationScreenState();
}

class _DrinkAdministrationScreenState extends State<DrinkAdministrationScreen> {
  final TextEditingController _searchTextController = TextEditingController();

  void performRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Getränkeverwaltung"),
      drawer: CustomDrawer(),
      body: OfflineCheck(builder: (context) {
        return FutureBuilder(
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              List<Widget> drinkCards = [];
              snapshot.data!.forEach((element) {
                Drink? drink;
                drink = Drink.fromJson(element);

                if (_searchTextController.text.isEmpty ||
                    drink.name
                        .toLowerCase()
                        .contains(_searchTextController.text.toLowerCase())) {
                  drinkCards.add(buildDrinkCard(
                      drink: drink,
                      onTap: () {
                        showCustomModalSheet(drink!);
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
                              ? Icons.search
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
                          ...drinkCards,
                          IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline_outlined,
                                  size: 40),
                              onPressed: () {
                                createNewDrink();
                              }),
                          const SizedBox(
                            height: 30,
                          )
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
          future: GetIt.instance<Backend>().get('/drink'),
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

  Widget buildDrinkCard({required drink, required Function onTap}) {
    final child = Row(
      children: [
        Icon(drink.active ? Icons.water_drop : Icons.close),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drink.name,
                style: TextStyle(fontSize: 20),
              ),
              Text(
                "Preis: " +
                    (drink.cost / 100).toStringAsFixed(2).replaceAll('.', ',') +
                    " €",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        )
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

  showCustomModalSheet(Drink drink) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: kBackgroundColor,
      context: context,
      builder: (context) => Wrap(children: [
        Center(
          child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(drink.name, style: TextStyle(fontSize: 30))),
        ),
        const Padding(
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: Divider(thickness: 2)),
        buildSettingCard(
          icon: Icons.euro,
          name: 'Preis ändern',
          onTap: () {
            changePrice(drink);
            setState(() {});
          },
        ),
        buildSettingCard(
          icon: Icons.text_snippet,
          name: 'Name ändern',
          onTap: () {
            changeName(drink);
            setState(() {});
          },
        ),
        buildSettingCard(
          icon: drink.active ? Icons.close : Icons.check,
          name: drink.active ? 'Getränk deaktivieren' : 'Getränk aktivieren',
          onTap: () {
            changeStatus(drink);
            setState(() {});
          },
        ),
        SizedBox(height: 15),
      ]),
    );
  }

  Future<void> changePrice(Drink drink) async {
    MoneyMaskedTextController _MoneyMaskedTextController =
    new MoneyMaskedTextController(
        decimalSeparator: '.', thousandSeparator: ',', rightSymbol: '€');
    await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: Text('Preis ändern',
                style: TextStyle(fontSize: 25), textAlign: TextAlign.center),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Neuer Preis:", style: TextStyle(fontSize: 20)),
                SizedBox(
                    width: 100,
                    child: TextField(
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.right,
                      controller: _MoneyMaskedTextController,
                      keyboardType: TextInputType.numberWithOptions(
                          signed: false, decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9]+[,.]{0,1}[0-9]*')),
                        TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                            text: newValue.text.replaceAll('.', ','),
                          ),
                        ),
                      ],
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
                    if (_MoneyMaskedTextController.numberValue > 0) {
                      final body = {
                        'cost': _MoneyMaskedTextController.numberValue * 100
                      };
                      await GetIt.I<Backend>()
                          .put('/drink/${drink.id}', jsonEncode(body));
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

  Future<void> changeName(Drink drink) async {
    TextEditingController _TextEditingController =
    new TextEditingController();
    await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: Text('Name ändern',
                style: TextStyle(fontSize: 25), textAlign: TextAlign.center),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Neuer Name:", style: TextStyle(fontSize: 20)),
                SizedBox(
                    width: 100,
                    child: TextField(
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.right,
                      controller: _TextEditingController,
                      keyboardType: TextInputType.text,
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
                    if (_TextEditingController.text.length > 2) {
                      final body = {
                        'name': _TextEditingController.text
                      };
                      await GetIt.I<Backend>()
                          .put('/drink/${drink.id}', jsonEncode(body));
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    return;
                  }
                },
              ),
            ],
          );
        });
  }

  Future<void> changeStatus(Drink drink) async {
    try {
      final body = {'active': !drink.active};
      await GetIt.I<Backend>().put('/drink/${drink.id}', jsonEncode(body));
    } finally {
      setState(() {});
      Navigator.pop(context);
    }
  }

  Future<void> createNewDrink() async {
    TextEditingController _TextEditingController = new TextEditingController();
    MoneyMaskedTextController _MoneyMaskedTextController =
        new MoneyMaskedTextController(
            decimalSeparator: '.', thousandSeparator: ',', rightSymbol: '€');

    await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: Text('Getränk hinzufügen',
                style: TextStyle(fontSize: 25), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Name:", style: TextStyle(fontSize: 20)),
                    SizedBox(
                        width: 100,
                        child: TextField(
                          autofocus: true,
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.right,
                          controller: _TextEditingController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                        ))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Preis:", style: TextStyle(fontSize: 20)),
                    SizedBox(
                        width: 100,
                        child: TextField(
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.right,
                          controller: _MoneyMaskedTextController,
                          keyboardType: TextInputType.numberWithOptions(
                              signed: false, decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9]+[,.]{0,1}[0-9]*')),
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.replaceAll('.', ','),
                              ),
                            ),
                          ],
                          textInputAction: TextInputAction.done,
                        ))
                  ],
                )
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
                    if ((_MoneyMaskedTextController.numberValue > 0) &&
                        (_TextEditingController.text.isNotEmpty)) {
                      final body = {
                        'name': _TextEditingController.text,
                        'cost': _MoneyMaskedTextController.numberValue * 100
                      };
                      await GetIt.I<Backend>().post('/drink', jsonEncode(body));
                      setState(() {});
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    setState(() {});
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
