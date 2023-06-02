import 'dart:async';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/offline-screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_card.dart';
import '../shared/custom_drawer.dart';

class GeneralStatisticsScreen extends StatefulWidget {
  const GeneralStatisticsScreen({Key? key, this.userId}) : super(key: key);
  final String? userId;
  @override
  State<GeneralStatisticsScreen> createState() =>
      _GeneralStatisticsScreenState();
}

class _GeneralStatisticsScreenState extends State<GeneralStatisticsScreen> {
  final Widget _noGeneralStatisticsScreen = Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
        Icon(Icons.search_off, size: 150),
        SizedBox(height: 20),
        SizedBox(
            width: 250,
            child: Text('Keine Statistiken gefunden ...',
                style: TextStyle(fontSize: 25), textAlign: TextAlign.center))
      ]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Statistiken"),
      drawer: const CustomDrawer(),
      body: (GetIt.I<Backend>().isOnline)
          ?
          //
          Column(children: [
              Expanded(
                  child: FutureBuilder<dynamic>(
                      future: getStatistics(),
                      builder: (context, snapshot2) {
                        if (snapshot2.hasData) {
                          return getStatisticsScreen(snapshot2.data!);
                        } else if (snapshot2.hasError) {
                          return _noGeneralStatisticsScreen;
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      }))
            ])
          : OfflineWarning(refresh: () {
              setState(() {});
            }),
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

  Future<dynamic> getStatistics() async {
    return GetIt.instance<Backend>().get('/statistics');
  }

  Widget getStatisticsScreen(dynamic input) {
    Widget statisticsCards = _buildStatisticsCards(
        input["totalUserAmount"], input["outstandingPayments"]);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [statisticsCards],
      ),
    );
  }

  Widget _buildStatisticsCards(int totalUserAmount, int outstandingPayments) {
    return buildCard(
        child: Row(children: [
      Icon(Icons.bar_chart),
      Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allgemeine Statistiken',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Nutzer gesamt: $totalUserAmount',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Zahlungen ausstehend: ' +
                    '${((-outstandingPayments) / 100).toStringAsFixed(2).replaceAll('.', ',')} €',
                style: const TextStyle(fontSize: 14),
              )
            ],
          ))
    ]));
  }
}
