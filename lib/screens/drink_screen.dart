import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/storage_interface.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class DrinkScreen extends StatefulWidget {
  const DrinkScreen({super.key, required this.userId});
  final String userId;

  @override
  State<DrinkScreen> createState() => _DrinkScreenState();
}

class _DrinkScreenState extends State<DrinkScreen> {
  String? userId;
  @override
  Widget build(BuildContext context) {
    userId ??= widget.userId;
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Getränke"),
      drawer: CustomDrawer(),
      body: FutureBuilder(
        future: Future.wait([
          fetchDrinks(),
          GetIt.I<StorageInterface>().getSettingByKey('shortcutDrink'),
          fetchFriends(),
        ]),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            List<Widget> drinkCards = [];
            snapshot.data![0].forEach((element) {
              if (element.active && !element.deleted) {
                drinkCards.add(
                  MaterialButton(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                    ),
                    onPressed: (() {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return BuyDialog(element, userId!);
                        },
                      );
                    }),
                    onLongPress: () async {
                      await GetIt.I<StorageInterface>().setSettingByKey(
                        'shortcutDrink',
                        element.id.toString(),
                      );
                      setState(() {});
                    },
                    color: Theme.of(context).colorScheme.surface,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Visibility(
                          visible: element.id.toString() == snapshot.data![1],
                          child: const Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 0,
                              ),
                              child: Icon(Icons.star, color: Colors.amber),
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
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              (element.cost / 100)
                                      .toStringAsFixed(2)
                                      .replaceAll('.', ',') +
                                  " €",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            });
            return Column(
              children: [
                if (snapshot.data![2].isNotEmpty)
                  buildFriendCard(
                    userId!,
                    [Friend(GetIt.I<Backend>().loggedInUserId!, 'Dich')] +
                        snapshot.data![2],
                  ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(6),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    crossAxisCount: 2,
                    children: drinkCards,
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      bottomNavigationBar: CustomBottomBar(),
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text("Zurück"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildFriendCard(String uuid, List<Friend> friends) {
    bool bookingForSelf = userId == GetIt.I<Backend>().loggedInUserId;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: (bookingForSelf)
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    color: bookingForSelf
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSecondary,
                    size: 32,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Du buchst für:',
                      style: TextStyle(
                        color: bookingForSelf
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSecondary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    iconEnabledColor: bookingForSelf
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSecondary,
                    style: TextStyle(
                      color: bookingForSelf
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSecondary,
                      fontSize: 18,
                    ),
                    dropdownColor: bookingForSelf
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    items: List.generate(
                      friends.length,
                      (index) => DropdownMenuItem(
                        value: friends[index].uuid,
                        child: Text(friends[index].userName),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        userId = value!;
                      });
                    },
                    value: uuid,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuyDialog extends StatelessWidget {
  Drink drink;
  String userId;
  BuyDialog(this.drink, this.userId, {super.key});
  int amountSelected = 1;
  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    controller.text = "1";
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(drink.name, style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
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
                          controller.text = (--amountSelected).toString();
                        }
                      },
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLength: 2,
                      onChanged: (amount) {
                        int? newValue = int.tryParse(amount);
                        if (newValue != null) {
                          amountSelected = int.parse(amount);
                        } else {
                          if (amount.isNotEmpty) {
                            controller.text = amountSelected.toString();
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          } else {
                            amountSelected = 1;
                          }
                        }
                      },
                      onSubmitted: (String? input) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '1',
                        labelText: "Anzahl",
                        counterText: "",
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 45,
                    child: IconButton(
                      onPressed: () {
                        if (amountSelected < 99) {
                          controller.text = (++amountSelected).toString();
                        }
                      },
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
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
                  onPressed: () async {
                    String? userName;
                    String forId = userId;
                    String bookedUserId = GetIt.I<Backend>().loggedInUserId!;
                    if (bookedUserId != userId) {
                      userName = (await fetchFriends())
                          .where((element) => element.uuid == userId)
                          .first
                          .userName;
                    }
                    purchaseDrink(
                      forId,
                      bookedUserId,
                      drink,
                      amountSelected,
                      userName,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Du hast ${amountSelected}x ${drink.name} ${userName != null ? 'für $userName ' : ''}gebucht.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text("Bestätigen"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> purchaseDrink(
  String userId,
  String userBookedId,
  Drink drink,
  int amount, [
  String? userName,
]) async {
  final body = {
    "uuid": userId,
    'userBookedId': userBookedId,
    "drinkid": drink.id,
    "amount": amount,
    "date": DateTime.now().toString(),
  };
  if (userBookedId != userId) {
    userName ??= (await fetchFriends())
        .where((element) => element.uuid == userId)
        .first
        .userName;
  } else {
    userName = GetIt.I<Backend>().loggedInUser!.name;
  }
  final purchase = Purchase(
    id: 0,
    drinkId: drink.id,
    userId: userId,
    userName: userName,
    userBookedId: userBookedId,
    userBookedName: GetIt.I<Backend>().loggedInUser!.name,
    amount: amount,
    cost: drink.cost,
    date: DateTime.now(),
    deleted: false,
    drinkName: drink.name,
  );

  if (await GetIt.instance<Backend>().checkConnection()) {
    try {
      await GetIt.instance<Backend>().post('/purchase', jsonEncode(body));
      await GetIt.instance<StorageInterface>().setLastPurchase(purchase);
    } catch (error) {
      await GetIt.instance<StorageInterface>().addUnsentPurchase(purchase);
      developer.log(error.toString());
    }
  } else {
    await GetIt.instance<StorageInterface>().addUnsentPurchase(purchase);
    await GetIt.instance<StorageInterface>().setLastPurchase(purchase);
  }
}
