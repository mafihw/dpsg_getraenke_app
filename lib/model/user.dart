import 'dart:developer' as developer;
import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/storage_interface.dart';
import 'package:dpsg_app/model/permissions.dart';
import 'package:get_it/get_it.dart';

class User {
  String id;
  String role;
  String email;
  String name;
  int balance;
  int? weight;
  String? gender;

  User({
    required this.id,
    required this.role,
    required this.email,
    required this.name,
    required this.balance,
    this.weight,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as String;
    final role = data['roleId'] as String;
    final email = data['email'] as String;
    final name = data['name'] as String;
    final balance = int.parse(data['balance'].toString());
    final weight = int.tryParse(data['weight'].toString());
    final gender = data['gender'];
    return User(
      id: id,
      role: role,
      email: email,
      name: name,
      balance: balance,
      weight: weight,
      gender: gender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleId': role,
      'email': email,
      'name': name,
      'balance': balance,
      'weight': weight,
      'gender': gender,
    };
  }
}

Future<User> fetchUser() async {
  User? user;
  if (GetIt.I<Backend>().isOnlineMode) {
    GetIt.I<PermissionSystem>().fetchPermissions();
    String id = GetIt.I<Backend>().loggedInUserId!;

    //try to fetch data from server
    try {
      final response = await GetIt.instance<Backend>().get('/user/$id');
      if (response != null) {
        user = User.fromJson(response);
        // Only update user data, preserve existing token
        final currentLoginInfo = await GetIt.I<StorageInterface>()
            .getLoginInformation();
        if (currentLoginInfo != null) {
          GetIt.I<StorageInterface>().setLoginInformation({
            'user': user.toJson(),
            'token': currentLoginInfo['token'], // Preserve existing token
          });
        }
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }
  //load user from local storage
  final loginInfo = await GetIt.I<StorageInterface>().getLoginInformation();
  if (loginInfo != null && loginInfo['user'] != null) {
    user = User.fromJson(loginInfo['user']);
  }

  return user!;
}
