import 'dart:math';

import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:dpsg_app/shared/custom_card.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../shared/custom_app_bar.dart';
import '../shared/custom_drawer.dart';

enum sortModes { name, balance }

class LaFlammeScreen extends StatefulWidget {
  const LaFlammeScreen({Key? key}) : super(key: key);

  @override
  State<LaFlammeScreen> createState() => _LaFlammeScreenState();
}

enum Status { alleAktiv, alleInAktiv, unbekannt }

class Category {
  bool expanded = false;
  Status status = Status.alleAktiv;
  String name;
  List<Flammkuchen> flammkuchen = [];

  Category(this.name) {}

  updateStatus() {
    bool alleAktiv = true;
    bool alleInaktiv = true;
    Iterator<Flammkuchen> i = this.flammkuchen.iterator;
    while (i.moveNext()) {
      if (i.current.activated) alleInaktiv = false;
      if (!i.current.activated) alleAktiv = false;
    }
    ;
    if (alleAktiv) this.status = Status.alleAktiv;
    if (alleInaktiv) this.status = Status.alleInAktiv;
    if (!alleInaktiv && !alleAktiv) this.status = Status.unbekannt;
  }

  setActivated() {
    Iterator<Flammkuchen> i = this.flammkuchen.iterator;
    if (this.status == Status.alleAktiv) {
      while (i.moveNext()) {
        i.current.activated = false;
        developer.log('deactivated');
      }
      this.status = Status.alleInAktiv;
    } else {
      while (i.moveNext()) {
        i.current.activated = true;
      }
      this.status = Status.alleAktiv;
    }
  }

  addFlammkuchen(Flammkuchen neuerflammkuchen) {
    neuerflammkuchen.categoryName = this.name;
    this.flammkuchen.add(neuerflammkuchen);
  }
}

class Flammkuchen {
  bool activated;
  String name;
  String? categoryName;

  Flammkuchen(this.activated, this.name) {}

  factory Flammkuchen.fromJson(Map<String, dynamic> data) {
    final activated = data['activated'];
    final name = data['name'] as String;
    final categoryName = data['name'] as String;
    final Flammkuchen flammkuchen = new Flammkuchen(activated, name);
    flammkuchen.categoryName = categoryName;
    return flammkuchen;
  }
}

class _LaFlammeScreenState extends State<LaFlammeScreen> {
  User? selectedUser = null;
  int selectedGroup = 0;
  String sortMode = sortModes.name.name;
  List<Category> categories = [];
  List<Flammkuchen> letzteFlammkuchen = [];
  var numGenerator = new Random();

