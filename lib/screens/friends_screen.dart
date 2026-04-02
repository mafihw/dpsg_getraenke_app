import 'dart:convert';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/drink_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:developer' as developer;

import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  User? selectedUser;

  final TextEditingController _searchTextController = TextEditingController();

  void performRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Freunde", onIconPress: performRebuild),
      drawer: const CustomDrawer(),
      body: FutureBuilder(
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            List<Widget> friendCards = [];
            List<Friend> friends = snapshot.data!;
            friends.sort((a, b) => a.userName.compareTo(b.userName));
            for (var friend in friends) {
              //check text input filter
              if (!(_searchTextController.text.isEmpty ||
                  friend.userName.toLowerCase().contains(
                    _searchTextController.text.toLowerCase(),
                  ))) {
                continue;
              }

              friendCards.add(
                buildFriendCard(
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 32),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          top: 20,
                          bottom: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.userName,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await showCustomModalSheet(friend);
                    performRebuild();
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
                        onPressed: () => generalInfoPopup(),
                        icon: const Icon(Icons.info),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.person_add_alt),
                  onPressed: () => addFriendPopup(),
                  label: const Text('Freund*in hinzufügen'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [...friendCards],
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
                  children: const [
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
              return const Center(child: CircularProgressIndicator());
            }
          }
        },
        future: fetchFriends(),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      bottomNavigationBar: const CustomBottomBar(),
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

  Widget buildFriendCard({required Widget child, required Function onTap}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: () => onTap(),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(padding: const EdgeInsets.all(10.0), child: child),
        ),
      ),
    );
  }

  Widget buildSettingCard({
    required IconData icon,
    required String name,
    required Function onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: () => onTap(),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, size: 40),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showCustomModalSheet(Friend friend) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      context: context,
      builder: (context) => Wrap(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                friend.userName,
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
          buildSettingCard(
            icon: FontAwesomeIcons.wineBottle,
            name: 'Getränk buchen',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DrinkScreen(userId: friend.uuid),
                ),
              );
            },
          ),
          buildSettingCard(
            icon: Icons.person_off,
            name: 'Freundschaft kündigen',
            onTap: () async {
              if (GetIt.I<Backend>().isOnlineMode) {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Freund*in entfernen?'),
                    content: Text(
                      'Möchtest du ${friend.userName} aus deiner Freundesliste entfernen?',
                    ),
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Nein'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _removeFriend(friend.uuid, friend.userName);
                          performRebuild();
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Ja'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Dafür brauchst du eine Internetverbindung',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Future<void> addFriendPopup() async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Expanded(child: Text('Freund*in hinzufügen')),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        children: [
          DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TabBar(
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: [
                    Tab(text: 'Mein QR-Code'),
                    Tab(text: 'QR-Code scannen'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  width: 300,
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: QrImageView(
                          data: base64.encode(
                            utf8.encode(
                              jsonEncode({
                                'uuid': GetIt.I<Backend>().loggedInUserId!,
                                'name': GetIt.I<Backend>().loggedInUser!.name,
                                'timestamp':
                                    DateTime.now().millisecondsSinceEpoch,
                              }),
                            ),
                          ),
                          version: QrVersions.auto,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          size: 200,
                        ),
                      ),
                      kIsWeb
                          ? SizedBox(
                              width: 200,
                              height: 200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    size: 64,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'QR-Code Scannen\nnur in der App verfügbar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : MobileScanner(
                              onDetect: (result) async {
                                try {
                                  var content = jsonDecode(
                                    utf8.decode(
                                      base64Decode(
                                        result.barcodes.first.rawValue!,
                                      ),
                                    ),
                                  );
                                  String name = content['name'];
                                  String uuid = content['uuid'];
                                  int timestamp = content['timestamp'];
                                  if (timestamp <
                                      DateTime.now().millisecondsSinceEpoch -
                                          const Duration(
                                            minutes: 5,
                                          ).inMilliseconds) {
                                    throw Exception('Code too old!');
                                  }
                                  await friendConfirmationPopup(name, uuid);
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  developer.log('Error Scanning QR-Code: $e');
                                }
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    setState(() {});
  }

  Future<void> friendConfirmationPopup(String name, String uuid) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Freund*in hinzufügen?'),
        content: Text('Möchtest du $name zu deiner Freundesliste hinzufügen?'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
          IconButton(
            onPressed: () async {
              await _addFriend(uuid, name);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
    );
    performRebuild();
  }

  void generalInfoPopup() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Freundschaftssystem"),
        content: const Text(
          "Hier hast du die Möglichkeit, andere Personen als Freunde hinzuzufügen. Die Personen die du hinzufügst können dann über ihr Smartphone Getränke für dich buchen und du für sie. Um jemanden zu deiner Freundesliste hinzuzufügen, scanne einfach den QR-Code der Person.\nDie Codes sind aus Sicherheitsgründen 5 Minuten gültig.",
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(c),
            icon: const Icon(Icons.check),
            label: const Text('Alles klar!'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFriend(String uuid, String name) async {
    final body = {'uuid': uuid};
    try {
      await GetIt.I<Backend>().post('/friend', jsonEncode(body));
    } catch (e) {
      developer.log('Error while adding friend: $e');
      var friends = await fetchFriends();
      if (friends.where((element) => element.uuid == uuid).isNotEmpty) {
        developer.log('Friend is already added!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Du bist bereits mit $name befreundet...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fehler beim Hinzufügen von $name',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _removeFriend(String uuid, String name) async {
    final body = {'uuid': uuid};
    try {
      await GetIt.I<Backend>().delete('/friend', jsonEncode(body));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim Entfernen von $name',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        );
        developer.log('Error while removing friend: $e');
      }
    }
  }
}
