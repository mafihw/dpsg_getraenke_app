import 'dart:convert';
import 'dart:io';

import 'dart:developer' as developer;
import 'package:dpsg_app/connection/database.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import '../model/purchase.dart';
import '../main.dart';

const bool usingLocalAPI = false;
const int tokenLifetimeBeforeRefreshInS = 15 * 60;

const oldApiUrl = 'https://api.dpsg-gladbach.de:3001';
const newApiUrl = 'https://app.dpsg-gladbach.de:443';
const localApiUrl = 'http://192.168.178.39:3000';

class Backend {
  static const int timeoutDuration = 30;
  bool isLoggedIn = false;
  bool isInitialized = false;
  bool isOnline = false;
  Directory? directory;
  String? path;
  dynamic loginInformation;
  String? loggedInUserId;
  User? loggedInUser;
  String? token;
  File? loginFile;
  late Map<String, String> headers;
  LocalDB? localStorage;
  String apiurl = newApiUrl;
  static bool refreshingToken = false;

  Future<void> init() async {
    await setApiUrl();
    await checkConnection();
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

  Future<void> setApiUrl() async {
    if (usingLocalAPI) {
      apiurl = localApiUrl;
    } /* else {
      try {
        final response = await http
            .get(Uri.parse('$apiurl/api/test'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) {
          apiurl = newApiUrl;
        }
      } catch (e) {
        apiurl = newApiUrl;
      }
    }*/
    developer.log('API-Url set to: ' + apiurl);
  }

  Future<dynamic> get(String uri) async {
    try {
      final response = await http
          .get(Uri.parse('$apiurl/api$uri'), headers: await getHeader())
          .timeout(const Duration(seconds: timeoutDuration));
      developer.log(response.statusCode.toString() + '  GET  ' + uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      await checkConnection();
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<dynamic> post(String uri, String body) async {
    try {
      final url = Uri.parse('$apiurl/api$uri');
      final response = await http
          .post(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: timeoutDuration));
      developer
          .log(response.statusCode.toString() + '  POST  ' + uri + '  ' + body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      await checkConnection();
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<dynamic> patch(String uri, String body) async {
    try {
      final url = Uri.parse('$apiurl/api$uri');
      final response = await http
          .patch(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: timeoutDuration));
      developer.log(
          response.statusCode.toString() + '  PATCH  ' + uri + '  ' + body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      await checkConnection();
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<dynamic> put(String uri, String body) async {
    try {
      final url = Uri.parse('$apiurl/api$uri');
      final response = await http
          .put(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: timeoutDuration));
      developer
          .log(response.statusCode.toString() + '  PUT  ' + uri + '  ' + body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      await checkConnection();
      developer.log(e.toString());
      rethrow;
    }
  }

  Future<dynamic> delete(String uri, String? body) async {
    try {
      final url = Uri.parse('$apiurl/api$uri');
      final response = await http
          .delete(url, headers: await getHeader(), body: body)
          .timeout(const Duration(seconds: timeoutDuration));
      developer.log(response.statusCode.toString() +
          '  DELETE  ' +
          uri +
          '  ' +
          (body ?? ''));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      await checkConnection();
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
            if (response.headers.containsKey("set-cookie")) {
              final cookie = response.headers["set-cookie"]!
                  .split(";")
                  .firstWhere((element) => element.contains("jwt="),
                      orElse: () => "");
              final refreshToken = cookie != "" ? cookie.split("=")[1] : null;
              if (refreshToken != null) {
                await localStorage!
                    .setSettingByKey("refreshToken", refreshToken);
              }
            }
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
    if (!isOnline || !isInitialized || !isLoggedIn) {
      return false;
    } else {
      try {
        await fetchDrinks();
        await fetchFriends();
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
      final response = await http
          .get(Uri.parse('$apiurl/api/test'))
          .timeout(const Duration(seconds: 5));
      developer.log(
          'Checking Connection to API at $apiurl. Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        isOnline = true;
        return true;
      } else {
        developer.log(
            'No Connection to API at $apiurl. Code: ${response.statusCode}');
        isOnline = false;
        return false;
      }
    } catch (error) {
      developer.log('No Connection to API at $apiurl. Status: $error');
      isOnline = false;
      return false;
    }
  }

  Future<bool> sendLocalPurchasesToServer() async {
    bool purchasesSent = false;
    if (isOnline) {
      List<Purchase> unsentPurchases =
          await GetIt.instance<LocalDB>().getUnsentPurchases();
      for (var element in unsentPurchases) {
        final body = {
          "uuid": element.userId,
          "userBookedId": element.userBookedId,
          "drinkid": element.drinkId,
          "amount": element.amount,
          "date": element.date.toString(),
        };
        developer.log('Sending offline purchase to server');
        try {
          await post('/purchase', jsonEncode(body));
          purchasesSent = true;
          await GetIt.instance<LocalDB>().removeUnsentPurchase(element);
          await Future.delayed(const Duration(milliseconds: 500));
          developer.log('Successfully sent offline purchase to server');
        } catch (error) {
          developer.log('Error while sending offline purchase to server: ' +
              error.toString());
          if (error.toString() == 'Exception: HTTP 403') {
            developer.log(
                'HTTP 403 Forbidden error while sending offline purchase. Deleting the purchase now.');
            developer.log('Purchase to be deleted: ${element.toJson()}');
            await GetIt.instance<LocalDB>().removeUnsentPurchase(element);
          }
        }
      }
      if (unsentPurchases.isEmpty) purchasesSent = true;
    }
    return purchasesSent;
  }

  Future<Map<String, String>> getHeader() async {
    if (await checkTokenValidity()) {
      return headers;
    } else {
      developer.log('Token has to be refreshed');
      return headers;
    }
  }

  Future<bool> checkTokenValidity() async {
    Map<String, dynamic> payload = Jwt.parseJwt(token!);
    if (payload.containsKey('exp') &&
        (payload['exp'] * 1000 >
            DateTime.now()
                .add(const Duration(seconds: tokenLifetimeBeforeRefreshInS))
                .millisecondsSinceEpoch)) {
      return Future(() => true);
    } else {
      if (payload.containsKey('exp') &&
          (payload['exp'] * 1000 >
              DateTime.now()
                  .add(const Duration(seconds: 30))
                  .millisecondsSinceEpoch)) {
        autoRefreshToken();
        return Future(() => true);
      } else {
        return Future(() async => await autoRefreshToken());
      }
    }
  }

  Future<bool> autoRefreshToken() async {
    if (refreshingToken) {
      return Future(() => false);
    }
    refreshingToken = true;
    final refreshToken = await localStorage!.getSettingByKey("refreshToken");
    if (refreshToken != null &&
        Jwt.parseJwt(refreshToken).containsKey('exp') &&
        Jwt.parseJwt(refreshToken)['exp'] * 1000 >
            DateTime.now().millisecondsSinceEpoch &&
        loggedInUser != null) {
      try {
        final response = await http.post(Uri.parse('$apiurl/auth/refresh'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Cookie': 'jwt=$refreshToken'
            },
            body: jsonEncode(<String, String>{'email': loggedInUser!.email}));
        developer.log(response.statusCode.toString() + '  /auth/refresh');
        if (response.statusCode == 200) {
          token = json.decode(response.body)['token'];
          if (loggedInUser != null && token != null) {
            if (response.headers.containsKey("set-cookie")) {
              final cookie = response.headers["set-cookie"]!
                  .split(";")
                  .firstWhere((element) => element.contains("jwt="),
                      orElse: () => "");
              final refreshToken = cookie != "" ? cookie.split("=")[1] : null;
              if (refreshToken != null) {
                await localStorage!
                    .setSettingByKey("refreshToken", refreshToken);
                developer.log('RefreshToken has been refreshed');
              }
            }
            await localStorage!.setSettingByKey("token", token!);
            developer.log('AccessToken has been refreshed');
            refreshingToken = false;
            return Future(() => true);
          } else {
            refreshingToken = false;
            return Future(() => true);
          }
        } else {
          if (response.statusCode == 409) {
            await this.refreshToken();
            refreshingToken = false;
            return Future(() => true);
          } else {
            refreshingToken = false;
            return Future(() => true);
          }
        }
      } catch (e) {
        developer.log(e.toString());
        refreshingToken = false;
        return Future(() => true);
      }
    } else {
      await this.refreshToken();
      refreshingToken = false;
      return Future(() => true);
    }
  }

  Future<void> refreshToken() async {
    final email = loggedInUser?.email;
    if (email != null) await _showDialog(email);
    refreshingToken = false;
  }

  Future<String?> _showDialog(String email) async {
    TextEditingController _textFieldController = TextEditingController();
    String? userInput;
    bool isRefreshingToken = false;
    String? _errorText;
    await showDialog(
        barrierDismissible: false,
        context: navigatorKey.currentContext!,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return CustomAlertDialog(
              title: const Text('Passwort eingeben'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Account muss neu validiert werden. Bitte Passwort erneut eingeben."),
                  const SizedBox(height: 10),
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
                      : const Text('Bestätigen'),
                  onPressed: () async {
                    if (_textFieldController.text.isNotEmpty &&
                        !isRefreshingToken) {
                      setState(() {
                        isRefreshingToken = true;
                      });
                      if (await login(email, _textFieldController.text)) {
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
