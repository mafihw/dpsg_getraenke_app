import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_app_bar.dart';
import 'package:dpsg_app/shared/custom_bottom_bar.dart';
import 'package:dpsg_app/shared/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../connection/notification_service.dart';

NotificationService _notificationService = GetIt.instance<NotificationService>();

class DrinkScreen extends StatefulWidget {
  DrinkScreen({Key? key, required this.userId}) : super(key: key);
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
            GetIt.I<LocalDB>().getSettingByKey('shortcutDrink'),
            fetchFriends()
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
                                return BuyDialog(element, userId!);
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
              return Column(
                children: [
                  if (snapshot.data![2].isNotEmpty)
                    buildFriendCard(
                        userId!,
                        [Friend(GetIt.I<Backend>().loggedInUserId!, 'Dich')] +
                            snapshot.data![2]),
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

  Widget buildFriendCard(String uuid, List<Friend> friends) {
    friends;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: (userId == GetIt.I<Backend>().loggedInUserId)
            ? kPrimaryColor
            : kSecondaryColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people,
                    color: Colors.black,
                    size: 32,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Du buchst für:',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  DropdownButton<String>(
                    iconEnabledColor: Colors.black,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    dropdownColor: kPrimaryColor,
                    items: List.generate(
                        friends.length,
                        (index) => DropdownMenuItem(
                              child: Text(friends[index].userName),
                              value: friends[index].uuid,
                            )),
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
  BuyDialog(this.drink, this.userId, {Key? key}) : super(key: key);
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
                          forId, bookedUserId, drink, amountSelected, userName);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Du hast ${amountSelected}x ${drink.name} ${userName != null ? 'für $userName ' : ''}gebucht.')));
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

Future<void> purchaseDrink(
    String userId, String userBookedId, Drink drink, int amount,
    [String? userName]) async {
  final body = {
    "uuid": userId,
    'userBookedId': userBookedId,
    "drinkid": drink.id,
    "amount": amount,
    "date": DateTime.now().toString()
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
      drinkName: drink.name);

  if (await GetIt.instance<Backend>().checkConnection()) {
    try {
      await GetIt.instance<Backend>().post('/purchase', jsonEncode(body));
      await GetIt.instance<LocalDB>().setLastPurchase(purchase);
    } catch (error) {
      await GetIt.instance<LocalDB>().insertUnsentPurchase(purchase);
      _notificationService.showOfflinePurchasesNotification();
      developer.log(error.toString());
    }
  } else {
    await GetIt.instance<LocalDB>().insertUnsentPurchase(purchase);
    _notificationService.showOfflinePurchasesNotification();
    await GetIt.instance<LocalDB>().setLastPurchase(purchase);
  }
}
