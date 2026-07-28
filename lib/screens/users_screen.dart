import 'dart:convert';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/permissions.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/offline_screen.dart';
import 'package:dpsg_app/screens/payments_screen.dart';
import 'package:dpsg_app/screens/profile_screen.dart';
import 'package:dpsg_app/screens/purchases_screen.dart';
import 'package:dpsg_app/shared/custom_card.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

enum SortModes { name, balance }

class UserAdministrationScreen extends StatefulWidget {
  const UserAdministrationScreen({super.key});

  @override
  State<UserAdministrationScreen> createState() =>
      _UserAdministrationScreenState();
}

class _UserAdministrationScreenState extends State<UserAdministrationScreen> {
  User? selectedUser;
  static const userRoles = [null, 'none', 'user', 'admin'];
  static const userRolesIcon = [
    Icons.groups,
    Icons.person_off,
    Icons.person,
    Icons.key,
  ];
  int selectedGroup = 0;
  String sortMode = SortModes.name.name;

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
              List<User> users = List.generate(
                snapshot.data!.length,
                (index) => User.fromJson(snapshot.data![index]),
              );
              if (sortMode == SortModes.name.name) {
                users.sort((a, b) => a.name.compareTo(b.name));
              }
              if (sortMode == SortModes.balance.name) {
                users.sort((a, b) => a.balance.compareTo(b.balance));
              }
              for (var user in users) {
                //check text input filter
                if (!(_searchTextController.text.isEmpty ||
                    user.name.toLowerCase().contains(
                      _searchTextController.text.toLowerCase(),
                    ) ||
                    user.email.toLowerCase().contains(
                      _searchTextController.text.toLowerCase(),
                    ))) {
                  continue;
                }

                if (userRoles[selectedGroup] != null &&
                    userRoles[selectedGroup] != user.role) {
                  continue;
                }

                userCards.add(
                  buildCard(
                    context: context,
                    child: Row(
                      children: [
                        Icon(
                          user.role == 'admin'
                              ? Icons.key
                              : user.role == 'user'
                              ? Icons.person
                              : user.role == 'none'
                              ? Icons.person_off
                              : Icons.question_mark,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: TextStyle(fontSize: 20)),
                              Text(
                                'Email: ${user.email}',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Kontostand: ${(user.balance / 100).toStringAsFixed(2).replaceAll('.', ',')} €",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      showCustomModalSheet(user);
                    },
                  ),
                );
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
                                icon: Icon(
                                  _searchTextController.text.isEmpty
                                      ? Icons.person_search
                                      : Icons.delete,
                                ),
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
                          icon: Icon(userRolesIcon[selectedGroup]),
                        ),
                        PopupMenuButton<SortModes>(
                          icon: Icon(Icons.sort),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          onSelected: (SortModes item) {
                            setState(() {
                              sortMode = item.name;
                            });
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<SortModes>>[
                                const PopupMenuItem<SortModes>(
                                  value: SortModes.name,
                                  child: Text('Name'),
                                ),
                                const PopupMenuItem<SortModes>(
                                  value: SortModes.balance,
                                  child: Text('Kontostand'),
                                ),
                              ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [...userCards, SizedBox(height: 20)],
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
                        child: Text(
                          'Anscheinend ist gerade niemand da...',
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
          },
          future: GetIt.instance<Backend>().get('/user'),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      bottomNavigationBar: CustomBottomBar(),
      floatingActionButton: selectedUser == null
          ? FloatingActionButton.extended(
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              backgroundColor: Theme.of(context).colorScheme.secondary,
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

  Widget buildSettingCard({
    required IconData icon,
    required String name,
    required Function onTap,
  }) {
    final child = Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, size: 32),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            name,
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    return buildCard(context: context, child: child, onTap: onTap);
  }

  void showCustomModalSheet(User user) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 30,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 10.0, right: 10.0),
              child: Divider(
                thickness: 2,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canPayForOthers,
            ))
              buildSettingCard(
                icon: Icons.euro,
                name: 'Zahlung buchen',
                onTap: () async {
                  await geldBuchen(user);
                  if(context.mounted) Navigator.pop(context);
                },
              ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canSeeAllPurchases,
            ))
              buildSettingCard(
                icon: Icons.shopping_cart,
                name: 'Käufe anzeigen',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: ((context) => PurchasesScreen(userId: user.id)),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canSeeAllPurchases,
            ))
              buildSettingCard(
                icon: Icons.payments,
                name: 'Zahlungen anzeigen',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: ((context) => PaymentsScreen(userId: user.id)),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            if (GetIt.I<PermissionSystem>().userHasPermission(
              Permission.canEditOtherUsers,
            ))
              buildSettingCard(
                icon: Icons.person_outline,
                name: 'Profil anzeigen',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        currentUser: user,
                        rebuild: performRebuild,
                      ),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                },
              ),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Future<void> geldBuchen(User user) async {
    final MoneyMaskedTextController moneyMaskedTextController =
        MoneyMaskedTextController(
          initialValue: 0,
          decimalSeparator: ',',
          thousandSeparator: '.',
          rightSymbol: '€',
        );
    await showDialog(
      context: context,
      builder: (context) {
        return customAlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: Text(
            'Geld buchen',
            style: TextStyle(fontSize: 25),
            textAlign: TextAlign.center,
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Einzahlung:", style: TextStyle(fontSize: 20)),
              SizedBox(
                width: 100,
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.right,
                  controller: moneyMaskedTextController,
                  keyboardType: TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
                ),
              ),
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
                if (moneyMaskedTextController.numberValue > 0) {
                  final body = {
                    'uuid': user.id,
                    'value': moneyMaskedTextController.numberValue * 100,
                  };
                  try {
                    await GetIt.I<Backend>().post('/payment', jsonEncode(body));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Zahlung wurde gespeichert!',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fehler beim Speichern der Zahlung!',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                    }
                  }
                }
                if (context.mounted) Navigator.pop(context);
                return;
              },
            ),
          ],
        );
      },
    );
  }
}
