import 'dart:async';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/offline-screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../model/purchase.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({Key? key, this.user}) : super(key: key);
  final User? user;
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final Widget _noPurchasesScreen = Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
        Icon(Icons.person_search, size: 150),
        SizedBox(height: 20),
        SizedBox(
            width: 250,
            child: Text('Du hast bisher noch nichts gekauft ...',
                style: TextStyle(fontSize: 25), textAlign: TextAlign.center))
      ]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Buchungen"),
      drawer: const CustomDrawer(),
      body: FutureBuilder<bool>(
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!) {
              return FutureBuilder<dynamic>(
                  future: getPurchases(widget.user),
                  builder: (context, snapshot2) {
                    if (snapshot2.hasData) {
                      return _buildOnlinePurchases(snapshot2.data!);
                    } else if (snapshot2.hasError) {
                      return _noPurchasesScreen;
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  });
            } else {
              return FutureBuilder<List<Purchase>>(
                  future: GetIt.I<LocalDB>().getUnsentPurchases(),
                  builder: (context, snapshot2) {
                    if (snapshot2.hasData && snapshot2.data!.isNotEmpty) {
                      return _buildOfflinePurchases(snapshot2.data!);
                    } else {
                      return OfflineWarning(refresh: () {
                        setState(() {});
                      });
                    }
                  });
            }
          } else {
            if (snapshot.hasError) {
              return _noPurchasesScreen;
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }
        },
        future: GetIt.I<Backend>().checkConnection(),
      ),
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: const CustomBottomBar(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kSecondaryColor,
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text("Zurück"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      resizeToAvoidBottomInset: false,
    );
  }

  Future<dynamic> getPurchases([User? user]) async {
    final String userId =
        user != null ? user.id : GetIt.instance<Backend>().loggedInUser!.id;
    await GetIt.instance<Backend>().sendLocalPurchasesToServer();
    return GetIt.instance<Backend>().get('/purchase?userId=${userId}');
  }

  Widget buildCard({required Row child, required Function onTap}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kMainColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: child,
        ),
      ),
    );
  }

  List<Widget> _buildPurchasesCards(List<Purchase> purchases) {
    List<Widget> purchasesCards = [];
    purchases.sort((a, b) => b.date.compareTo(a.date));
    purchases.forEach((purchase) {
      purchasesCards.add(buildCard(
          child: Row(
            children: [
              const Padding(
                  padding: EdgeInsets.only(left: 5, right: 10),
                  child: Icon(Icons.local_drink)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${purchase.amount} x ${purchase.drinkName}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy, kk:mm')
                        .format(purchase.date.toLocal()),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${((purchase.cost / 100) * purchase.amount).toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: const TextStyle(fontSize: 14),
                  )
                ],
              )
            ],
          ),
          onTap: () {}));
    });
    return purchasesCards;
  }

  Widget _buildOnlinePurchases(dynamic input) {
    List<Purchase> purchases = [];
    input.forEach((element) {
      Purchase? purchase;
      purchase = Purchase.fromJson(element);
      purchases.add(purchase);
    });
    List<Widget> purchasesCards = _buildPurchasesCards(purchases);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: purchasesCards,
      ),
    );
  }

  _buildOfflinePurchases(List<Purchase> purchases) {
    List<Widget> purchasesCards = [];
    purchasesCards.add(_buildNotSyncedInfo());
    purchasesCards.addAll(_buildPurchasesCards(purchases));
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: purchasesCards,
      ),
    );
  }

  Widget _buildNotSyncedInfo() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: kPrimaryColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Hero(
                    tag: 'syncWarning',
                    child: Icon(
                      Icons.sync_problem_rounded,
                      color: kWarningColor,
                      size: 32,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Offline-Käufe',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  )
                ],
              ),
              const Text(
                'Die hier aufgelisteten Käufe sind vorgemerkt und werden erst übernommen, wenn du die App mit einer aktiven Internetverbindung öffnest.',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
