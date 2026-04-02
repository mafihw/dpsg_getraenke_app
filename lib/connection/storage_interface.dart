import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:flutter/material.dart' show ColorScheme;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';

abstract class StorageInterface {
  bool get isInitialized;

  Future<bool> init();

  // User authentication and session data
  Future<String?> getLoggedInUserId();
  Future<void> setLoggedInUserId(String userId);
  Future<Map<String, dynamic>?> getLoginInformation();
  Future<void> setLoginInformation(Map<String, dynamic> loginInfo);
  Future<void> clearLoginData();

  // Settings (only used on mobile, web returns defaults)
  Future<String?> getSettingByKey(String key);
  Future<void> setSettingByKey(String key, String value);
  Future<void> removeSettingByKey(String key);
  Future<ColorScheme> getColorScheme();

  // Local data (only used on mobile)
  Future<List<Drink>> getLocalDrinks();
  Future<void> saveLocalDrinks(List<Drink> drinks);
  Future<Purchase?> getLastPurchase();
  Future<void> setLastPurchase(Purchase purchase);
  Future<List<Purchase>> getUnsentPurchases();
  Future<void> addUnsentPurchase(Purchase purchase);
  Future<void> removeUnsentPurchase(int purchaseId);
  Future<void> clearUnsentPurchases();
  Future<List<Friend>> getFriends();
  Future<void> saveFriends(List<Friend> friends);

  // Stream for settings changes (mobile only)
  Stream<Map<String, String>> get settingsStream;

  void dispose();
}

class StorageFactory {
  static StorageInterface createStorage() {
    if (GetIt.instance.isRegistered<StorageInterface>()) {
      return GetIt.instance<StorageInterface>();
    }
    throw Exception(
      'Storage service not registered. Call registerStorage() first.',
    );
  }

  static bool get isWeb => kIsWeb;
}
