import 'drink.dart';

class DrinkStatistics {
  int id;
  String name;
  int amountActual;
  int amountPurchased;
  DateTime? date;
  Drink drink;

  DrinkStatistics(
      {required this.id,
      required this.name,
      required this.amountActual,
      required this.amountPurchased,
      required this.date,
      required this.drink});

  factory DrinkStatistics.fromJson(Map<String, dynamic> data) {
    final id = data['id'];
    final name = data['name'] as String;
    final amountActual = data['amountActual'] == null ? 0 : int.parse(data['amountActual'].toString());
    final amountPurchased = data['amountPurchased'] == null ? 0 : int.parse(data['amountPurchased'].toString());
    final date = data['date'] == null ? null : DateTime.parse(data['date']);
    final drink = Drink.fromJson(data['drink']);
    return DrinkStatistics(
        id: id, name: name, amountActual: amountActual, amountPurchased: amountPurchased, date: date, drink: drink);
  }
}
