import 'dart:async';
import 'dart:developer';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/storage_interface.dart';
import 'package:dpsg_app/model/permissions.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/offline_screen.dart';
import 'package:dpsg_app/screens/profile_screen.dart';
import 'package:dpsg_app/shared/custom_card.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:dpsg_app/shared/status_led.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../model/purchase.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key, this.userId});
  final String? userId;
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
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

  final Widget _noPurchasesScreen = Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Icon(Icons.person_search, size: 150),
        SizedBox(height: 20),
        SizedBox(
          width: 250,
          child: Text(
            'Du hast bisher noch nichts gekauft ...',
            style: TextStyle(fontSize: 25),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarTitle: "Buchungen",
        onIconPress: () {
          setState(() {});
        },
      ),
      drawer: const CustomDrawer(),
      body: () {
        if (GetIt.I<Backend>().isOnlineMode) {
          return Column(
            children: [
              getFilters(),
              Expanded(
                child: FutureBuilder<dynamic>(
                  future: getPurchases(widget.userId),
                  builder: (context, snapshot2) {
                    if (snapshot2.hasData) {
                      if (snapshot2.data.isEmpty) {
                        return _noPurchasesScreen;
                      } else {
                        return _buildOnlinePurchases(snapshot2.data!);
                      }
                    } else if (snapshot2.hasError) {
                      return _noPurchasesScreen;
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ],
          );
        } else {
          //app is not connected to server
          if (widget.userId == null) {
            return _noPurchasesScreen;
          } else {
            return FutureBuilder<List<Purchase>>(
              future: GetIt.I<StorageInterface>().getUnsentPurchases(),
              builder: (context, snapshot2) {
                if (snapshot2.hasData && snapshot2.data!.isNotEmpty) {
                  return _buildOfflinePurchases(snapshot2.data!);
                } else {
                  return OfflineWarning(
                    refresh: () {
                      setState(() {});
                    },
                  );
                }
              },
            );
          }
        }
      }.call(),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      bottomNavigationBar: const CustomBottomBar(),
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

  Future<dynamic> getPurchases([String? userId]) async {
    final String dateStartSearchString =
        '?from=${(startDate.millisecondsSinceEpoch / 1000).toStringAsFixed(0)}';
    final String dateEndSearchString =
        '&to=${(endDate.add(const Duration(days: 1)).millisecondsSinceEpoch / 1000).toStringAsFixed(0)}';
    final String userSearchString = userId != null ? '&userId=$userId' : '';
    await GetIt.instance<Backend>().sendLocalPurchasesToServer();
    return GetIt.instance<Backend>().get(
      '/purchase$dateStartSearchString$dateEndSearchString$userSearchString',
    );
  }

  Future<dynamic> deletePurchase(int purchaseId) async {
    try {
      await GetIt.instance<Backend>().delete('/purchase/$purchaseId', null);
    } catch (e) {
      log('Error deleting purchase: $e');
    }
  }

  List<Widget> _buildPurchasesCards(List<Purchase> purchases) {
    List<Widget> purchasesCards = [];
    purchases.sort((a, b) => b.date.compareTo(a.date));
    for (var purchase in purchases) {
      purchasesCards.add(
        buildCard(
          context: context,
          background: purchase.deleted
              ? HSLColor.fromColor(
                  Theme.of(context).colorScheme.surface,
                ).withLightness(0.9).withAlpha(0.7).toColor()
              : null,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 5, right: 10),
                child: Icon(Icons.local_drink),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${purchase.deleted ? 'Storniert: ' : ''}${purchase.amount} x ${purchase.drinkName}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (widget.userId == null)
                    Text(
                      'Nutzer: ${purchase.userName}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  Text(
                    DateFormat(
                      'dd.MM.yyyy, HH:mm',
                    ).format(purchase.date.toLocal()),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${((purchase.cost / 100) * purchase.amount).toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: const TextStyle(fontSize: 14),
                  ),
                  ((widget.userId != null &&
                              purchase.userBookedId != widget.userId) ||
                          (purchase.userBookedId != purchase.userId &&
                              widget.userId == null))
                      ? Text('Gebucht von ${purchase.userBookedName}')
                      : (widget.userId != null &&
                            purchase.userId != widget.userId)
                      ? Text('Gebucht für ${purchase.userName}')
                      : const SizedBox(),
                ],
              ),
            ],
          ),
          onTap: () {
            if (GetIt.I<Backend>().isOnlineMode &&
                (GetIt.I<PermissionSystem>().userHasPermission(
                          Permission.canEditOtherUsers,
                        ) &&
                        purchase.userBookedName.trim() != '' &&
                        purchase.userBookedId !=
                            GetIt.I<Backend>().loggedInUserId ||
                    !purchase.deleted)) {
              showCustomModalSheet(purchase);
            }
          },
        ),
      );
    }
    return purchasesCards;
  }

  void showCustomModalSheet(Purchase purchase) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
                child: Text(
                  '${purchase.amount}x ${purchase.drinkName} für ${(purchase.cost * purchase.amount / 100).toStringAsFixed(2).replaceAll('.', ',')}€',
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
            !purchase.deleted
                ? buildSettingCard(
                    icon: Icons.cancel,
                    name: 'Buchung stornieren',
                    onTap: () async {
                      await deletePurchase(purchase.id);
                      if(context.mounted) Navigator.pop(context);
                      setState(() {});
                    },
                  )
                : Container(),
            GetIt.I<PermissionSystem>().userHasPermission(
                      Permission.canEditOtherUsers,
                    ) &&
                    purchase.userBookedName.trim() != '' &&
                    purchase.userBookedId != GetIt.I<Backend>().loggedInUserId
                ? buildSettingCard(
                    icon: Icons.person,
                    name: purchase.userBookedName,
                    onTap: () async {
                      User user = User.fromJson(
                        await GetIt.I<Backend>().get(
                          '/user/${purchase.userBookedId}',
                        ),
                      );
                      if(context.mounted){
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            currentUser: user,
                            rebuild: () {
                              setState(() {});
                            },
                          ),
                        ),
                      );
                      if(context.mounted) Navigator.pop(context);
                      setState(() {});
                      }
                    },
                  )
                : Container(),
            const SizedBox(height: 15),
          ],
        ),
      ),
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
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    return buildCard(context: context, child: child, onTap: onTap);
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

  SingleChildScrollView _buildOfflinePurchases(List<Purchase> purchases) {
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
        color: Theme.of(context).colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StatusLed(color: Colors.red),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Offline-Käufe',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Die hier aufgelisteten Käufe sind vorgemerkt und werden erst übernommen, wenn du die App mit einer aktiven Internetverbindung öffnest.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
