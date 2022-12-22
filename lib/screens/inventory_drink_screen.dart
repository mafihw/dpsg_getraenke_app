import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/inventory.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../model/drink.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

class InventoryDrinkScreen extends StatefulWidget {
  InventoryDrinkScreen({Key? key, required this.drink}) : super(key: key);
  Drink drink;

  @override
  State<InventoryDrinkScreen> createState() => _InventoryDrinkScreenState();
}

class _InventoryDrinkScreenState extends State<InventoryDrinkScreen> {
  final TextEditingController _searchTextController = TextEditingController();

  void performRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Bestand " + widget.drink.name),
      drawer: CustomDrawer(),
      body: FutureBuilder(
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            List<Widget> inventoryCards = [];
            snapshot.data!.forEach((element) {
              Inventory? inventory;
              inventory = Inventory.fromJson(element);

              inventoryCards.add(buildInventoryCard(
                  child: Row(
                children: [
                  Icon(Icons.date_range),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd.MM.yyyy, kk:mm')
                            .format(inventory.date.toLocal()),
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        "Soll-Bestand: " +
                            inventory.amountCalculated.toString() +
                            ' Fl.',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        "Ist-Bestand: " +
                            inventory.amountActual.toString() +
                            ' Fl.',
                        style: TextStyle(fontSize: 14),
                      ),
                      Row(children: [
                        Text(
                          "Differenz: ",
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                            (inventory.amountActual -
                                        inventory.amountCalculated)
                                    .toString() +
                                ' Fl.',
                            style: TextStyle(
                              fontSize: 14,
                              color: (inventory.amountActual -
                                          inventory.amountCalculated) < 0
                                  ? Colors.red
                                  : Colors.green,
                            ))
                      ])
                    ],
                  )
                ],
              )));
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
                        ...inventoryCards,
                        SizedBox(
                          height: 20,
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
                      children: [
                    Icon(Icons.search_off, size: 150),
                    SizedBox(height: 20),
                    SizedBox(
                        width: 250,
                        child: Text('Keine Bestände gefunden...',
                            style: TextStyle(fontSize: 25),
                            textAlign: TextAlign.center))
                  ]));
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }
        },
        future: GetIt.instance<Backend>()
            .get('/inventory?drinkId=' + widget.drink.id.toString()),
      ),
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

  Widget buildInventoryCard({required Row child}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kMainColor,
        child: InkWell(
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