  _LaFlammeScreenState() {
    Category herzhaft = new Category("Herzhaft");
    herzhaft.addFlammkuchen(new Flammkuchen(true, "01 - Elsässer Original"));
    herzhaft.addFlammkuchen(
        new Flammkuchen(true, "02 - Elsässer Original Gratiniert"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "03 - Chile-Cheese"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "04 - Spinat Speck"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "05 - Paprika Schinken"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "06 - Route 66"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "07 - Hawaii"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "08 - Kikok"));
    herzhaft.addFlammkuchen(
        new Flammkuchen(true, "09 - Hackfleisch Feta Zucchini"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "10 - Salsa Fajita"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "11 - Chorizo"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "12 - Spinat"));
    herzhaft.addFlammkuchen(new Flammkuchen(true, "13 - Wiedtaler"));
    categories.add(herzhaft);

    Category veg = new Category("Vegetarisch");
    veg.addFlammkuchen(new Flammkuchen(true, "20 - Lauch Käse"));
    veg.addFlammkuchen(new Flammkuchen(true, "21 - Feta Spinat"));
    veg.addFlammkuchen(new Flammkuchen(true, "22 - Tomate Mozzarella"));
    veg.addFlammkuchen(new Flammkuchen(true, "23 - Rucola"));
    veg.addFlammkuchen(new Flammkuchen(true, "24 - Pomme De Terre"));
    veg.addFlammkuchen(new Flammkuchen(true, "25 - Preiselbeeren Camembert"));
    veg.addFlammkuchen(new Flammkuchen(true, "26 - Vier Käse"));
    categories.add(veg);

    Category meer = new Category("Aus dem Meer");
    meer.addFlammkuchen(new Flammkuchen(true, "40 - Lachs"));
    meer.addFlammkuchen(new Flammkuchen(true, "41 - Red Shrimpy"));
    meer.addFlammkuchen(new Flammkuchen(true, "42 - Green Shrimpy"));
    meer.addFlammkuchen(new Flammkuchen(true, "43 - Thunfisch Feta"));
    meer.addFlammkuchen(new Flammkuchen(true, "44 - Thunfisch Mediteran"));
    categories.add(meer);

    Category asiatisch = new Category("Asiatisch");
    asiatisch.addFlammkuchen(new Flammkuchen(true, "50 - Kikok Hiosin"));
    asiatisch.addFlammkuchen(new Flammkuchen(true, "51 - Kikok Sriracha"));
    asiatisch.addFlammkuchen(new Flammkuchen(true, "52 - Sweet Chili Shrimpy"));
    asiatisch.addFlammkuchen(new Flammkuchen(true, "53 - Tonkatsu"));
    asiatisch.addFlammkuchen(new Flammkuchen(true, "54 - Huasheng"));
    categories.add(asiatisch);

    Category tomate = new Category("Tomatenflammkuchen");
    tomate.addFlammkuchen(new Flammkuchen(true, "60 - Salamimimi Rouge"));
    tomate.addFlammkuchen(new Flammkuchen(true, "61 - Route 67 Rouge"));
    tomate.addFlammkuchen(new Flammkuchen(true, "62 - Gärtnerin Rouge"));
    tomate.addFlammkuchen(new Flammkuchen(true, "63 - BBQ Rouge"));
    tomate
        .addFlammkuchen(new Flammkuchen(true, "64 - Lachs Spinat Feta Rouge"));
    categories.add(tomate);

    Category vegan = new Category("Vegan");
    vegan.addFlammkuchen(new Flammkuchen(true, "70 - Tomate Panko"));
    vegan.addFlammkuchen(new Flammkuchen(true, "71 - Tofu Cashew"));
    vegan.addFlammkuchen(new Flammkuchen(true, "72 - Hot Tofu"));
    vegan.addFlammkuchen(new Flammkuchen(true, "73 - Rucola Cashew"));
    vegan.addFlammkuchen(new Flammkuchen(true, "74 - Himbeere"));
    vegan.addFlammkuchen(new Flammkuchen(true, "75 - Apfel"));
    categories.add(vegan);

    Category suess = new Category("Süß");
    suess.addFlammkuchen(new Flammkuchen(true, "80 - Apfel"));
    suess.addFlammkuchen(new Flammkuchen(true, "81 - Apfel Calvados"));
    suess.addFlammkuchen(new Flammkuchen(true, "82 - Schniggas"));
    suess.addFlammkuchen(new Flammkuchen(true, "83 - Himbeere"));
    suess.addFlammkuchen(new Flammkuchen(true, "84 - Himbeere Schoko"));
    suess.addFlammkuchen(new Flammkuchen(true, "85 - Banane Nutella"));
    suess.addFlammkuchen(new Flammkuchen(true, "86 - Crispy Peach"));
    categories.add(suess);
  }

