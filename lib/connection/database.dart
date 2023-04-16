import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/model/drink.dart';
import 'package:dpsg_app/model/friend.dart';
import 'package:dpsg_app/model/purchase.dart';
import 'package:dpsg_app/model/user.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDB {
  bool isInitialized = false;
  Database? database;
  String? get _loggedInUserId {
    return GetIt.I<Backend>().loggedInUserId;
  }

  Future<bool> init() async {
    try {
      // open or create the database file
      database = await openDatabase(
          join(await getDatabasesPath(), 'dpsg-database.db'),
          version: 2,
          onCreate: (db, _) async => await _createTables(db),
          onUpgrade: ((db, oldVersion, newVersion) async =>
              await _handleUpdate(db, oldVersion, newVersion)));
      isInitialized = true;
      return true;
    } catch (e) {
      isInitialized = false;
      return false;
    }
  }

  Future<void> _createTables(Database db) async {
    developer.log('Creating local Database');
    List<String> createStatements = [
      'CREATE TABLE drinks(id INTEGER PRIMARY KEY, cost INTEGER, name STRING, active INTEGER, deleted INTEGER)',
      'CREATE TABLE unsentPurchases(id INTEGER PRIMARY KEY AUTOINCREMENT, drinkId INTEGER, userId STRING, userBookedId STRING, amount INTEGER, cost INTEGER, date STRING, drinkName STRING, userName STRING, userBookedName STRING)',
      'CREATE TABLE settings(userId STRING, key STRING, value, STRING, PRIMARY KEY (userId, key))',
      'CREATE TABLE friends(uuid STRING PRIMARY KEY, userName STRING)',
    ];

    for (String createStatement in createStatements) {
      await db.execute(createStatement);
    }
  }

  Future<void> _handleUpdate(
      Database db, int oldVersion, int newVersion) async {
    developer.log('Updating local database');
    if (newVersion > 1) {
      await db.execute(
          'CREATE TABLE IF NOT EXISTS friends(uuid STRING PRIMARY KEY, userName STRING)');
      await db.execute(
          "ALTER TABLE unsentPurchases ADD COLUMN userBookedId STRING");
      await db.execute(
          "ALTER TABLE unsentPurchases ADD COLUMN userBookedName STRING");
    }
  }

  Future<void> insertDrinks(List<Drink> drinks) async {
    if (isInitialized) {
      await database!.delete('drinks');
      for (Drink drink in drinks) {
        await database!.insert(
          'drinks',
          drink.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<List<Drink>> fetchDrinksFromDB() async {
    if (isInitialized) {
      final List<Map<String, dynamic>> maps = await database!.query('drinks');
      return List.generate(maps.length, (index) {
        return Drink(
          id: maps[index]['id'],
          name: maps[index]['name'],
          cost: maps[index]['cost'],
          active: maps[index]['active'] > 0,
          deleted: maps[index]['deleted'] > 0,
        );
      });
    } else {
      return [];
    }
  }

  Future<void> insertUnsentPurchase(Purchase purchase) async {
    if (isInitialized) {
      var purchaseJson = purchase.toJson();
      purchaseJson.remove('id');
      await database!.insert(
        'unsentPurchases',
        purchaseJson,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> removeUnsentPurchase(Purchase purchase) async {
    if (isInitialized) {
      await database!.delete(
        'unsentPurchases',
        where: "id = ?",
        whereArgs: [purchase.id],
      );
    }
  }

  Future<void> removeAllUnsentPurchases() async {
    if (isInitialized) await database!.delete('unsentPurchases');
  }

  Future<List<Purchase>> getUnsentPurchases() async {
    if (isInitialized) {
      final List<Map<String, dynamic>> maps =
          await database!.query('unsentPurchases');
      return List.generate(maps.length, (index) {
        return Purchase(
          id: maps[index]['id'],
          drinkId: maps[index]['drinkId'],
          userId: maps[index]['userId'],
          userBookedId: maps[index]['userBookedId'] ?? maps[index]['userId'],
          userBookedName: maps[index]['userBookedName'] ?? '',
          amount: maps[index]['amount'],
          cost: maps[index]['cost'],
          date: DateTime.parse(maps[index]['date']),
          drinkName: maps[index]['drinkName'],
          userName: maps[index]['userName'],
        );
      });
    } else {
      return [];
    }
  }

  Future<bool> saveLoginInformation(User user, String? token) async {
    if (isInitialized) {
      List<Map<String, dynamic>> values = [
        {'key': 'userId', 'value': user.id},
        {'key': 'role', 'value': user.role},
        {'key': 'email', 'value': user.email},
        {'key': 'name', 'value': user.name},
        {'key': 'balance', 'value': user.balance},
      ];
      if (user.weight != null) {
        values.add(
          {'key': 'weight', 'value': user.weight},
        );
      }
      if (user.gender != null) {
        values.add(
          {'key': 'gender', 'value': user.gender},
        );
      }
      if (token != null) {
        values.add(
          {'key': 'token', 'value': token},
        );
      }
      Batch batch = database!.batch();
      for (Map<String, dynamic> value in values) {
        value.addAll({'userId': user.id});
        batch.insert(
          'settings',
          value,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      try {
        await batch.commit();
        return true;
      } catch (e) {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLoginInformation() async {
    if (isInitialized) {
      String? loggedInUserId = await getLoggedInUserId();
      if (loggedInUserId != null) {
        List<String> keys = [
          'userId',
          'role',
          'email',
          'name',
          'balance',
          'weight',
          'token',
        ];
        Map<String, dynamic> values = {};
        for (var key in keys) {
          var value = await database!.query('settings',
              columns: ['value'],
              where: 'key = ? AND userId = ?',
              whereArgs: [key, loggedInUserId]);
          if (value.isNotEmpty) {
            values.addAll({key: value.first.values.first});
          }
        }
        User loggedInUser = User(
          id: values['userId'],
          role: values['role'],
          email: values['email'],
          name: values['name'],
          balance: values['balance'],
          weight: values['weight'],
          gender: values['gender'],
        );
        String token = values['token'];
        return {'user': loggedInUser, 'token': token};
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<bool> setLoggedInUserId(String userId) async {
    if (isInitialized) {
      Map<String, dynamic> entry = {
        'key': 'loggedInId',
        'userId': null,
        'value': userId,
      };
      database!.insert('settings', entry,
          conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> removeLoggedInUserId() async {
    if (isInitialized) {
      database!.delete('settings', where: 'key = ?', whereArgs: ['loggedInId']);
      return true;
    } else {
      return false;
    }
  }

  Future<String?> getLoggedInUserId() async {
    var userId = await database!.query('settings',
        columns: ['value'], where: 'key = ?', whereArgs: ['loggedInId']);
    String? loggedInUserId = userId.first.values.first != null
        ? userId.first.values.first.toString()
        : null;
    return loggedInUserId;
  }

  Future<bool> setLastPurchase(Purchase purchase) async {
    if (isInitialized && _loggedInUserId != null) {
      Map<String, dynamic> entry = {
        'userId': _loggedInUserId,
        'key': 'lastPurchase',
        'value': jsonEncode(purchase.toJson()),
      };
      database!.insert('settings', entry,
          conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } else {
      return false;
    }
  }

  Future<Purchase?> getLastPurchase() async {
    if (isInitialized && _loggedInUserId != null) {
      var value = await database!.query('settings',
          columns: ['value'],
          where: 'userId = ? AND key = ?',
          whereArgs: [_loggedInUserId, 'lastPurchase']);
      if (value.isNotEmpty) {
        return Purchase.fromJson(
            jsonDecode(value.first.values.first.toString()));
      }
    }
    return null;
  }

  Future<bool> setSettingByKey(String key, String value) async {
    if (isInitialized && _loggedInUserId != null) {
      Map<String, dynamic> entry = {
        'userId': _loggedInUserId,
        'key': key,
        'value': value,
      };
      database!.insert('settings', entry,
          conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } else {
      return false;
    }
  }

  Future<String?> getSettingByKey(String key) async {
    if (isInitialized && _loggedInUserId != null) {
      var value = await database!.query('settings',
          columns: ['value'],
          where: 'userId = ? AND key = ?',
          whereArgs: [_loggedInUserId, key]);
      if (value.isNotEmpty) {
        return value.first.values.first.toString();
      }
    }
    return null;
  }

  Future<bool> removeSettingByKey(String key) async {
    if (isInitialized && _loggedInUserId != null) {
      return await database!.delete('settings',
              where: 'userId = ? AND key = ?',
              whereArgs: [_loggedInUserId, key]) >
          0;
    }
    return false;
  }

  Future<void> insertFriends(List<Friend> friends) async {
    if (isInitialized) {
      await database!.delete('friends');
      for (Friend friend in friends) {
        await database!.insert(
          'friends',
          friend.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<List<Friend>> fetchFriendsFromDB() async {
    if (isInitialized) {
      final List<Map<String, dynamic>> maps = await database!.query('friends');
      var list = List.generate(maps.length, (index) {
        return Friend.fromMap(maps[index]);
      });
      return list;
    } else {
      return [];
    }
  }
}
