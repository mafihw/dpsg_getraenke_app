import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/drink_screen.dart';
import 'package:dpsg_app/screens/payments_screen.dart';
import 'package:dpsg_app/screens/purchases_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

import '../shared/custom_alert_dialog.dart';
import '../shared/custom_snack_bar.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  User? currentUser;
  final Purchase? lastPurchase = null;

  //The ValueNotifier triggers a rebuild of a snackBar
  final ValueNotifier<String> snackMsg = ValueNotifier('');
  int drinksPending = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      if (!GetIt.instance<Backend>().checkTokenValidity() &&
          await GetIt.instance<Backend>().checkConnection()) {
        await GetIt.instance<Backend>().refreshToken(context);
      }
      await fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (context, AsyncSnapshot<WelcomeScreenData> snapshot) {
        if (snapshot.hasData) {
          return processSnapshotData(snapshot);
        } else {
          if (snapshot.hasError) {
            return processSnapshotError(snapshot);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }
      },
      future: fetchWelcomeScreenData(context),
    );
  }

  Widget buildCard(
      {required Widget child,
      required Function onTap,
      Function()? onLongPress}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kMainColor,
        child: InkWell(
          onTap: () => onTap(),
          onLongPress: onLongPress,
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );
  }

  Future<WelcomeScreenData> fetchWelcomeScreenData(context) async {
    return WelcomeScreenData(
      lastPurchase: await fetchLastPurchase(),
      user: await fetchUser(),
      unsentPurchasesCost: await calculateUnsentPurchasesCost(),
      shortcutDrink: await _getCurrentlySelectedShortcutDrink(),
    );
  }

  Container processSnapshotData(snapshot) {
    final user = snapshot.data!.user;
    final lastPurchase = snapshot.data!.lastPurchase;
    final unsentPurchasesCost = snapshot.data!.unsentPurchasesCost;
    final Drink? shortcutDrink = snapshot.data!.shortcutDrink;
    int daysUntilLastBooking = lastPurchase == null
        ? 0
        : DateTime.now().difference(lastPurchase.date).inDays;
    return Container(
      color: kBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildCard(
                child: Column(
                  children: [
                    Text(
                      'Hallo ${user.name}',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Text(
                      'Willkommen zurück!',
                      style: TextStyle(fontSize: 18),
                    )
                  ],
                ),
                onTap: () {
                  print("Profil");
                }),
            buildCard(
              child: Column(
                children: [
                  const Text(
                    'Dein Kontostand:',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    '${((user.balance - unsentPurchasesCost) / 100).toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: const TextStyle(fontSize: 48),
                  )
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentsScreen(),
                  ),
                );
              },
            ),
            buildCard(
              child: Column(
                children: [
                  const Text(
                    'Letzte Buchung:',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    daysUntilLastBooking == 0
                        ? 'Heute'
                        : daysUntilLastBooking == 1
                            ? 'Gestern'
                            : ' Vor $daysUntilLastBooking Tagen',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    lastPurchase == null
                        ? '-'
                        : '${lastPurchase.amount}x ${lastPurchase.drinkName} für ${(lastPurchase.cost / 100 * lastPurchase.amount).toStringAsFixed(2).replaceAll('.', ',')}€',
                    style: const TextStyle(fontSize: 18),
                  )
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PurchasesScreen(),
                  ),
                );
              },
            ),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Schnellwahltaste',
                                style: TextStyle(fontSize: 16)),
                            Icon(
                              Icons.add,
                              size: 48,
                            ),
                            shortcutDrink != null
                                ? Text(
                                    '1x ${shortcutDrink.name} buchen',
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    'Lange gedrückt halten zum Auswählen',
                                    textAlign: TextAlign.center,
                                  ),
                          ],
                        ),
                        onTap: () async {
                          if (shortcutDrink != null) {
                            shortDrinkPurchase(user, shortcutDrink);
                          }
                        },
                        onLongPress: openShortcutSelector),
                  ),
                  Expanded(
                    child: buildCard(
                      child: Column(
                        children: const [
                          Text(
                            'Bezahlen',
                            style: TextStyle(fontSize: 24),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Icon(
                            FontAwesomeIcons.paypal,
                            size: 48,
                          ),
                        ],
                      ),
                      onTap: () async {
                        await _openPaypal(-user.balance / 100);
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  openShortcutSelector() async {
    List<Drink> drinks = (await fetchDrinks())
        .where((element) => element.active && !element.deleted)
        .toList();
    String? selected =
        await GetIt.I<LocalDB>().getSettingByKey('shortcutDrink');
    await showDialog(
        context: context,
        builder: (context) =>
            ShortcutSelector(available: drinks, currentlySelectedId: selected));
    setState(() {});
  }

  Future<Drink?> _getCurrentlySelectedShortcutDrink() async {
    String? id = await GetIt.I<LocalDB>().getSettingByKey('shortcutDrink');
    if (id != null) {
      var drinks = await fetchDrinks();
      for (Drink drink in drinks) {
        if (drink.id.toString() == id) {
          return drink;
        }
      }
    }
    return null;
  }

  Center processSnapshotError(snapshot) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          const Icon(Icons.error, size: 150),
          const SizedBox(height: 20),
          SizedBox(
              width: 250,
              child: Text(
                  'Userdaten konnten nicht geladen werden: ${snapshot.error}',
                  style: const TextStyle(fontSize: 25),
                  textAlign: TextAlign.center))
        ]));
  }

  Future<Purchase?> fetchLastPurchase() async {
    var backend = GetIt.I<Backend>();
    var localStorage = GetIt.I<LocalDB>();
    String userId = backend.loggedInUserId!;
    Purchase? purchase;
    await backend.sendLocalPurchasesToServer();
    //try to fetch data from server
    try {
      final response = await backend.get('/purchase?userId=$userId');
      if (response != null) {
        purchase = Purchase.fromJson(response.last);
        localStorage.setLastPurchase(purchase);
      }
    } catch (e) {
      developer.log(e.toString());
    }

    //load last purchase from local storage
    purchase ??= await localStorage.getLastPurchase();

    return purchase;
  }

  Future<int> calculateUnsentPurchasesCost() async {
    int cost = 0;
    List<Purchase> unsentPurchases =
        await GetIt.I<LocalDB>().getUnsentPurchases();
    for (Purchase unsentPurchase in unsentPurchases) {
      cost += unsentPurchase.cost * unsentPurchase.amount;
    }
    return cost;
  }

  Future<void> _openPaypal(double amount) async {
    Uri url = Uri.parse(
        'https://paypal.me/Bierkasse1947/${amount.toString().replaceAll('.', ',')}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      developer.log("url $url cant be launched");
    }
  }

  Future<void> shortDrinkPurchase(User user, Drink shortcutDrink) async {
    snackMsg.value = (++drinksPending).toString() + ' ' + shortcutDrink.name + ' gebucht';
    if(drinksPending == 1){
      final snackBar = CustomSnackBar(
          content: SnackContent(snackMsg),
          action: SnackBarAction(label: 'Rückgängig machen', textColor: kColorScheme.onPrimary, onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          })
      );
      await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((value) async
        {
          if (value == SnackBarClosedReason.action){
            drinksPending = 0;
          } else {
            int drinks = drinksPending;
            drinksPending = 0;
            await purchaseDrink(user.id, shortcutDrink, drinks);
            setState(() {});
          }
        });
    }
  }
}

