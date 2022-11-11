import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';

class Drink {
  int id;
  String name;
  int cost;
  bool active;
  bool deleted;

  Drink(
      {required this.id,
      required this.name,
      required this.cost,
      required this.active,
      required this.deleted});

  factory Drink.fromJson(Map<String, dynamic> data) {
    final id = data['id'];
    final name = data['name'] as String;
    final cost = int.parse(data['cost'].toString());
    final active = int.parse(data['active'].toString()) > 0;
    final deleted = int.parse(data['deleted'].toString()) > 0;
    return Drink(
        id: id, name: name, cost: cost, active: active, deleted: deleted);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
      'active': active ? 1 : 0,
      'deleted': deleted ? 1 : 0,
    };
  }
}

Future<List<Drink>> fetchDrinks() async {
  var database = GetIt.I<LocalDB>();
  List<Drink> drinks = [];
  try {
    final response = await GetIt.instance<Backend>().get('/drink');
    if (response != null) {
      for (var drinkJson in response) {
        drinks.add(Drink.fromJson(drinkJson));
      }
      await database.insertDrinks(drinks);
    }
  } catch (e) {
    developer.log(e.toString());
  }

  if (drinks.isEmpty) {
    drinks = await database.fetchDrinks();
  }

  return drinks;
}
