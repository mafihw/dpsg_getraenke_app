class Payment {
  int id;
  String userId;
  int value;
  int balanceAfter;
  DateTime date;

  Payment(
      {required this.id,
      required this.userId,
      required this.value,
      required this.balanceAfter,
      required this.date});

  factory Payment.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as int;
    final userId = data['userId'] as String;
    final value = data['value'] as int;
    final balanceAfter = int.parse(data['balanceAfter'].toString());
    final date = DateTime.parse(data['date']);
    return Payment(
        id: id,
        userId: userId,
        value: value,
        balanceAfter: balanceAfter,
        date: date);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'value': value,
        'balanceAfter': balanceAfter,
        'date': date.toString()
      };
}
