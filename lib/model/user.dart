import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:dpsg_app/connection/backend.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

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

Future<User> fetchUser() async {
  String id = GetIt.I<Backend>().loggedInUserId!;
  //load files
  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  final userFile = File('$path/user.txt');

  //try to fetch data from server
  try {
    final response = await GetIt.instance<Backend>().get('/user/$id');
    if (response != null) {
      await userFile.writeAsString(jsonEncode(response));
    }
  } catch (e) {
    developer.log(e.toString());
  }

  //load user from local storage
  final userString = await userFile.readAsString();
  final userJson = await jsonDecode(userString);
  return User.fromJson(userJson);
}
