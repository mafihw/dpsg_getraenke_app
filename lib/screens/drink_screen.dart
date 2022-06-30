import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:flutter/material.dart';

class DrinkScreen extends StatefulWidget {
  const DrinkScreen({Key? key}) : super(key: key);

  @override
  State<DrinkScreen> createState() => _DrinkScreenState();
}

class _DrinkScreenState extends State<DrinkScreen> {
  @override
  Widget build(BuildContext context) {
    List<Widget> drinkCards = [];
    drinks.forEach(
      (element) {
        drinkCards.add(Padding(
          padding: const EdgeInsets.all(10),
          child: MaterialButton(
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
                  element.price.toString() + "€",
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
        ));
      },
    );
    return Scaffold(
      appBar: CustomAppBar(),
      body: GridView.count(
        crossAxisCount: 2,
        children: drinkCards,
      ),
      backgroundColor: kBackgroundColor,
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
    _controller.text="1";
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
              child:
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 45,
                    child:
                      IconButton(
                        onPressed: (){
                          if (amountSelected > 0) {
                            _controller.text = (--amountSelected).toString();
                          }
                        },
                        icon: Icon(
                            Icons.remove_circle_outline
                        )
                      )
                  ),
                  Expanded(
                    child:
                      TextField(
                        controller: _controller,
                        onChanged: (amount) {
                          amountSelected = int.parse(amount);
                        },
                        onSubmitted: (String? input) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        keyboardType: TextInputType.number,
                        decoration:
                        const InputDecoration(hintText: '1', labelText: "Anzahl"),
                      ),
                  ),
                  SizedBox(
                      height: 45,
                      child:
                      IconButton(
                          onPressed: (){
                              _controller.text = (++amountSelected).toString();
                          },
                          icon: Icon(
                              Icons.add_circle_outline
                          )
                      )
                  ),
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

List<Drink> drinks = [
  Drink(
    id: 1,
    name: "Hachenburger Hell",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Hachenburger Hell",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Hachenburger Hell",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Hachenburger Hell",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Hachenburger Hell",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
  Drink(
    id: 1,
    name: "Hachenburger Hell",
    icon: const Icon(Icons.local_drink),
    price: 0.70,
  ),
];
