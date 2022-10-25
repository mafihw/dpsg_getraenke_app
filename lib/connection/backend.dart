import 'dart:convert';
import 'dart:io';

import 'dart:developer' as developer;
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/shared/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import '../model/purchase.dart';

class Backend {
  String apiurl = 'https://api.dpsg-gladbach.de:3001';
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
        headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        };
        await refreshData();
      }
    } catch (e) {
      developer.log('No login file. User not logged in.');
    }

    isInitialized = true;
  }

  Future<dynamic> get(String uri) async {
    try {
      final response = await http
          .get(Uri.parse('$apiurl/api$uri'), headers: await getHeader())
          .timeout(const Duration(seconds: 10));
      developer.log(response.statusCode.toString() + '  ' + uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<dynamic> post(String uri, String body) async {
    try {
      final url = Uri.parse('$apiurl/api$uri');
      developer.log('POST: url:${url} body: ${body}');
      final response = await http
          .post(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: 10));
      developer.log(response.statusCode.toString() + '  ' + uri + '  ' + body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<dynamic> patch(String uri, String body) async {
    try {
      final url = Uri.parse('$apiurl/api$uri');
      developer.log('PATCH: url:$url');
      final response = await http
          .patch(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: 10));
      developer.log(response.statusCode.toString() + '  ' + uri + '  ' + body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<dynamic> delete(String uri, String? body) async {
    try {
      final url = Uri.parse('$apiurl/api$uri');
      developer.log('DELETE: url:$url body: $body');
      final response = await http
          .delete(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: 10));
      developer.log(
          response.statusCode.toString() + '  ' + uri + '  ' + (body ?? ''));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<bool> login(String? email, String? password) async {
    if (email == null || password == null) {
      return false;
    }
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

  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup("api.dpsg-gladbach.de");
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  Future<bool> sentLocalPurchasesToServer() async {
    bool purchasesSent = false;
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final purchasesFile = File('$path/unDonePurchases.txt');
    if (await purchasesFile.exists()) {
      if (await checkConnection()) {
        for (var element
            in List.from(jsonDecode(await purchasesFile.readAsString()))) {
          Purchase.fromJson(element);
          final body = {
            "uuid": element["userId"],
            "drinkid": element["drinkId"],
            "amount": element["amount"],
            "date": element["date"]
          };
          developer.log('Sending purchase to server');
          try {
            await post('/purchase', jsonEncode(body));
            purchasesSent = true;
            await Future.delayed(const Duration(milliseconds: 500));
            developer.log('Successfully sent purchase to server');
          } catch (error) {
            developer.log(
                'Error while sending purchase to server: ' + error.toString());
          }
        }
        purchasesFile.delete();
      }
    } else {
      purchasesSent = true;
    }
    return purchasesSent;
  }

  Future<Map<String, String>> getHeader() async {
    if(checkTokenValidity()) {
    return headers;
    } else {
      developer.log('Token has to be refreshed');
      return headers;
    }
  }

  bool checkTokenValidity() {
    Map<String, dynamic> payload = Jwt.parseJwt(token);
    if(payload.containsKey('exp') && (payload['exp'] * 1000 > DateTime.now().add(Duration(days: 1)).millisecondsSinceEpoch)) {
        return true;
      } else {
        return false;
      }
    }

  Future<void> refreshToken(context) async {
    final password = await _showPasswordDialog(context);
    final email = loggedInUser?.email;
    if (password != null && email != null) {
      this.login(email, password);
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    TextEditingController _textFieldController = new TextEditingController();
    String? userInput = null;
    await showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: Text('Passwort eingeben'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Accout muss neu validiert werden. Bitte Passwort erneut eingeben."),
                  SizedBox(height: 10),
                  TextField(
                    onChanged: (value) {
                      userInput = value;
                    },
                    controller: _textFieldController,
                    decoration: InputDecoration(hintText: "Passwort"),
                    obscureText: true,
                  )
                ],
              ),
            actions: <Widget>[
              OutlinedButton(
                child: Text('Abbrechen'),
                onPressed: () {
                  userInput = null;
                  Navigator.pop(context);
                  return;
                },
              ),
              ElevatedButton(
                child: Text('Bestätigen'),
                onPressed: () {
                    Navigator.pop(context);
                    return;
                },
              ),
            ],
          );
        });
    return userInput;
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
