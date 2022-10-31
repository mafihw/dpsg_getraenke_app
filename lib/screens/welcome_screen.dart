import 'dart:convert';
import 'dart:io';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/purchases_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>  {

  User? currentUser = null;
  final Purchase? lastPurchase = null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!GetIt.instance<Backend>().checkTokenValidity() &&
          await GetIt.instance<Backend>().checkConnection()) {
        await GetIt.instance<Backend>().refreshToken(context);
      }
      await updateUserFromServer();
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
            return Center(
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
        user: await fetchUser(), lastPurchase: await fetchLastPurchase());
  }

  Container processSnapshotData(snapshot) {
    final user = snapshot.data!.user;
    final lastPurchase = snapshot.data!.lastPurchase;
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
                      style: TextStyle(fontSize: 24),
                    ),
                    Text(
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
                  Text(
                    'Dein Kontostand:',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    '${(user.balance / 100).toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: TextStyle(fontSize: 48),
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
                  Text(
                    'Letzte Buchung:',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    daysUntilLastBooking == 0
                        ? 'Heute'
                        : daysUntilLastBooking == 1
                        ? 'Gestern'
                        : ' Vor ${daysUntilLastBooking} Tagen',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    lastPurchase == null
                        ? '-'
                        : '${lastPurchase.amount}x ${lastPurchase.drinkName} für ${(lastPurchase.cost / 100).toStringAsFixed(2).replaceAll('.', ',')}€',
                    style: TextStyle(fontSize: 18),
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
                          children: [
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
                        children: [
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
              Icon(Icons.error, size: 150),
              SizedBox(height: 20),
              SizedBox(
                  width: 250,
                  child: Text(
                      'Userdaten konnten nicht geladen werden: ${snapshot.error}',
                      style: TextStyle(fontSize: 25),
                      textAlign: TextAlign.center))
            ]
        )
    );
  }

  Future<Purchase?> fetchLastPurchase() async {
    //TODO fetch from db if no last purchase was found locally
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final drinksFile = File('$path/lastPurchase.txt');
      final lastPurchaseString = await drinksFile.readAsString();
      final lastPurchaseData = jsonDecode(lastPurchaseString.toString());
      return Purchase.fromJson(lastPurchaseData);
    } catch (error) {
      developer.log(error.toString());
      return null;
    }
  }

  Future<User> getUser() async {
    if (currentUser == null){
      //load files
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final userFile = File('$path/user.txt');

      //load user from local storage
      if (await userFile.exists()) {
        final userString = await userFile.readAsString();
        final userJson = await jsonDecode(userString);
        currentUser = User.fromJson(userJson);
      } else  {
        //load user from server
        await updateUserFromServer();
      }

      if (currentUser == null) {
        throw new Exception("Kein User gefunden");
      }
    }

    return currentUser!;
  }

  Future<void> updateUserFromServer() async {

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final userFile = File('$path/user.txt');
    //try to fetch data from server
    try {
      String? loggedInUserId = GetIt.instance<Backend>().loggedInUser?.id;
      if (loggedInUserId == null) throw Error();
      final response =
      await GetIt.instance<Backend>().get('/user/$loggedInUserId');
      if (response != null) {
        await userFile.writeAsString(jsonEncode(response));
        currentUser = User.fromJson(response);
      }
    } catch (e) {
      developer.log(e.toString());
    }
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

  WelcomeScreenData({required this.user, this.lastPurchase});
}
