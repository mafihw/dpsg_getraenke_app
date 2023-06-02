import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/database.dart';
import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';

class Friend {
  late String uuid;
  late String userName;
  Friend(this.uuid, this.userName);

  factory Friend.fromMap(Map<String, dynamic> friendMap) {
    return Friend(
        friendMap['uuid']! as String, friendMap['userName']! as String);
  }

  factory Friend.fromJson(Map<String, dynamic> data) {
    return Friend(data['uuid'], data['userName']);
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'userName': userName,
    };
  }
}

Future<List<Friend>> fetchFriends() async {
  var database = GetIt.I<LocalDB>();
  List<Friend> friends = [];
  if (GetIt.I<Backend>().isOnline) {
    try {
      final response = await GetIt.I<Backend>().get('/friend');
      if (response != null) {
        for (var friendsJson in response) {
          friends.add(Friend.fromJson(friendsJson));
        }
        await database.insertFriends(friends);
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }

  if (friends.isEmpty) {
    friends = await database.fetchFriendsFromDB();
  }

  return friends;
}