  void performRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> categoriyCards = [];
    for (var category in categories) {
      categoriyCards.add(buildCard(
          child: Row(
            children: [
              Icon(category.status == Status.alleAktiv
                  ? Icons.check_box
                  : category.status == Status.alleInAktiv
                      ? Icons.check_box_outline_blank
                      : Icons.indeterminate_check_box),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(fontSize: 20),
                      )
                    ],
                  ),
                ),
              ),
              IconButton(
                  onPressed: () {
                    setState(() {
                      category.expanded = !category.expanded;
                    });
                  },
                  constraints: BoxConstraints(minHeight: 30),
                  icon: Icon(category.expanded
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down))
            ],
          ),
          onTap: () {
            category.setActivated();
            setState(() {
              developer.log('set state');
            });
          },
          onLongPress: () {
            setState(() {
              category.expanded = !category.expanded;
            });
          }));
      if (category.expanded) {
        for (var flammkuchen in category.flammkuchen) {
          categoriyCards.add(Row(
            children: [
              SizedBox(width: 20),
              Expanded(
                child: buildCard(
                    child: Row(
                      children: [
                        Icon(flammkuchen.activated
                            ? Icons.check_box
                            : Icons.check_box_outline_blank),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                flammkuchen.name,
                                style: TextStyle(fontSize: 20),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        flammkuchen.activated = !flammkuchen.activated;
                        category.updateStatus();
                      });
                    }),
              ),
            ],
          ));
        }
      }
    }
    var body = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ...categoriyCards,
                SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      appBar: CustomAppBar(appBarTitle: "La Flamme"),
      drawer: CustomDrawer(),
      body: body,
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: this.getBottomNavigationBar(context),
      floatingActionButton: selectedUser == null
          ? FloatingActionButton.extended(
              backgroundColor: kSecondaryColor,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                showSnackBar();
              },
              icon: const Icon(Icons.replay_outlined),
              label: const Text("Würfeln"),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      resizeToAvoidBottomInset: false,
    );
  }

  void showSnackBar() async {
    List<Flammkuchen> activatedFlammkuchen = [];

    Iterator<Category> categoryIterator = this.categories.iterator;
    while (categoryIterator.moveNext()) {
      Iterator<Flammkuchen> flammkuchenIterator =
          categoryIterator.current.flammkuchen.iterator;
      while (flammkuchenIterator.moveNext()) {
        if (flammkuchenIterator.current.activated)
          activatedFlammkuchen.add(flammkuchenIterator.current);
      }
    }
    String snackMsg;
    Flammkuchen? ausgewaehlterFlammkuchen;
    if (activatedFlammkuchen.length > 0) {
      int nextFlammkuchen = numGenerator.nextInt(activatedFlammkuchen.length);
      ausgewaehlterFlammkuchen = activatedFlammkuchen[nextFlammkuchen];
      snackMsg = ausgewaehlterFlammkuchen.name +
          " (" +
          ausgewaehlterFlammkuchen.categoryName! +
          ")";
    } else {
      snackMsg = "Trink Leitungswasser!";
    }
    final snackBar = SnackBar(
        content: Text(
          snackMsg,
          style: TextStyle(color: kColorScheme.onPrimary),
        ),
        duration: Duration(hours: 5),
        dismissDirection: DismissDirection.vertical,
        action: SnackBarAction(
            label: 'speichern',
            textColor: kColorScheme.onPrimary,
            onPressed: () async {
              if (ausgewaehlterFlammkuchen != null) {
                letzteFlammkuchen.add(ausgewaehlterFlammkuchen);
              }
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }));
    await ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget getBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
                builder: ((context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ))),
            IconButton(
              icon: const Icon(
                Icons.access_time_outlined,
              ),
              onPressed: () {
                showCustomModalSheet();
              },
            )
          ],
        ),
      ),
      elevation: 5,
      color: kMainColor,
    );
  }

  showCustomModalSheet() {
    List<Widget> flammkuchenCards = [];
    for (var flammkuchen in letzteFlammkuchen) {
      flammkuchenCards.add(buildCard(
          child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Text(
                flammkuchen.name + " (" + flammkuchen.categoryName! + ")",
                style: TextStyle(fontSize: 20),
                softWrap: true,
              ),
            )
          ],
        ),
      )));
    }
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: kBackgroundColor,
      context: context,
      builder: (context) => Container(
          constraints: BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
              child: Column(children: flammkuchenCards.reversed.toList()))),
    );
  }
}
