import 'dart:convert';
import 'dart:io';

import 'dart:developer' as developer;
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class Backend {
  String apiurl = 'http://api.dpsg-gladbach.de:3000';
  bool isLoggedIn = false;
  bool isInitialized = false;
  Directory? directory;
  String? path;
  dynamic loginInformation;
  String? loggedInUserId;
  User? loggedInUser;
  dynamic token;
  File? loginFile;
  late Map<String, String> headers;

  Future<void> init() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      directory = await getApplicationDocumentsDirectory();
      path = directory!.path;
      loginFile = File('$path/loginInformation.txt');
      loginInformation = jsonDecode(await loginFile!.readAsString());
      token = loginInformation['token'];
      loggedInUserId = loginInformation['user']['id'];
      if (token != null) {
        isLoggedIn = true;
        isInitialized = true;
        await refreshData();
        headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        };
      }
    } catch (e) {
      developer.log('No login file. User not logged in.');
    }

    isInitialized = true;
  }

  Future<dynamic> get(String uri) async {
    try {
      final response = await http
          .get(Uri.parse('$apiurl/api$uri'), headers: headers)
          .timeout(const Duration(seconds: 10));
      developer.log(response.statusCode.toString());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    if (!isInitialized) {
      return false;
    } else {
      final response = await http.post(Uri.parse('$apiurl/auth/login'),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(
              <String, String>{'email': email, 'password': password}));
      developer.log(response.statusCode.toString());
      developer.log(response.body);
      if (response.statusCode == 200) {
        await loginFile?.writeAsString(response.body);
        await init();
        return true;
      } else {
        return false;
      }
    }
  }

  Future<bool> register(String email, String password, String name) async {
    if (!isInitialized) {
      return false;
    } else {
      final response = await http.post(Uri.parse('$apiurl/auth/register'),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, String>{
            'email': email,
            'password': password,
            'name': name
          }));
      developer.log(response.statusCode.toString());
      developer.log(response.body);
      if (response.statusCode == 201) {
        return await login(email, password);
      } else {
        return false;
      }
    }
  }

  void logout() {
    directory!.list().forEach((element) async {
      await element.delete(recursive: true);
    });
    loginInformation = null;
    loggedInUser = null;
    isLoggedIn = false;
  }

  Future<bool> refreshData() async {
    if (!isInitialized || !isLoggedIn) {
      return false;
    } else {
      try {
        await fetchDrinks();
        loggedInUser = await fetchUser();
        return true;
      } catch (e) {
        developer.log(e.toString());
        return false;
      }
    }
  }
}
