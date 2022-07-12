import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

import '../model/purchase.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesScreen> createState() =>
      _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  Widget build(BuildContext context) {
    final String userId = GetIt.instance<Backend>().loggedInUser!.id;
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Buchungen"),
      drawer: CustomDrawer(),
      body: FutureBuilder(
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            List<Widget> purchasesCards = [];
            snapshot.data!.forEach((element) {
              Purchase? purchase;
              purchase = Purchase.fromJson(element);
              developer.log(element.toString());

              purchasesCards.add(
                buildCard(
                  child: Row(
                    children: [
                      Padding(
                          padding: EdgeInsets.only(left: 5, right: 10),
                          child: Icon(Icons.local_drink)
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${purchase.amount} * ${purchase.drinkId}',
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            '${DateFormat('dd.MM.yyyy, kk:mm').format(purchase.date.toLocal())}',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${purchase.cost.toStringAsFixed(2).replaceAll('.', ',')} €',
                            style: TextStyle(fontSize: 14),
                          )
                        ],
                      )
                    ],
                  ),
                  onTap: () {}
                )
              );
            });
            return
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [...purchasesCards],
                  ),
                );
          } else {
            if (snapshot.hasError) {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    Icon(Icons.person_search, size: 150),
                    SizedBox(height: 20),
                    SizedBox(
                        width: 250,
                        child: Text('Anscheinend ist gerade niemand da...',
                            style: TextStyle(fontSize: 25),
                            textAlign: TextAlign.center))
                  ]));
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }
        },
        future: GetIt.instance<Backend>().get('/purchase?userId=${userId}'),
      ),
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
      resizeToAvoidBottomInset: false,
    );
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
}