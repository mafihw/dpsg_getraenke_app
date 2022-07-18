import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:developer' as developer;

import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_bar.dart';
import '../shared/custom_drawer.dart';

class UserAdministrationScreen extends StatefulWidget {
  const UserAdministrationScreen({Key? key}) : super(key: key);

  @override
  State<UserAdministrationScreen> createState() =>
      _UserAdministrationScreenState();
}

class _UserAdministrationScreenState extends State<UserAdministrationScreen> {
  final TextEditingController _searchTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "Nutzerverwaltung"),
      drawer: CustomDrawer(),
      body: FutureBuilder(
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            List<Widget> userCards = [];
            snapshot.data!.forEach((element) {
              User? user;
              user = User.fromJson(element);
              developer.log(element.toString());
              Icon iconEnabledStatus;

              //TODO: activated if user enabled field exists
              iconEnabledStatus = Icon(Icons.check_circle_outline);
              /*
                    if(user.enabled){
                      iconEnabledStatus = Icon(Icons.check_circle_outline);
                    } else {
                      iconEnabledStatus = Icon(Icons.disabled_by_default_outlined);
                    }
                    */
              if (_searchTextController.text.isEmpty ||
                  user.name
                      .toLowerCase()
                      .contains(_searchTextController.text.toLowerCase()) ||
                  user.email
                      .toLowerCase()
                      .contains(_searchTextController.text.toLowerCase())) {
                userCards.add(buildCard(
                    child: Row(
                      children: [
                        IconButton(
                            icon: iconEnabledStatus,
                            onPressed: () {
                              //toggle enabled status here
                            }),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: ${user.name}',
                              style: TextStyle(fontSize: 20),
                            ),
                            Text(
                              'Email: ${user.email}',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Rolle: ${user.role}',
                              style: TextStyle(fontSize: 14),
                            )
                          ],
                        )
                      ],
                    ),
                    onTap: () {}));
              }
            });
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [...userCards],
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
