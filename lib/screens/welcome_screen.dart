import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/purchases_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  User? currentUser;
  final Purchase? lastPurchase = null;

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

  Widget buildCard({required Column child, required Function onTap}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kMainColor,
        child: InkWell(
          onTap: () => onTap(),
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
        unsentPurchasesCost: await calculateUnsentPurchasesCost());
  }

  Container processSnapshotData(snapshot) {
    final user = snapshot.data!.user;
    final lastPurchase = snapshot.data!.lastPurchase;
    final unsentPurchasesCost = snapshot.data!.unsentPurchasesCost;
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
                print("Bezahlen");
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
                        : '${lastPurchase.amount}x ${lastPurchase.drinkName} für ${(lastPurchase.cost / 100).toStringAsFixed(2).replaceAll('.', ',')}€',
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
                          children: const [
                            Text('Schnellwahltaste',
                                style: TextStyle(fontSize: 16)),
                            Icon(
                              Icons.add,
                              size: 48,
                            ),
                            Text('1x Bier buchen'),
                          ],
                        ),
                        onTap: () {
                          print("BIERBUCHEN");
                        }),
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
      cost += unsentPurchase.cost;
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
}

class WelcomeScreenData {
  User user;
  Purchase? lastPurchase;
  int unsentPurchasesCost;
  WelcomeScreenData(
      {required this.user, this.lastPurchase, this.unsentPurchasesCost = 0});
}
