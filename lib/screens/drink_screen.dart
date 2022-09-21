import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';

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
                      purchaseDrink(GetIt.instance<Backend>().loggedInUser!.id, drink, amountSelected);
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

  void purchaseDrink(String userId, Drink drink, int amount) async {
    final body = {
    "uuid": userId,
    "drinkid": drink.id,
    "amount": amount,
    "date": DateTime.now().toString()
    };
    final purchase = Purchase(id: 0, drinkId: drink.id, userId: userId, amount: amount, cost: amount * drink.price, date: DateTime.now(), drinkName: drink.name);

    if(await GetIt.instance<Backend>().checkConnection()) {
      try {
        await GetIt.instance<Backend>().post(
            '/purchase',
            jsonEncode(body)
        );
      } catch(error) {
        developer.log(error.toString());
      }
    } else {
      List<Purchase> notSubmittedPurchases = [];
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final drinksFile = File('$path/unDonePurchases.txt');
      if (await drinksFile.exists()) {
        List.from(jsonDecode(await drinksFile.readAsString())).
        forEach((element) {
          notSubmittedPurchases.add(Purchase.fromJson(element));
        });
      };
      notSubmittedPurchases.add(purchase);
      drinksFile.writeAsString(jsonEncode(notSubmittedPurchases).toString());
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final drinksFile = File('$path/lastPurchase.txt');
    drinksFile.writeAsString(jsonEncode(purchase.toJson()));

  }
}
