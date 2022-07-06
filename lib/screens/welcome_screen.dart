import 'dart:convert';
import 'dart:io';

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (context, AsyncSnapshot<User> snapshot) {
        if (snapshot.hasData) {
          return Container(
            color: kBackgroundColor,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  buildCard(
                      child: Column(
                        children: [
                          Text(
                            'Hallo ${snapshot.data!.name}',
                            style: TextStyle(fontSize: 24),
                          ),
                          Text(
                            'Willkommen zurück!',
                            style: TextStyle(fontSize: 18),
                          )
                        ],
                      ),
                      onTap: () {
                        print("Profil");
                      }),
                  buildCard(
                    child: Column(
                      children: [
                        Text(
                          'Dein Kontostand:',
                          style: TextStyle(fontSize: 24),
                        ),
                        Text(
                          '${snapshot.data!.balance.toStringAsFixed(2).replaceAll('.', ',')} €',
                          style: TextStyle(fontSize: 48),
                        )
                      ],
                    ),
                    onTap: () {
                      print("Bezahlen");
                    },
                  ),
                  buildCard(
                    child: Column(
                      children: [
                        Text(
                          'Letzte Buchung:',
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          'Vor 12 Tagen:',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          '3x Paulaner Spezi für 3 €',
                          style: TextStyle(fontSize: 18),
                        )
                      ],
                    ),
                    onTap: () {
                      print("letzte Buchung");
                    },
                  ),
                  IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: buildCard(
                              child: Column(
                                children: [
                                  Text('Schnellwahltaste',
                                      style: TextStyle(fontSize: 16)),
                                  Icon(
                                    Icons.add,
                                    size: 48,
                                  ),
                                  Text('1x Bier buchen'),
                                ],
                              ),
                              onTap: () {
                                print("BIERBUCHEN");
                              }),
                        ),
                        Expanded(
                          child: buildCard(
                            child: Column(
                              children: [
                                Text(
                                  'Bezahlen',
                                  style: TextStyle(fontSize: 24),
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                Icon(
                                  FontAwesomeIcons.paypal,
                                  size: 48,
                                ),
                              ],
                            ),
                            onTap: () async {
                              Uri url = Uri.parse(
                                  // TODO: Richtige paypal.me Adresse einfügen!!!!!!!!!!!!!!!!!!!!!!!!
                                  'https://paypal.me/blozom/${(-snapshot.data!.balance)}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                developer.log("url $url cant be launched");
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
      future: fetchUser(),
    );
  }

  Widget buildCard({required Column child, required Function onTap}) {
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
            padding: const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );
  }

  Future<User> fetchUser() async {
    //load files
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final userFile = File('$path/user.txt');
    User? user;

    //try to fetch data from server
    try {
      String loggedInUserId = GetIt.instance<Backend>().loggedInUser!.id;
      final response =
          await GetIt.instance<Backend>().get('/user/$loggedInUserId');
      if (response != null) {
        await userFile.writeAsString(jsonEncode(response));
        print("before");
        user = User.fromJson(response);
        print("after");
      }
    } catch (e) {
      developer.log(e.toString());
    }

    //load user from local storage
    if (user == null) {
      final userString = await userFile.readAsString();
      final userJson = await jsonDecode(userString);
      user = User.fromJson(userJson);
    }

    return user;
  }
}
