import 'dart:convert';
import 'dart:io';
import 'package:dpsg_app/connection/backend.dart';
import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

class Drink {
  int id;
  String name;
  double price;
  bool active;
  Drink(
      {required this.id,
      required this.name,
      required this.price,
      required this.active});

  factory Drink.fromJson(Map<String, dynamic> data) {
    final id = data['id'];
    final name = data['name'] as String;
    final price = double.parse(data['cost'].toString());
    final active = int.parse(data['active'].toString()) > 0;
    return Drink(id: id, name: name, price: price, active: active);
  }
}

Future<List<Drink>> fetchDrinks() async {
  //load files
  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  final drinksFile = File('$path/drinks.txt');

  //try to fetch data from server
  try {
    final response = await GetIt.instance<Backend>().get('/drink');
    if (response != null) {
      await drinksFile.writeAsString(jsonEncode(response));
    }
  } catch (e) {
    developer.log(e.toString());
  }

  //load drinks from local storage
  final drinksString = await drinksFile.readAsString();
  final drinksJson = await jsonDecode(drinksString);

  List<Drink> drinks = [];
  drinksJson.forEach((drinkJson) {
    final drink = Drink.fromJson(drinkJson);
    if (drink.active) drinks.add(drink);
  });
  return drinks;
}
