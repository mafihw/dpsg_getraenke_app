import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
                          element.icon,
                          Text(
                            element.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            element.price.toStringAsFixed(2).replaceAll('.', ',') + " €",
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
              return Center(
                child:  CircularProgressIndicator()
              );
            }
          }
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
    );

  }

  Future<List<Drink>> fetchDrinks() async {
    //load files
    final directory = await getApplicationDocumentsDirectory();
    final path = await directory.path;
    final loginFile = await File('$path/loginInformation.txt');
    final drinksFile = await File('$path/drinks.txt');

    //try to fetch data from server
    try {
      final loginInformation = jsonDecode(await loginFile.readAsString());
      final token = loginInformation['token'];
      final response = await http.get(
          Uri.parse('http://api.dpsg-gladbach.de:3000/api/drink'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          }
      );
      developer.log(response.statusCode.toString());
      if(response.statusCode == 200){
        //save new data at local storage if successful
        drinksFile.writeAsString(response.body);
      }
    } catch (e) {
      developer.log(e.toString());
    }

    //load drinks from local storage
    final drinksString = await drinksFile.readAsString();
    final drinksJson = await jsonDecode(drinksString);

    List<Drink> drinks = [];
    drinksJson.forEach((drink) =>
        drinks.add(
        new Drink(
            id: drink['id'].toInt(),
            name: drink['name'].toString(),
            icon: Icon(Icons.local_drink),
            price: drink['cost'].toDouble()
        ))

    );

    return Future<List<Drink>>.value(drinks);
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

class Drink {
  int id;
  String name;
  Icon icon;
  double price;
  Drink(
      {required this.id,
      required this.name,
      required this.icon,
      required this.price});
}

List<Drink> drinksExample = [
  Drink(
    id: 1,
    name: "Vulkan Pils",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Vulkan Radler",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Vulkan Helles",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Freibier",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Paulaner Spezi",
    icon: const Icon(Icons.local_drink),
    price: 1.0,
  ),
  Drink(
    id: 1,
    name: "24er Kiste Bier",
    icon: const Icon(Icons.local_drink),
    price: 20.90,
  ),
];
