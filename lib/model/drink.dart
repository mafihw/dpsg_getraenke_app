import 'package:flutter/material.dart';

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
