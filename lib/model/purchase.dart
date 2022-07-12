class Purchase {
  int id;
  int drinkId;
  String userId;
  int amount;
  double cost;
  DateTime date;
  String? drinkName;
  String? userName;

  Purchase(
      {required this.id,
      required this.drinkId,
      required this.userId,
      required this.amount,
      required this.cost,
      required this.date,
      this.drinkName,
      this.userName});

  factory Purchase.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as int;
    final drinkId = data['drinkId'] as int;
    final userId = data['userId'] as String;
    final amount = data['amount'] as int;
    final cost = double.parse(data['cost'].toString());
    final date = DateTime.parse(data['date']);
    final drinkName = data['drinkName'];
    final userName = data['userName'];
    return Purchase(
        id: id,
        drinkId: drinkId,
        userId: userId,
        amount: amount,
        cost: cost,
        date: date,
        drinkName: drinkName,
        userName: userName);
  }

  Map toJson() => {
    'id': id,
    'drinkId': drinkId,
    'userId': userId,
    'amount': amount,
    'cost': cost,
    'date': date.toString(),
    'drinkName': drinkName,
    'userName': userName
  };
}
