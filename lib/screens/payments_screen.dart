import 'dart:async';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/screens/offline-screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../model/payment.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_card.dart';
import '../shared/custom_drawer.dart';

class PaymentsScreen extends StatefulWidget {
  PaymentsScreen({Key? key, this.userId}) : super(key: key);
  String? userId;
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  var startDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .subtract(const Duration(days: 90));
  var endDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  final Widget _noPaymentsScreen = Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 150),
            SizedBox(height: 20),
            SizedBox(
                width: 250,
                child: Text('Noch keine Zahlungen erhalten ...',
                    style: TextStyle(fontSize: 25), textAlign: TextAlign.center))
          ]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Zahlungen"),
      drawer: CustomDrawer(),
      body: OfflineCheck(
        builder: (context) => FutureBuilder(
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            return Column(
              children: [getFilters(), Expanded(child: getBody(snapshot))],
            );
          },
          future: getPayments(widget.userId),
        ),
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

  Widget getBody(snapshot) {
    if (snapshot.hasData) {
      if(snapshot.data.isEmpty){
        return _noPaymentsScreen;
      }
      List<Widget> PaymentsCards = [];
      List<Payment> Payments = [];
      snapshot.data!.forEach((element) {
        Payment? payment;
        payment = Payment.fromJson(element);
        Payments.add(payment);
      });
      Payments.sort((a, b) => b.date.compareTo(a.date));
      Payments.forEach((payment) {
        PaymentsCards.add(buildCard(
            child: Row(
              children: [
                Icon(Icons.euro),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('dd.MM.yyyy, kk:mm').format(payment.date.toLocal())}',
                        style: TextStyle(fontSize: 20),
                      ),
                      if (widget.userId == null)
                        Text(
                          'Nutzer: ' + (payment.userName == null ? '-' : payment.userName!),
                          style: const TextStyle(fontSize: 14),
                        ),
                      Text(
                        'Betrag: ${((payment.value / 100)).toStringAsFixed(2).replaceAll('.', ',')} €',
                        style: TextStyle(fontSize: 14),
                      )
                    ],
                  ),
                )
              ],
            )));
      });
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [...PaymentsCards],
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
                      child: Text('Keine Zahlungen gefunden ...',
                          style: TextStyle(fontSize: 25),
                          textAlign: TextAlign.center))
                ]));
      } else {
        return Center(
            child: CircularProgressIndicator(),
          );
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
          child: ElevatedButton(
            onPressed: () async {
              final selectedDate = await selectDate(
                  context: context,
                  initialDate: startDate,
                  firstDate: DateTime(2021, 12, 01),
                  lastDate: endDate);
              if (selectedDate != null)
                setState(() {
                  startDate = selectedDate;
                });
            },
            style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0)))),
            child: IntrinsicWidth(
              child: Text('von: ' +
                  DateFormat('dd.MM.yyyy').format(startDate.toLocal())),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              final selectedDate = await selectDate(
                  context: context,
                  initialDate: endDate,
                  firstDate: startDate,
                  lastDate: DateTime.now());
              if (selectedDate != null)
                setState(() {
                  endDate = selectedDate;
                });
            },
            style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0)))),
            child: IntrinsicWidth(
              child: Text(
                  'bis: ' + DateFormat('dd.MM.yyyy').format(endDate.toLocal())),
            ),
          ),
        ),
      ],
    );
  }

  Future<dynamic> getPayments([String? userId]) async {
    final String dateStartSearchString =
        '?from=' + (startDate.millisecondsSinceEpoch / 1000).toStringAsFixed(0);
    final String dateEndSearchString = '&to=' +
        (endDate.add(Duration(days: 1)).millisecondsSinceEpoch / 1000)
            .toStringAsFixed(0);
    final String userSearchString = userId != null ? '&userId=' + userId : '';
    await GetIt.instance<Backend>().sendLocalPurchasesToServer();
    return GetIt.instance<Backend>().get('/payment' +
        dateStartSearchString +
        dateEndSearchString +
        userSearchString);
  }
}
