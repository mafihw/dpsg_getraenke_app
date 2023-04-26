import 'dart:convert';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/permissions.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/offline-screen.dart';
import 'package:dpsg_app/screens/payments_screen.dart';
import 'package:dpsg_app/screens/profile_screen.dart';
import 'package:dpsg_app/screens/purchases_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_card.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:get_it/get_it.dart';

import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

enum sortModes { name, balance }

class UserAdministrationScreen extends StatefulWidget {
  const UserAdministrationScreen({Key? key}) : super(key: key);

  @override
  State<UserAdministrationScreen> createState() =>
      _UserAdministrationScreenState();
}

class _UserAdministrationScreenState extends State<UserAdministrationScreen> {
  User? selectedUser = null;
  static const userRoles = [null, 'none', 'user', 'admin'];
  static const userRolesIcon = [
    Icons.groups,
    Icons.person_off,
    Icons.person,
    Icons.key
  ];
  int selectedGroup = 0;
  String sortMode = sortModes.name.name;

  final TextEditingController _searchTextController = TextEditingController();

  void performRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Nutzerverwaltung"),
      drawer: CustomDrawer(),
      body: OfflineCheck(
        builder: (context) => FutureBuilder(
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              List<Widget> userCards = [];
              List<User> users = List.generate(snapshot.data!.length,
                  (index) => User.fromJson(snapshot.data![index]));
              if(sortMode == sortModes.name.name) users.sort((a, b) => a.name.compareTo(b.name));
              if(sortMode == sortModes.balance.name) users.sort((a, b) => a.balance.compareTo(b.balance));
              for (var user in users) {
                //check text input filter
                if (!(_searchTextController.text.isEmpty ||
                    user.name
                        .toLowerCase()
                        .contains(_searchTextController.text.toLowerCase()) ||
                    user.email
                        .toLowerCase()
                        .contains(_searchTextController.text.toLowerCase()))) {
                  continue;
                }

                if (userRoles[selectedGroup] != null &&
                    userRoles[selectedGroup] != user.role) {
                  continue;
                }

                userCards.add(buildCard(
                    child: Row(
                      children: [
                        Icon(user.role == 'admin'
                            ? Icons.key
                            : user.role == 'user'
                                ? Icons.person
                                : user.role == 'none'
                                    ? Icons.person_off
                                    : Icons.question_mark),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(fontSize: 20),
                              ),
                              Text(
                                'Email: ${user.email}',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Kontostand: ' +
                                    (user.balance / 100)
                                        .toStringAsFixed(2)
                                        .replaceAll('.', ',') +
                                    " €",
                                style: TextStyle(fontSize: 14),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    onTap: () {
                      showCustomModalSheet(user);
                    }));
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchTextController,
                            decoration: InputDecoration(
                              hintText: 'Suche',
                              suffixIcon: IconButton(
                                icon: Icon(_searchTextController.text.isEmpty
                                    ? Icons.person_search
                                    : Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _searchTextController.clear();
                                  });
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              ),
                            ),
                            onChanged: (query) {
                              setState(() {});
                            },
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              setState(() {
                                selectedGroup = ++selectedGroup % 4;
                              });
                            },
                            icon: Icon(userRolesIcon[selectedGroup])),
                        PopupMenuButton<sortModes>(
                            icon: Icon(Icons.sort),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            color: kColorScheme.surface,
                            onSelected: (sortModes item) {
                              setState(() {
                                sortMode = item.name;
                              });
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<sortModes>>[
                                  const PopupMenuItem<sortModes>(
                                    value: sortModes.name,
                                    child: Text('Name'),
                                  ),
                                  const PopupMenuItem<sortModes>(
                                    value: sortModes.balance,
                                    child: Text('Kontostand'),
                                  ),
                                ]),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ...userCards,
                          SizedBox(
                            height: 20,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
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
          future: GetIt.instance<Backend>().get('/user'),
        ),
      ),
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: CustomBottomBar(),
      floatingActionButton: selectedUser == null
          ? FloatingActionButton.extended(
              backgroundColor: kSecondaryColor,
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Zurück"),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      resizeToAvoidBottomInset: false,
    );
  }


  Widget buildSettingCard(
      {required IconData icon, required String name, required Function onTap}) {
    final child = Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, size: 40),
        Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(name,
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center))
      ],
    );
    return buildCard(child: child, onTap: onTap);
  }

  showCustomModalSheet(User user) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: kBackgroundColor,
      context: context,
      builder: (context) => Wrap(children: [
        Center(
          child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(user.name, style: TextStyle(fontSize: 30))),
        ),
        const Padding(
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: Divider(thickness: 2)),
        if (GetIt.I<PermissionSystem>()
            .userHasPermission(Permission.canPayForOthers))
          buildSettingCard(
            icon: Icons.euro,
            name: 'Zahlung buchen',
            onTap: () async {
              await geldBuchen(user);
              Navigator.pop(context);
            },
          ),
        if (GetIt.I<PermissionSystem>()
            .userHasPermission(Permission.canSeeAllPurchases))
          buildSettingCard(
              icon: Icons.shopping_cart,
              name: 'Käufe anzeigen',
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) => PurchasesScreen(userId: user.id))));
                Navigator.pop(context);
              }),
        if (GetIt.I<PermissionSystem>()
            .userHasPermission(Permission.canSeeAllPurchases))
          buildSettingCard(
              icon: Icons.payments,
              name: 'Zahlungen anzeigen',
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) => PaymentsScreen(userId: user.id))));
                Navigator.pop(context);
              }),
        if (GetIt.I<PermissionSystem>()
            .userHasPermission(Permission.canEditOtherUsers))
          buildSettingCard(
            icon: Icons.person_outline,
            name: 'Profil anzeigen',
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                          currentUser: user, rebuild: performRebuild)));
              Navigator.pop(context);
              setState(() {});
            },
          ),
        SizedBox(height: 15),
      ]),
    );
  }

  Future<void> geldBuchen(User user) async {
    MoneyMaskedTextController _MoneyMaskedTextController =
        new MoneyMaskedTextController(
            decimalSeparator: '.', thousandSeparator: ',', rightSymbol: '€');
    await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: Text('Geld buchen',
                style: TextStyle(fontSize: 25), textAlign: TextAlign.center),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Einzahlung:", style: TextStyle(fontSize: 20)),
                SizedBox(
                    width: 100,
                    child: TextField(
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.right,
                      controller: _MoneyMaskedTextController,
                      keyboardType: TextInputType.numberWithOptions(
                          signed: false, decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9]+[,.]{0,1}[0-9]*')),
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                            text: newValue.text.replaceAll('.', ','),
                          ),
                        ),
                      ],
                    ))
              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                child: Text('Abbrechen'),
                onPressed: () {
                  Navigator.pop(context);
                  return;
                },
              ),
              ElevatedButton(
                child: Text('Bestätigen'),
                onPressed: () async {
                  if (_MoneyMaskedTextController.numberValue > 0) {
                    final body = {
                      'uuid': user.id,
                      'value': _MoneyMaskedTextController.numberValue * 100
                    };
                    try {
                      await GetIt.I<Backend>()
                          .post('/payment', jsonEncode(body));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Zahlung wurde gespeichert!')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Fehler beim Speichern der Zahlung!'),
                        backgroundColor: kWarningColor,
                      ));
                    }
                  }
                  Navigator.pop(context);
                  return;
                },
              ),
            ],
          );
        });
  }
}
