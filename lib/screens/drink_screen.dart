import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

class DrinkScreen extends StatefulWidget {
  const DrinkScreen({Key? key}) : super(key: key);

  @override
  State<DrinkScreen> createState() => _DrinkScreenState();
}

class _DrinkScreenState extends State<DrinkScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Getränke"),
      drawer: CustomDrawer(),
      body: FutureBuilder<List<Drink>>(
          future: fetchDrinks(),
          builder: (context, AsyncSnapshot<List<Drink>> snapshot) {
            if (snapshot.hasData) {
              List<Widget> drinkCards = [];
              snapshot.data!.forEach(
                (element) {
                  drinkCards.add(
                    MaterialButton(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(22)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Icons.add),
                          Text(
                            element.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            element.price
                                    .toStringAsFixed(2)
                                    .replaceAll('.', ',') +
                                " €",
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                      onPressed: (() {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return BuyDialog(element);
                            });
                      }),
                      color: kMainColor,
                    ),
                  );
                },
              );
              return GridView.count(
                padding: const EdgeInsets.all(6),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                crossAxisCount: 2,
                children: drinkCards,
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
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
    );
  }

  Future<List<Drink>> fetchDrinks() async {
    //load files
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final drinksFile = File('$path/drinks.txt');

    //try to fetch data from server
    try {
      final response = await GetIt.instance<Backend>().get('/drink');
      if (response != null) {
        await drinksFile.writeAsString(jsonEncode(response));
      }
    } catch (e) {
      developer.log(e.toString());
    }

    //load drinks from local storage
    final drinksString = await drinksFile.readAsString();
    final drinksJson = await jsonDecode(drinksString);

    List<Drink> drinks = [];
    drinksJson.forEach((drinkJson) {
      final drink = Drink.fromJson(drinkJson);
      if (drink.active) drinks.add(drink);
    });
    return drinks;
  }
}

class BuyDialog extends StatelessWidget {
  Drink drink;
  BuyDialog(this.drink, {Key? key}) : super(key: key);
  int amountSelected = 1;
  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    _controller.text = "1";
    return Dialog(
      backgroundColor: kMainColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              drink.name,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                      height: 45,
                      child: IconButton(
                          onPressed: () {
                            if (amountSelected > 0) {
                              _controller.text = (--amountSelected).toString();
                            }
                          },
                          icon: Icon(Icons.remove_circle_outline))),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (amount) {
                        amountSelected = int.parse(amount);
                      },
                      onSubmitted: (String? input) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText: '1', labelText: "Anzahl"),
                    ),
                  ),
                  SizedBox(
                      height: 45,
                      child: IconButton(
                          onPressed: () {
                            _controller.text = (++amountSelected).toString();
                          },
                          icon: Icon(Icons.add_circle_outline))),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Abbrechen"),
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Bestätigen"))
              ],
            )
          ],
        ),
      ),
    );
  }
}
