class NewDrink {
  int id;
  int drinkId;
  int amount;
  DateTime date;
  String userCreatedId;
  String drinkName;

  NewDrink(
      {required this.id,
      required this.drinkId,
      required this.amount,
      required this.date,
      required this.userCreatedId,
      required this.drinkName});

  factory NewDrink.fromJson(Map<String, dynamic> data) {
    final id = data['id'];
    final drinkId = data['drinkId'];
    final amount = data['amount'];
    final date = DateTime.parse(data['date']);
    final userCreatedId = data['userCreatedId'] as String;
    final drinkName = data['drinkName'] as String;
    return NewDrink(
        id: id,
        drinkId: drinkId,
        amount: amount,
        date: date,
        userCreatedId: userCreatedId,
        drinkName: drinkName);
  }
}