class ShortcutSelector extends StatefulWidget {
  ShortcutSelector(
      {Key? key, required this.available, this.currentlySelectedId})
      : super(key: key);
  List<Drink> available;
  String? currentlySelectedId;
  @override
  State<ShortcutSelector> createState() => _ShortcutSelectorState();
}

class _ShortcutSelectorState extends State<ShortcutSelector> {
  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(
      title: Text('Schnellwahltaste'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: widget.available.length,
          itemBuilder: ((context, index) {
            return CheckboxListTile(
                title: Text(widget.available[index].name),
                value: widget.available[index].id.toString() ==
                    widget.currentlySelectedId,
                onChanged: (_) {
                  setState(() {
                    if (widget.available[index].id.toString() ==
                        widget.currentlySelectedId) {
                      widget.currentlySelectedId = null;
                    } else {
                      widget.currentlySelectedId =
                          widget.available[index].id.toString();
                    }
                  });
                });
          }),
        ),
      ),
      actions: [
        OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.cancel),
            label: Text('Abbrechen')),
        ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (widget.currentlySelectedId != null) {
                GetIt.I<LocalDB>().setSettingByKey(
                    'shortcutDrink', widget.currentlySelectedId.toString());
              } else {
                GetIt.I<LocalDB>().removeSettingByKey('shortcutDrink');
              }
            },
            icon: Icon(Icons.save),
            label: Text('Speichern')),
      ],
    );
  }
}

class WelcomeScreenData {
  User user;
  Purchase? lastPurchase;
  int unsentPurchasesCost;
  Drink? shortcutDrink;
  WelcomeScreenData(
      {required this.user,
      this.lastPurchase,
      this.unsentPurchasesCost = 0,
      this.shortcutDrink});
}

class SnackContent extends StatelessWidget {
  final ValueNotifier<String> snackMsg;

  SnackContent(this.snackMsg);

  @override
  Widget build(BuildContext context) {
    /// ValueListenableBuilder rebuilds whenever snackMsg value changes.
    /// i.e. this "listens" to changes of ValueNotifier "snackMsg".
    /// "msg" in builder below is the value of "snackMsg" ValueNotifier.
    /// We don't use the other builder args for this example so they are
    /// set to _ & __ just for readability.
    return ValueListenableBuilder<String>(
        valueListenable: snackMsg,
        builder: (_, msg, __) => Text(msg, style: TextStyle(color: kColorScheme.onPrimary),));
  }
}
