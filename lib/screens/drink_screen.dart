import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
      body: FutureBuilder(
          future: Future.wait([
            fetchDrinks(),
            GetIt.I<LocalDB>().getSettingByKey('shortcutDrink')
          ]),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              List<Widget> drinkCards = [];
              snapshot.data![0].forEach(
                (element) {
                  if (element.active && !element.deleted) {
                    drinkCards.add(
                      MaterialButton(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Visibility(
                              visible:
                                  element.id.toString() == snapshot.data![1],
                              child: const Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 0),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ),
                            Column(
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
                                  (element.cost / 100)
                                          .toStringAsFixed(2)
                                          .replaceAll('.', ',') +
                                      " €",
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ],
                        ),
                        onPressed: (() {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return BuyDialog(element);
                              });
                        }),
                        onLongPress: () async {
                          await GetIt.I<LocalDB>().setSettingByKey(
                              'shortcutDrink', element.id.toString());
                          setState(() {});
                        },
                        color: kMainColor,
                      ),
                    );
                  }
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
                            if (amountSelected > 1) {
                              _controller.text = (--amountSelected).toString();
                            }
                          },
                          icon: Icon(Icons.remove_circle_outline))),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 2,
                      onChanged: (amount) {
                        int? newValue = int.tryParse(amount);
                        if (newValue != null) {
                          amountSelected = int.parse(amount);
                        } else {
                          if (amount.isNotEmpty) {
                            _controller.text = amountSelected.toString();
                            _controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: _controller.text.length));
                          } else {
                            amountSelected = 1;
                          }
                        }
                      },
                      onSubmitted: (String? input) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText: '1', labelText: "Anzahl", counterText: ""),
                    ),
                  ),
                  SizedBox(
                      height: 45,
                      child: IconButton(
                          onPressed: () {
                            if (amountSelected < 99) {
                              _controller.text = (++amountSelected).toString();
                            }
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
                      purchaseDrink(GetIt.instance<Backend>().loggedInUser!.id,
                          drink, amountSelected);
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

Future<void> purchaseDrink(String userId, Drink drink, int amount) async {
  final body = {
    "uuid": userId,
    "drinkid": drink.id,
    "amount": amount,
    "date": DateTime.now().toString()
  };
  final purchase = Purchase(
      id: 0,
      drinkId: drink.id,
      userId: userId,
      amount: amount,
      cost: amount * drink.cost,
      date: DateTime.now(),
      drinkName: drink.name);

  if (await GetIt.instance<Backend>().checkConnection()) {
    try {
      await GetIt.instance<Backend>().post('/purchase', jsonEncode(body));
      await GetIt.instance<LocalDB>().setLastPurchase(purchase);
    } catch (error) {
      await GetIt.instance<LocalDB>().insertUnsentPurchase(purchase);
      developer.log(error.toString());
    }
  } else {
    await GetIt.instance<LocalDB>().insertUnsentPurchase(purchase);
    await GetIt.instance<LocalDB>().setLastPurchase(purchase);
  }
}
