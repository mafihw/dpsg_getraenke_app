class User {
  String id;
  String role;
  String email;
  String name;
  double balance;
  double? weight;
  String? gender;

  User(
      {required this.id,
      required this.role,
      required this.email,
      required this.name,
      required this.balance,
      this.weight,
      this.gender});

  factory User.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as String;
    final role = data['roleId'] as String;
    final email = data['email'] as String;
    final name = data['name'] as String;
    final balance = double.parse(data['balance'].toString());
    final weight = double.tryParse(data['weight'].toString());
    final gender = data['gender'];
    return User(
        id: id,
        role: role,
        email: email,
        name: name,
        balance: balance,
        weight: weight,
        gender: gender);
  }
}
