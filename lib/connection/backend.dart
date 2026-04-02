import 'dart:convert';
import 'dart:io';

import 'dart:developer' as developer;
import 'package:dpsg_app/connection/storage_interface.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:dpsg_app/shared/custom_dialogs.dart';
import 'package:flutter/foundation.dart';
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
  StorageInterface? localStorage;
  String apiurl = newApiUrl;
  static bool refreshingToken = false;
  bool isTokenValid = true;
  String? newestAppVersion;
  String? minAppVersion;
  bool versionIncompatible = false;
  bool updateAvailable = false;
  bool get isOnlineMode =>
      isInitialized && isOnline && isLoggedIn && isTokenValid;

  // Debug method to check online mode status
  String getOnlineModeDebugInfo() {
    return 'isOnlineMode: $isOnlineMode, '
        'isInitialized: $isInitialized, '
        'isOnline: $isOnline, '
        'isLoggedIn: $isLoggedIn, '
        'isTokenValid: $isTokenValid, '
        'token: ${token != null ? "present" : "null"}';
  }

  Future<void> init() async {
    localStorage = GetIt.I<StorageInterface>();
    await setApiUrl();

    // For web, don't check connection immediately - let session determine status
    if (!kIsWeb) {
      await checkConnection();
    } else {
      // On web, assume online if we have a session
      final userId = await localStorage!.getLoggedInUserId();
      if (userId != null && userId.isNotEmpty) {
        isOnline = true;
      } else {
        isOnline = false;
      }
    }

    versionIncompatible = !checkMinVersion();
    updateAvailable = checkNewVersion();

    try {
      loggedInUserId = await localStorage!.getLoggedInUserId();
      isLoggedIn = loggedInUserId != null;
      if (isLoggedIn) {
        Map<String, dynamic>? loginInformation = await localStorage!
            .getLoginInformation();
        if (loginInformation != null) {
          // Properly deserialize the user from JSON
          if (loginInformation['user'] is Map<String, dynamic>) {
            loggedInUser = User.fromJson(loginInformation['user']);
          }
          token = loginInformation['token'];
          isInitialized = true;
          if (kIsWeb) {
            // On web, assume token is valid initially and validate in background
            isTokenValid = token != null && token!.isNotEmpty;
            if (isTokenValid) {
              // Validate token asynchronously without blocking
              checkTokenValidity().then((isValid) {
                if (!isValid) {
                  autoRefreshToken().then((refreshed) {
                    isTokenValid = refreshed;
                  });
                }
              });
            }
          } else {
            // Mobile: strict token validation
            isTokenValid = await checkTokenValidity();
            if (!isTokenValid) isTokenValid = await autoRefreshToken();
          }

          headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          };
          await refreshData();
        }
      }
    } catch (e) {
      developer.log('User not logged in. Error: $e');
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
    developer.log('API-Url set to: $apiurl');
  }

  Future<dynamic> get(String uri) async {
    try {
      final response = await http
          .get(Uri.parse('$apiurl/api$uri'), headers: await getHeader())
          .timeout(const Duration(seconds: timeoutDuration));
      developer.log('${response.statusCode}  GET  $uri');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        developer.log('401 Unauthorized - attempting token refresh');
        bool refreshed = await autoRefreshToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http
              .get(Uri.parse('$apiurl/api$uri'), headers: await getHeader())
              .timeout(const Duration(seconds: timeoutDuration));
          developer.log('${retryResponse.statusCode}  GET  $uri (retry)');
          if (retryResponse.statusCode == 200) {
            return jsonDecode(retryResponse.body);
          }
        }
        throw Exception('HTTP ${response.statusCode} - Token refresh failed');
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
      developer.log('${response.statusCode}  POST  $uri  $body');
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
      developer.log('${response.statusCode}  PATCH  $uri  $body');
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
      developer.log('${response.statusCode}  PUT  $uri  $body');
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
      developer.log('${response.statusCode}  DELETE  $uri  ${body ?? ''}');
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
        final response = await http
            .post(
              Uri.parse('$apiurl/auth/login'),
              headers: kIsWeb
                  ? <String, String>{
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                      'Access-Control-Allow-Origin': '*',
                    }
                  : <String, String>{'Content-Type': 'application/json'},
              body: jsonEncode(<String, String>{
                'email': email,
                'password': password,
              }),
            )
            .timeout(const Duration(seconds: 10));
        developer.log('Login response status: ${response.statusCode}');
        developer.log('Login response body: ${response.body}');
        if (response.statusCode == 200) {
          //await loginFile?.writeAsString(response.body);
          loggedInUser = User.fromJson(json.decode(response.body)['user']);
          token = json.decode(response.body)['token'];
          if (loggedInUser != null && token != null) {
            loggedInUserId = loggedInUser!.id;
            await localStorage!.setLoggedInUserId(loggedInUser!.id);
            await localStorage!.setLoginInformation({
              'user': loggedInUser!.toJson(),
              'token': token,
            });
            await handleOfflinePurchasesAfterLogin(loggedInUser!.id);
            if (response.headers.containsKey("set-cookie")) {
              final cookie = response.headers["set-cookie"]!
                  .split(";")
                  .firstWhere(
                    (element) => element.contains("jwt="),
                    orElse: () => "",
                  );
              final refreshToken = cookie != "" ? cookie.split("=")[1] : null;
              if (refreshToken != null) {
                await localStorage!.setSettingByKey(
                  "refreshToken",
                  refreshToken,
                );
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
        developer.log('Login error: ${e.toString()}');
        return false;
      }
    }
  }

  Future<bool> register(String email, String password, String name) async {
    if (!isInitialized) {
      return false;
    } else {
      final response = await http.post(
        Uri.parse('$apiurl/auth/register'),
        headers: kIsWeb
            ? <String, String>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Access-Control-Allow-Origin': '*',
              }
            : <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
          'name': name,
        }),
      );
      developer.log(response.statusCode.toString());
      developer.log(response.body);
      if (response.statusCode == 201) {
        return await login(email, password);
      } else {
        return false;
      }
    }
  }

  Future<void> logout() async {
    loginInformation = null;
    loggedInUser = null;
    isLoggedIn = false;
    await localStorage!.clearLoginData();
  }

  Future<void> handleOfflinePurchasesAfterLogin(String userId) async {
    List<Purchase> unsent = await localStorage!.getUnsentPurchases();
    if (unsent.isNotEmpty && unsent.first.userBookedId != userId) {
      developer.log('New user logged in. Removing unsent purchases');
      localStorage!.clearUnsentPurchases();
    } else if (unsent.isNotEmpty) {
      await sendLocalPurchasesToServer();
    }
  }

  Future<bool> refreshData() async {
    if (!isOnlineMode) {
      return false;
    } else {
      try {
        await fetchDrinks();
        await fetchFriends();
        loggedInUser = await fetchUser();
        return true;
      } catch (e) {
        developer.log('refreshData error: $e');
        return false;
      }
    }
  }

  Future<bool> checkConnection() async {
    try {
      Map<String, String> headers = {'App-Version': appVersion};
      final userId = await localStorage!.getLoggedInUserId();
      if (userId != null) {
        headers['User-Id'] = userId;
      }

      final response = await http
          .get(Uri.parse('$apiurl/api/version'), headers: headers)
          .timeout(const Duration(seconds: kIsWeb ? 3 : 1));
      developer.log(
        'Checked Connection to API at $apiurl. Status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        isOnline = true;
        if (isLoggedIn) isTokenValid = await checkTokenValidity();
        minAppVersion = json.decode(response.body)['minAppVersion'];
        newestAppVersion = json.decode(response.body)['newestAppVersion'];
        developer.log(
          'Current App Version: $appVersion, Min App Version: $minAppVersion, Newest App Version: $newestAppVersion',
        );
        return isOnlineMode;
      } else {
        developer.log(
          'No Connection to API at $apiurl. Code: ${response.statusCode}',
        );
        isOnline = false;
        return false;
      }
    } catch (error) {
      developer.log('No Connection to API at $apiurl. Status: $error');
      // On web, don't immediately set offline - might be temporary network issue
      if (kIsWeb) {
        // For web, try to maintain online status if we have a valid session
        final userId = await localStorage!.getLoggedInUserId();
        final hasSession = userId != null && userId.isNotEmpty;
        isOnline = hasSession; // Keep online if we have session
        developer.log(
          'Web connection check failed, but session exists: $hasSession',
        );
      } else {
        isOnline = false;
      }
      return false;
    }
  }

  /// Checks if a newer version of the app is available.
  /// Returns true if the current app version is older than the newest available version.
  bool checkNewVersion() {
    if (newestAppVersion == null) {
      checkConnection();
      if (newestAppVersion == null) {
        return false; // No version information available
      }
    }
    final currentVersion = appVersion.split('.').map(int.parse).toList();
    final newestVersion = newestAppVersion!.split('.').map(int.parse).toList();

    if (currentVersion.length != 3 || newestVersion.length != 3) {
      developer.log('Invalid version format: $appVersion or $newestAppVersion');
      return false; // Invalid version format
    }

    for (int i = 0; i < 3; i++) {
      if (currentVersion[i] < newestVersion[i]) {
        developer.log(
          'Newer version available: $newestAppVersion (current: $appVersion)',
        );
        return true; // Newer version available
      } else if (currentVersion[i] > newestVersion[i]) {
        return false; // Current version is newer or equal
      }
    }
    return false; // Versions are equal
  }

  /// Checks if the current app version is at least the minimum required version.
  /// Returns true if the current version is equal to or greater than the minimum version.
  bool checkMinVersion() {
    if (minAppVersion == null) {
      checkConnection();
      if (minAppVersion == null) {
        return true; // No minimum version information available
      }
    }
    final currentVersion = appVersion.split('.').map(int.parse).toList();
    final minVersion = minAppVersion!.split('.').map(int.parse).toList();

    if (currentVersion.length != 3 || minVersion.length != 3) {
      developer.log('Invalid version format: $appVersion or $minAppVersion');
      return false; // Invalid version format
    }

    for (int i = 0; i < 3; i++) {
      if (currentVersion[i] < minVersion[i]) {
        developer.log(
          'Current version $appVersion is below minimum required version $minAppVersion',
        );
        return false; // Current version is below minimum
      } else if (currentVersion[i] > minVersion[i]) {
        return true; // Current version is above minimum
      }
    }
    return true; // Versions are equal
  }

  Future<bool> sendLocalPurchasesToServer() async {
    bool purchasesSent = false;
    if (isOnline) {
      List<Purchase> unsentPurchases = await GetIt.instance<StorageInterface>()
          .getUnsentPurchases();
      for (var element in unsentPurchases.where(
        (element) => element.amount > 0,
      )) {
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
          await GetIt.instance<StorageInterface>().removeUnsentPurchase(
            element.id,
          );
          await Future.delayed(const Duration(milliseconds: 500));
          developer.log('Successfully sent offline purchase to server');
        } catch (error) {
          developer.log(
            'Error while sending offline purchase to server: $error',
          );
          if (error.toString() == 'Exception: HTTP 403') {
            developer.log(
              'HTTP 403 Forbidden error while sending offline purchase. Deleting the purchase now.',
            );
            developer.log('Purchase to be deleted: ${element.toJson()}');
            await GetIt.instance<StorageInterface>().removeUnsentPurchase(
              element.id,
            );
          }
        }
      }
      if (unsentPurchases.isEmpty) purchasesSent = true;
    }
    return purchasesSent;
  }

  Future<Map<String, String>> getHeader() async {
    // Don't check token validity on every header request for web
    if (!kIsWeb) {
      isTokenValid = await checkTokenValidity();
    }
    headers = {
      'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    return headers;
  }

  Future<bool> checkTokenValidity() async {
    if (token == null || token!.isEmpty) {
      developer.log('Token is null or empty');
      return false;
    }

    try {
      Map<String, dynamic> payload = Jwt.parseJwt(token!);
      if (payload.containsKey('exp') &&
          (payload['exp'] * 1000 >
              DateTime.now()
                  .add(const Duration(seconds: tokenLifetimeBeforeRefreshInS))
                  .millisecondsSinceEpoch)) {
        return Future(() => true);
      } else {
        developer.log('Token has to be refreshed. Attemting now ...');
        bool isRefreshed = await autoRefreshToken();
        if (isRefreshed) {
          developer.log('Token has successfuly been refreshed!');
        } else {
          developer.log('Token could not be refreshed.');
        }
        return isRefreshed;
      }
    } catch (e) {
      developer.log('Error checking token validity: $e');
      return false;
    }
  }

  Future<bool> autoRefreshToken() async {
    if (refreshingToken) {
      return Future.value(false);
    }
    refreshingToken = true;
    final refreshToken = await localStorage!.getSettingByKey("refreshToken");
    if (refreshToken != null &&
        Jwt.parseJwt(refreshToken).containsKey('exp') &&
        Jwt.parseJwt(refreshToken)['exp'] * 1000 >
            DateTime.now().millisecondsSinceEpoch &&
        loggedInUser != null) {
      try {
        final response = await http.post(
          Uri.parse('$apiurl/auth/refresh'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Cookie': 'jwt=$refreshToken',
          },
          body: jsonEncode(<String, String>{'email': loggedInUser!.email}),
        );
        developer.log('${response.statusCode}  /auth/refresh');
        if (response.statusCode == 200) {
          token = json.decode(response.body)['token'];
          if (loggedInUser != null && token != null) {
            if (response.headers.containsKey("set-cookie")) {
              final cookie = response.headers["set-cookie"]!
                  .split(";")
                  .firstWhere(
                    (element) => element.contains("jwt="),
                    orElse: () => "",
                  );
              final refreshToken = cookie != "" ? cookie.split("=")[1] : null;
              if (refreshToken != null) {
                await localStorage!.setSettingByKey(
                  "refreshToken",
                  refreshToken,
                );
                developer.log('RefreshToken has been refreshed');
              }
            }
            await localStorage!.setSettingByKey("token", token!);
            developer.log('AccessToken has been refreshed');
            refreshingToken = false;
            return Future.value(true);
          }
        }
      } catch (e) {
        developer.log(e.toString());
      }
    }
    refreshingToken = false;
    return Future.value(false);
  }

  Future<void> refreshToken() async {
    final email = loggedInUser?.email;
    if (email != null) await _showDialog(email);
    refreshingToken = false;
  }

  Future<String?> _showDialog(String email) async {
    TextEditingController textFieldController = TextEditingController();
    String? userInput;
    bool isRefreshingToken = false;
    String? errorText;
    await showDialog(
      barrierDismissible: true,
      context: navigatorKey.currentContext!,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return customAlertDialog(
              title: const Text('Passwort eingeben'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Account muss neu validiert werden. Bitte Passwort erneut eingeben.",
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: textFieldController,
                    decoration: InputDecoration(
                      hintText: "Passwort",
                      errorText: errorText,
                    ),
                    obscureText: true,
                    onChanged: (text) {
                      setState(() {
                        errorText = null;
                      });
                    },
                  ),
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
                            color: Colors.blue.shade800,
                          ),
                        )
                      : const Text('Bestätigen'),
                  onPressed: () async {
                    if (textFieldController.text.isNotEmpty &&
                        !isRefreshingToken) {
                      setState(() {
                        isRefreshingToken = true;
                      });
                      if (await login(email, textFieldController.text)) {
                        setState(() {
                          isRefreshingToken = false;
                        });
                        if (context.mounted) Navigator.pop(context);
                        return;
                      } else {
                        setState(() {
                          isRefreshingToken = false;
                          errorText = 'Passwort falsch!';
                        });
                      }
                    } else {
                      if (!isRefreshingToken) {
                        setState(() {
                          errorText = 'Passwort falsch!';
                        });
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
