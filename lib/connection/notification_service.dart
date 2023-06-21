import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:get_it/get_it.dart';

import 'backend.dart';

class NotificationService {
  static final NotificationService _notificationService =
  NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init(Future<dynamic> Function(int, String?, String?, String?)? onDidReceive) async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_monochrome');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      onDidReceiveLocalNotification: onDidReceive,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: null);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: selectNotification);
  }


  Future selectNotification(NotificationResponse? payload) async {
    if(await GetIt.instance<Backend>().sendLocalPurchasesToServer()){
      print("Offline purchases send");
    } else {
      print("Offline purchases not send");
      this.showOfflinePurchasesNotification();
    }
  }

  void showNotification(String title, String message) async {
    String channelDescription = "Channel der Getränkeapp";
    String applicationName = "Getränkeapp";
    const String channel_id = "123";
    await flutterLocalNotificationsPlugin.show(
        1,
        title,
        message,
        NotificationDetails(
            android: AndroidNotificationDetails(
                channel_id,
                applicationName,
                channelDescription: channelDescription,
                enableVibration: false)
        )
    );
  }

  void showOfflinePurchasesNotification(){
    this.showNotification("Offlinebuchung vorhanden", "Bitte App öffnen, wenn Internetverbindung besteht");
  }
}