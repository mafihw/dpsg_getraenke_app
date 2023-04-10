import 'dart:convert';
import 'dart:io';

import 'dart:developer' as developer;
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import '../model/purchase.dart';

const bool usingLocalAPI = false;

class Backend {
  String apiurl = usingLocalAPI
      ? 'http://192.168.178.32:3000'
      : 'https://api.dpsg-gladbach.de:3001';
  static const int timeoutDuration = 30;
  bool isLoggedIn = false;
  bool isInitialized = false;
  Directory? directory;
  String? path;
  dynamic loginInformation;
  String? loggedInUserId;
  User? loggedInUser;
  String? token;
  File? loginFile;
  late Map<String, String> headers;
  LocalDB? localStorage;

  Future<void> init() async {
    try {
      localStorage = GetIt.I<LocalDB>();
      loggedInUserId = await localStorage!.getLoggedInUserId();
      isLoggedIn = loggedInUserId != null;
      if (isLoggedIn) {
        Map<String, dynamic>? loginInformation =
            await localStorage!.getLoginInformation();
        if (loginInformation != null) {
          loggedInUser = loginInformation['user'];
          token = loginInformation['token'];
          isInitialized = true;
          headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          };
          await refreshData();
        }
      }
    } catch (e) {
      developer.log('User not logged in.');
    }

    isInitialized = true;
  }

  Future<dynamic> get(String uri) async {
    try {
      final response = await http
          .get(Uri.parse('$apiurl/api$uri'), headers: await getHeader())
          .timeout(const Duration(seconds: timeoutDuration));
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
      developer.log('POST: url:$url body: $body');
      final response = await http
          .post(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: timeoutDuration));
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
          .timeout(const Duration(seconds: timeoutDuration));
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

  Future<dynamic> put(String uri, String body) async {
    try {
      final url = Uri.parse('$apiurl/api$uri');
      developer.log('PUT: url:$url');
      final response = await http
          .put(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: timeoutDuration));
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
          .timeout(const Duration(seconds: timeoutDuration));
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
      try {
        final response = await http.post(Uri.parse('$apiurl/auth/login'),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(
                <String, String>{'email': email, 'password': password}));
        developer.log(response.statusCode.toString());
        developer.log(response.body);
        if (response.statusCode == 200) {
          //await loginFile?.writeAsString(response.body);
          loggedInUser = User.fromJson(json.decode(response.body)['user']);
          token = json.decode(response.body)['token'];
          if (loggedInUser != null && token != null) {
            loggedInUserId = loggedInUser!.id;
            await localStorage!.setLoggedInUserId(loggedInUser!.id);
            await localStorage!.saveLoginInformation(loggedInUser!, token);
            await init();
            return true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } catch (e) {
        developer.log(e.toString());
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
    /*directory!.list().forEach((element) async {
      await element.delete(recursive: true);
    });*/
    localStorage!.removeLoggedInUserId();
    localStorage!.removeAllUnsentPurchases();
    loginInformation = null;
    loggedInUser = null;
    isLoggedIn = false;
  }

  Future<bool> refreshData() async {
    if (!await checkConnection() || !isInitialized || !isLoggedIn) {
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

  Future<bool> sendLocalPurchasesToServer() async {
    bool purchasesSent = false;
    if (await checkConnection()) {
      List<Purchase> unsentPurchases =
          await GetIt.instance<LocalDB>().getUnsentPurchases();
      for (var element in unsentPurchases) {
        final body = {
          "uuid": element.userId,
          "drinkid": element.drinkId,
          "amount": element.amount,
          "date": element.date.toString(),
        };
        developer.log('Sending purchase to server');
        try {
          await post('/purchase', jsonEncode(body));
          purchasesSent = true;
          await GetIt.instance<LocalDB>().removeUnsentPurchase(element);
          await Future.delayed(const Duration(milliseconds: 500));
          developer.log('Successfully sent purchase to server');
        } catch (error) {
          developer.log(
              'Error while sending purchase to server: ' + error.toString());
        }
      }
      if (unsentPurchases.isEmpty) purchasesSent = true;
    }
    return purchasesSent;
  }

  Future<Map<String, String>> getHeader() async {
    if (checkTokenValidity()) {
      return headers;
    } else {
      developer.log('Token has to be refreshed');
      return headers;
    }
  }

  bool checkTokenValidity() {
    Map<String, dynamic> payload = Jwt.parseJwt(token!);
    if (payload.containsKey('exp') &&
        (payload['exp'] * 1000 >
            DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch)) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> refreshToken(context) async {
    final email = loggedInUser?.email;
    if (email != null) await _showDialog(context, email);
  }

  Future<String?> _showDialog(BuildContext context, String email) async {
    TextEditingController _textFieldController = new TextEditingController();
    String? userInput = null;
    bool isRefreshingToken = false;
    String? _errorText = null;
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return CustomAlertDialog(
              context: context,
              title: Text('Passwort eingeben'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "Account muss neu validiert werden. Bitte Passwort erneut eingeben."),
                  SizedBox(height: 10),
                  TextField(
                    controller: _textFieldController,
                    decoration: InputDecoration(
                        hintText: "Passwort", errorText: _errorText),
                    obscureText: true,
                    onChanged: (_text) {
                      setState(() {
                        _errorText = null;
                      });
                    },
                  )
                ],
              ),
              actions: <Widget>[
                /*
                OutlinedButton(
                  child: Text('Offline nutzen'),
                  onPressed: () {
                    userInput = null;
                    Navigator.pop(context);
                    return;
                  },
                ),
                */
                ElevatedButton(
                  child: isRefreshingToken
                      ? SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                              color: Colors.blue.shade800))
                      : Text('Bestätigen'),
                  onPressed: () async {
                    if (_textFieldController.text.isNotEmpty &&
                        !isRefreshingToken) {
                      setState(() {
                        isRefreshingToken = true;
                      });
                      if (await this.login(email, _textFieldController.text)) {
                        setState(() {
                          isRefreshingToken = false;
                        });
                        Navigator.pop(context);
                        return;
                      } else {
                        setState(() {
                          isRefreshingToken = false;
                          _errorText = 'Passwort falsch!';
                        });
                      }
                    } else {
                      if (!isRefreshingToken) {
                        setState(() {
                          _errorText = 'Passwort falsch!';
                        });
                      }
                    }
                  },
                ),
              ],
            );
          });
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
