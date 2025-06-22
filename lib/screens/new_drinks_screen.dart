import 'dart:async';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/offline_screen.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../model/new_drink.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_card.dart';
import '../shared/custom_drawer.dart';

class NewDrinksScreen extends StatefulWidget {
  const NewDrinksScreen({super.key, this.userId});
  final String? userId;
  @override
  State<NewDrinksScreen> createState() => _NewDrinksScreenState();
}

class _NewDrinksScreenState extends State<NewDrinksScreen> {
  var startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).subtract(const Duration(days: 90));
  var endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Einkäufe"),
      drawer: CustomDrawer(),
      body: OfflineCheck(
        builder: (context) => FutureBuilder(
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            return Column(
              children: [
                getFilters(),
                Expanded(child: getBody(snapshot)),
              ],
            );
          },
          future: getNewDrinks(),
        ),
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
      resizeToAvoidBottomInset: false,
    );
  }

  Widget getBody(AsyncSnapshot snapshot) {
    if (snapshot.hasData) {
      List<Widget> newDrinksCards = [];
      List<NewDrink> newDrinks = [];
      snapshot.data!.forEach((element) {
        NewDrink? newDrink;
        newDrink = NewDrink.fromJson(element);
        newDrinks.add(newDrink);
      });
      newDrinks.sort((a, b) => b.date.compareTo(a.date));
      for (var newDrink in newDrinks) {
        newDrinksCards.add(
          buildCard(
            context: context,
            child: Row(
              children: [
                Icon(Icons.euro),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(newDrink.drinkName, style: TextStyle(fontSize: 20)),
                      Text(
                        'Datum: ${DateFormat('dd.MM.yyyy, HH:mm').format(newDrink.date.toLocal())}',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Anzahl: ${newDrink.amount}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [...newDrinksCards],
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
                child: Text(
                  'Keine Einkäufe gefunden ...',
                  style: TextStyle(fontSize: 25),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      } else {
        return Center(child: CircularProgressIndicator());
      }
    }
  }

  Widget getFilters() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton(
            onPressed: () async {
              final selectedDate = await selectDate(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2021, 12, 01),
                lastDate: endDate,
              );
              if (selectedDate != null) {
                setState(() {
                  startDate = selectedDate;
                });
              }
            },
            style: ButtonStyle(
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
              ),
            ),
            child: IntrinsicWidth(
              child: Text(
                'von: ${DateFormat('dd.MM.yyyy').format(startDate.toLocal())}',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton(
            onPressed: () async {
              final selectedDate = await selectDate(
                context: context,
                initialDate: endDate,
                firstDate: startDate,
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                setState(() {
                  endDate = selectedDate;
                });
              }
            },
            style: ButtonStyle(
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
              ),
            ),
            child: IntrinsicWidth(
              child: Text(
                'bis: ${DateFormat('dd.MM.yyyy').format(endDate.toLocal())}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<dynamic> getNewDrinks() async {
    final String dateStartSearchString =
        '?from=${(startDate.millisecondsSinceEpoch / 1000).toStringAsFixed(0)}';
    final String dateEndSearchString =
        '&to=${(endDate.add(Duration(days: 1)).millisecondsSinceEpoch / 1000).toStringAsFixed(0)}';
    return GetIt.instance<Backend>().get(
      '/newDrinks$dateStartSearchString$dateEndSearchString',
    );
  }
}
