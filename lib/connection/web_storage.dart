import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dpsg_app/connection/storage_interface.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart' show ColorScheme;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' if (dart.library.io) 'web_stub.dart' as web;

class WebStorage implements StorageInterface {
  @override
  bool isInitialized = false;
  final StreamController<Map<String, String>> _settingsStreamController =
      StreamController<Map<String, String>>.broadcast();

  // Helper methods for JSON encoding/decoding
  Map<String, dynamic> _decodeJson(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  String _encodeJson(Map<String, dynamic> data) {
    return json.encode(data);
  }

  @override
  Stream<Map<String, String>> get settingsStream =>
      _settingsStreamController.stream;

  @override
  Future<bool> init() async {
    isInitialized = true;
    return true;
  }

  // Session-based authentication using sessionStorage (web only)
  @override
  Future<String?> getLoggedInUserId() async {
    if (kIsWeb) {
      return web.window.sessionStorage.getItem('loggedInUserId')?.toString();
    } else {
      return null;
    }
  }

  @override
  Future<void> setLoggedInUserId(String userId) async {
    if (kIsWeb) {
      web.window.sessionStorage.setItem('loggedInUserId', userId);
    }
  }

  @override
  Future<Map<String, dynamic>?> getLoginInformation() async {
    if (kIsWeb) {
      final loginInfoJson = web.window.sessionStorage
          .getItem('loginInformation')
          ?.toString();
      if (loginInfoJson != null) {
        try {
          // Use dart:convert to decode JSON
          final loginInfoMap = _decodeJson(loginInfoJson);
          return loginInfoMap;
        } catch (e) {
          return null;
        }
      }
      return null;
    }
    return null;
  }

  @override
  Future<void> setLoginInformation(Map<String, dynamic> loginInfo) async {
    if (kIsWeb) {
      try {
        // Use dart:convert to encode JSON
        final loginInfoJson = _encodeJson(loginInfo);
        web.window.sessionStorage.setItem('loginInformation', loginInfoJson);
      } catch (e) {
        developer.log('Error storing login information: $e');
      }
    }
  }

  @override
  Future<void> clearLoginData() async {
    if (kIsWeb) {
      web.window.sessionStorage.removeItem('loggedInUserId');
      web.window.sessionStorage.removeItem('loginInformation');
    }
  }

  // Settings - Web uses sessionStorage for persistence
  @override
  Future<String?> getSettingByKey(String key) async {
    // Return hardcoded defaults
    switch (key) {
      case 'colorScheme':
        return kColorSchemes.first.name;
      case 'shortcutDrink':
        return null;
      default:
        return null;
    }
  }

  @override
  Future<void> setSettingByKey(String key, String value) async {
    // Web doesn't persist settings, just emit to stream if needed
    _settingsStreamController.add({key: value});
  }

  @override
  Future<void> removeSettingByKey(String key) async {
    // Web doesn't persist settings, just emit to stream if needed
    _settingsStreamController.add({key: ''});
  }

  @override
  Future<ColorScheme> getColorScheme() async {
    // Return default color scheme
    return kColorSchemes.first.colorScheme;
  }

  // Local data methods - Web doesn't support these
  @override
  Future<List<Drink>> getLocalDrinks() async {
    return [];
  }

  @override
  Future<void> saveLocalDrinks(List<Drink> drinks) async {
    // Web doesn't store local drinks
  }

  @override
  Future<Purchase?> getLastPurchase() async {
    return null;
  }

  @override
  Future<void> setLastPurchase(Purchase purchase) async {
    // Web doesn't store last purchase
  }

  @override
  Future<List<Purchase>> getUnsentPurchases() async {
    return [];
  }

  @override
  Future<void> addUnsentPurchase(Purchase purchase) async {
    // Web doesn't support unsent purchases
  }

  @override
  Future<void> removeUnsentPurchase(int id) async {
    // Web doesn't support unsent purchases
  }

  @override
  Future<void> clearUnsentPurchases() async {
    // Web doesn't support unsent purchases
  }

  @override
  Future<List<Friend>> getFriends() async {
    return [];
  }

  @override
  Future<void> saveFriends(List<Friend> friends) async {
    // Web doesn't store local friends
  }

  @override
  void dispose() {
    _settingsStreamController.close();
  }
}
