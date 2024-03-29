import 'dart:async';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/drink_screen.dart';
import 'package:dpsg_app/screens/payments_screen.dart';
import 'package:dpsg_app/screens/profile_screen.dart';
import 'package:dpsg_app/screens/purchases_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

import '../shared/custom_dialogs.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with WidgetsBindingObserver {
  User? currentUser;
  final Purchase? lastPurchase = null;
  Timer timer = Timer(const Duration(seconds: 5), () {});
  bool connecting = false;
  int reconnectCounter = 0;

  //The ValueNotifier triggers a rebuild of a snackBar
  final ValueNotifier<String> snackMsg = ValueNotifier('');
  int drinksPending = 0;
  Drink? shortcutDrink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (GetIt.instance<Backend>().isOnline &&
          !(await GetIt.instance<Backend>().checkTokenValidity())) {
        await GetIt.instance<Backend>().refreshToken();
      }
      await fetchUser();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive && timer.isActive) {
      timer.cancel();
      int drinks = drinksPending;
      drinksPending = 0;
      await purchaseDrink(
          currentUser!.id, currentUser!.id, shortcutDrink!, drinks);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      await GetIt.I<Backend>().checkConnection();
      setState(() {});
    }
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
      Function()? onLongPress,
      Widget? infoIcon}) {
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: infoIcon ?? Container(),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget offlineInfo() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kPrimaryColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Offline-Modus',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    Text(
                      'Du bist nicht verbunden',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    reconnectCounter++;
                  });
                  if (!connecting) {
                    connecting = true;
                    await GetIt.I<Backend>().checkConnection().then((value) => {
                          Future.delayed(const Duration(seconds: 1))
                              .then((_) => setState(() => connecting = false))
                        });
                  } else {
                    setState(() {});
                  }
                },
                icon: AnimatedRotation(
                    duration: const Duration(seconds: 1),
                    turns: reconnectCounter / 1,
                    child: const Icon(Icons.refresh)),
                label: const Text('Verbinden'),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(kMainColor),
                    foregroundColor: MaterialStateProperty.all(Colors.white)),
              ),
            ],
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
    currentUser = snapshot.data!.user;
    final Purchase? lastPurchase = snapshot.data!.lastPurchase;
    final int unsentPurchasesCost = snapshot.data!.unsentPurchasesCost;
    shortcutDrink = snapshot.data!.shortcutDrink;
    final now = DateTime.now();
    int daysUntilLastBooking = lastPurchase == null
        ? 0
        : DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastPurchase.date.year,
                lastPurchase.date.month, lastPurchase.date.day))
            .inDays;
    return Container(
      color: kBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (!GetIt.I<Backend>().isOnline) offlineInfo(),
            buildCard(
                child: Column(
                  children: [
                    Text(
                      'Hallo ${currentUser!.name}',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Text(
                      'Willkommen zurück!',
                      style: TextStyle(fontSize: 18),
                    )
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyProfileScreen(),
                    ),
                  );
                  setState(() {});
                }),
            buildCard(
              child: Column(
                children: [
                  const Text(
                    'Dein Kontostand:',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    '${((currentUser!.balance - unsentPurchasesCost) / 100).toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: const TextStyle(fontSize: 48),
                  )
                ],
              ),
              onTap: () async {
                final userId = await GetIt.I<LocalDB>().getLoggedInUserId();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentsScreen(userId: userId),
                  ),
                );
                setState(() {});
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
                    ),
                    if (lastPurchase != null &&
                        lastPurchase.userId !=
                            GetIt.I<Backend>().loggedInUserId)
                      Text('für ${lastPurchase.userName}',
                          style: const TextStyle(fontSize: 18)),
                    if (lastPurchase != null &&
                        lastPurchase.userBookedId !=
                            GetIt.I<Backend>().loggedInUserId)
                      Text('von ${lastPurchase.userBookedName}',
                          style: const TextStyle(fontSize: 18))
                  ],
                ),
                onTap: () async {
                  final userId = await GetIt.I<LocalDB>().getLoggedInUserId();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PurchasesScreen(userId: userId),
                    ),
                  );
                  setState(() {});
                },
                infoIcon: FutureBuilder<List>(
                    future: GetIt.I<LocalDB>().getUnsentPurchases(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return Hero(
                            tag: 'syncWarning',
                            child: IconButton(
                              icon: Icon(
                                Icons.sync_problem_rounded,
                                color: kWarningColor
                              ),
                              onPressed: () {
                                setState((){
                                  GetIt.instance<Backend>().sendLocalPurchasesToServer();
                                });
                              },
                            )
                        );
                      } else {
                        return Container();
                      }
                    })),
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
                                    '1x ${shortcutDrink!.name} buchen',
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
                            shortDrinkPurchase(currentUser!, shortcutDrink!);
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
                        await _openPaypal(-currentUser!.balance / 100);
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
    if (backend.isOnline) {
      await backend.sendLocalPurchasesToServer();
      //try to fetch data from server
      try {
        final response = await backend.get('/purchase?userId=$userId');
        if (response != null && response.isNotEmpty) {
          purchase = Purchase.fromJson(response.last);
          localStorage.setLastPurchase(purchase);
        }
      } catch (e) {
        developer.log(e.toString());
      }
    }

    //load last purchase from local storage
    purchase ??= await localStorage.getLastPurchase();

    return purchase;
  }

  Future<int> calculateUnsentPurchasesCost() async {
    int cost = 0;
    List<Purchase> unsentPurchases =
        await GetIt.I<LocalDB>().getUnsentPurchases();
    for (Purchase unsentPurchase in unsentPurchases.where(
        (element) => element.userId == GetIt.I<Backend>().loggedInUserId)) {
      cost += unsentPurchase.cost * unsentPurchase.amount;
    }
    return cost;
  }

  Future<void> _openPaypal(double amount) async {
    Uri url = Uri.parse(
        'https://paypal.me/Bierkasse1947/${amount.toString().replaceAll('.', ',')}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      developer.log("url $url cant be launched: $e");
    }
  }

  FutureOr<dynamic> shortDrinkPurchase(User user, Drink drink) async {
    snackMsg.value =
        (++drinksPending).toString() + ' ' + drink.name + ' gebucht';
    restartTimer();
    if (drinksPending == 1) {
      final snackBar = SnackBar(
          content: SnackContent(snackMsg),
          duration: Duration(minutes: 5),
          action: SnackBarAction(
              label: 'Rückgängig machen',
              textColor: kColorScheme.onPrimary,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }));
      await ScaffoldMessenger.of(context)
          .showSnackBar(snackBar)
          .closed
          .then((value) async {
        if (value == SnackBarClosedReason.action) {
          drinksPending = 0;
          timer.cancel();
        } else if (value == SnackBarClosedReason.timeout) {
          int drinks = drinksPending;
          drinksPending = 0;
          await purchaseDrink(user.id, user.id, drink, drinks);
          setState(() {});
        }
      });
    }
  }

  void restartTimer() {
    if (timer.isActive) {
      timer.cancel();
    }
    timer = Timer(
        const Duration(seconds: 5),
        () => {
              ScaffoldMessenger.of(context)
                  .hideCurrentSnackBar(reason: SnackBarClosedReason.timeout)
            });
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
        builder: (_, msg, __) => Text(
              msg,
              style: TextStyle(color: kColorScheme.onPrimary),
            ));
  }
}
