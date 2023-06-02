import 'dart:convert';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/screens/drink_screen.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:fast_barcode_scanner/fast_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:developer' as developer;

import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

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
      appBar: CustomAppBar(
        appBarTitle: "Freunde",
        onIconPress: performRebuild,
      ),
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
                  friend.userName
                      .toLowerCase()
                      .contains(_searchTextController.text.toLowerCase()))) {
                continue;
              }

              friendCards.add(buildFriendCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 32,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, top: 20, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.userName,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  onTap: () async {
                    await showCustomModalSheet(friend);
                    performRebuild();
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
                          onPressed: () => generalInfoPopup(),
                          icon: const Icon(Icons.info)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ...friendCards,
                        IconButton(
                          icon: const Icon(Icons.person_add_alt, size: 40),
                          onPressed: () async {
                            await addFriendPopup();
                            performRebuild();
                          },
                        ),
                        const SizedBox(
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
                      children: const [
                    Icon(Icons.person_search, size: 150),
                    SizedBox(height: 20),
                    SizedBox(
                        width: 250,
                        child: Text('Anscheinend ist gerade niemand da...',
                            style: TextStyle(fontSize: 25),
                            textAlign: TextAlign.center))
                  ]));
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }
        },
        future: fetchFriends(),
      ),
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: const CustomBottomBar(),
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

  Widget buildFriendCard({required Widget child, required Function onTap}) {
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
            padding: const EdgeInsets.all(10.0),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget buildSettingCard(
      {required IconData icon, required String name, required Function onTap}) {
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
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, size: 40),
                Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(name,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center))
              ],
            ),
          ),
        ),
      ),
    );
  }

  showCustomModalSheet(Friend friend) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: kBackgroundColor,
      context: context,
      builder: (context) => Wrap(children: [
        Center(
          child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child:
                  Text(friend.userName, style: const TextStyle(fontSize: 30))),
        ),
        const Padding(
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: Divider(thickness: 2)),
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
            if (GetIt.I<Backend>().isOnline) {
              await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('Freund*in entfernen?'),
                        content: Text(
                            'Möchtest du ${friend.userName} aus deiner Freundesliste entfernen?'),
                        actions: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Nein'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _removeFriend(friend.uuid, friend.userName);
                              performRebuild();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Ja'),
                          )
                        ],
                      ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Dafür brauchst du eine Internetverbindung')));
            }
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 15),
      ]),
    );
  }

  Future<void> addFriendPopup() async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Freund*in hinzufügen')),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
        ),
        children: [
          DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const TabBar(indicatorColor: kPrimaryColor, tabs: [
                  Tab(
                    text: 'Mein QR-Code',
                  ),
                  Tab(
                    text: 'QR-Code scannen',
                  )
                ]),
                SizedBox(
                  height: 300,
                  width: 300,
                  child: TabBarView(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: QrImage(
                        data: base64.encode(utf8.encode(jsonEncode({
                          'uuid': GetIt.I<Backend>().loggedInUserId!,
                          'name': GetIt.I<Backend>().loggedInUser!.name,
                          'timestamp': DateTime.now().millisecondsSinceEpoch
                        }))),
                        version: QrVersions.auto,
                        backgroundColor: kPrimaryColor,
                        foregroundColor: kMainColor,
                        size: 200,
                      ),
                    ),
                    BarcodeCamera(
                      types: const [
                        BarcodeType.qr,
                      ],
                      resolution: Resolution.sd480,
                      framerate: Framerate.fps30,
                      mode: DetectionMode.continuous,
                      onError: (context, error) {
                        return Container(
                          color: Colors.blueGrey,
                          child: const Icon(
                            Icons.error,
                            color: kWarningColor,
                            size: 48,
                          ),
                        );
                      },
                      onScan: (code) async {
                        try {
                          var content =
                              jsonDecode(utf8.decode(base64Decode(code.value)));
                          String name = content['name'];
                          String uuid = content['uuid'];
                          int timestamp = content['timestamp'];
                          if (timestamp <
                              DateTime.now().millisecondsSinceEpoch -
                                  const Duration(minutes: 5).inMilliseconds) {
                            throw Exception('Code too old!');
                          }
                          await friendConfirmationPopup(name, uuid);
                          Navigator.pop(context);
                        } catch (e) {
                          developer.log('Error Scanning QR-Code: $e');
                        }
                      },
                      children: const [
                        MaterialPreviewOverlay(
                          animateDetection: true,
                          aspectRatio: 1,
                        ),
                      ],
                    ),
                  ]),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> friendConfirmationPopup(String name, String uuid) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Freund*in hinzufügen?'),
              content:
                  Text('Möchtest du $name zu deiner Freundesliste hinzufügen?'),
              actions: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel)),
                IconButton(
                    onPressed: () async {
                      await _addFriend(uuid, name);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check))
              ],
            ));
    performRebuild();
  }

  generalInfoPopup() {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text("Freundschaftssystem"),
              content: const Text(
                  "Hier hast du die Möglichkeit, andere Personen als Freunde hinzuzufügen. Die Personen die du hinzufügst können dann über ihr Smartphone Getränke für dich buchen und du für sie. Um jemanden zu deiner Freundesliste hinzuzufügen, scanne einfach den QR-Code der Person.\nDie Codes sind aus Sicherheitsgründen 5 Minuten gültig."),
              actions: [
                ElevatedButton.icon(
                    onPressed: () => Navigator.pop(c),
                    icon: const Icon(Icons.check),
                    label: const Text('Alles klar!'))
              ],
            ));
  }

  Future<void> _addFriend(String uuid, String name) async {
    final body = {
      'uuid': uuid,
    };
    try {
      await GetIt.I<Backend>().post('/friend', jsonEncode(body));
    } catch (e) {
      developer.log('Error while adding friend: $e');
      var friends = await fetchFriends();
      if (friends.where((element) => element.uuid == uuid).isNotEmpty) {
        developer.log('Friend is already added!');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Du bist bereits mit $name befreundet...')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Hinzufügen von $name')));
      }
    }
  }

  Future<void> _removeFriend(String uuid, String name) async {
    final body = {
      'uuid': uuid,
    };
    try {
      await GetIt.I<Backend>().delete('/friend', jsonEncode(body));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Entfernen von $name')));
      developer.log('Error while removing friend: $e');
    }
  }
}
