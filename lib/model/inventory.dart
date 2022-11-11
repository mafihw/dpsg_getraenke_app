class Inventory {
  int id;
  int drinkId;
  String userCreatedId;
  int amountActual;
  int amountCalculated;
  DateTime date;
  String? drinkName;

  Inventory(
      {required this.id,
      required this.drinkId,
      required this.userCreatedId,
      required this.amountActual,
      required this.amountCalculated,
      required this.date,
      this.drinkName
      });

  factory Inventory.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as int;
    final drinkId = data['drinkId'] as int;
    final userCreatedId = data['userCreatedId'] as String;
    final amountActual = data['amountActual'] as int;
    final amountCalculated = data['amountCalculated'] as int;
    final date = DateTime.parse(data['date']);
    final drinkName = data['drinkName'];
    return Inventory(
        id: id,
        drinkId: drinkId,
        userCreatedId: userCreatedId,
        amountActual: amountActual,
        amountCalculated: amountCalculated,
        date: date,
        drinkName: drinkName);
  }

  Map toJson() => {
    'id': id,
    'drinkId': drinkId,
    'userCreatedId': userCreatedId,
    'amountActual': amountActual,
    'amountCalculated': amountCalculated,
    'date': date.toString(),
    'drinkName': drinkName
  };
}
