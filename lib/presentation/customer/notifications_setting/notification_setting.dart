import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spreadlee/core/constant.dart';

import '../../resources/routes_manager.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool? chatNotification = true;
  bool? requestNotification = true;

  @override
  void initState() {
    super.initState();
    // Retrieve and store user ID securely
    _secureStorage.read(key: "role").then((value) {
      Constants.role = value ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    // final userIsCustomer = false; // Replace with your condition

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notification Settings",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, Routes.customerHomeRoute),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            SwitchListTile.adaptive(
              value: chatNotification ?? true,
              onChanged: (newValue) async {
                // if (newValue == true) {
                //   final granted =
                //       await OneSignal.Notifications.requestPermission(true);
                //   if (!granted) return;
                // }
                // setState(() => chatNotification = newValue);

                // // Replace this with your update method
                // print("Chat Notifications: $newValue");
              },
              title: const Text(
                "Chat Notifications",
                style: TextStyle(fontSize: 16),
              ),
              activeColor: Colors.blue,
              activeTrackColor: Colors.lightBlue,
              tileColor: Colors.grey[100],
              controlAffinity: ListTileControlAffinity.trailing,
              dense: true,
            ),
            if (Constants.role == "customer")
              SwitchListTile.adaptive(
                value: requestNotification ?? true,
                onChanged: (newValue) async {
                  // if (newValue == true) {
                  //   final granted =
                  //       await OneSignal.Notifications.requestPermission(true);
                  //   if (!granted) return;
                  // }
                  // setState(() => requestNotification = newValue);

                  // // Replace this with your update method
                  // print("Client Request Notifications: $newValue");
                },
                title: const Text(
                  "Client Request Notifications",
                  style: TextStyle(fontSize: 16),
                ),
                activeColor: Colors.blue,
                activeTrackColor: Colors.lightBlue,
                tileColor: Colors.grey[100],
                controlAffinity: ListTileControlAffinity.trailing,
                dense: true,
              ),
          ],
        ),
      ),
    );
  }
}
