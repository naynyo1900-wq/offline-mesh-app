import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(home: OfflineChatApp()));
}

class OfflineChatApp extends StatefulWidget {
  const OfflineChatApp({super.key});
  @override
  State<OfflineChatApp> createState() => _OfflineChatAppState();
}

class _OfflineChatAppState extends State<OfflineChatApp> {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String userName = "Tecno_User";
  List<String> messages = [];
  TextEditingController msgController = TextEditingController();
  String? connectedEndpointId;
  int connectedDevicesCount = 0;

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  void checkPermissions() async {
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
    startP2P();
  }

  void startP2P() async {
    await Nearby().startAdvertising(
      userName,
      strategy,
      onConnectionInitiated: (id, info) => onInit(id, info),
      onConnectionResult: (id, status) => onResult(id, status),
      onDisconnected: (id) => onDisconnect(id),
    );

    await Nearby().startDiscovery(
      userName,
      strategy,
      onEndpointFound: (id, name, serviceId) {
        Nearby().requestConnection(
          userName,
          id,
          onConnectionInitiated: (id, info) => onInit(id, info),
          onConnectionResult: (id, status) => onResult(id, status),
          onDisconnected: (id) => onDisconnect(id),
        );
      },
      onEndpointLost: (id) {},
    );
  }

  void onInit(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes!);
          setState(() => messages.add("အခြားဖုန်း: $str"));
        }
      },
    );
  }

  void onResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      setState(() {
        connectedEndpointId = id;
        connectedDevicesCount++;
      });
    }
  }

  void onDisconnect(String id) {
    setState(() {
      if (connectedDevicesCount > 0) connectedDevicesCount--;
      if (connectedDevicesCount == 0) connectedEndpointId = null;
    });
  }

  void sendMessage() {
    if (connectedEndpointId != null && msgController.text.trim().isNotEmpty) {
      Nearby().sendBytesPayload(
        connectedEndpointId!,
        Uint8List.fromList(msgController.text.codeUnits),
      );
      setState(() => messages.add("မိမိ: ${msgController.text}"));
      msgController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        title: Text("ချိတ်မိသော စက်: $connectedDevicesCount လုံး", style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, i) => ListTile(title: Text(messages[i])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: msgController, decoration: const InputDecoration(hintText: "စာတို ရိုက်ပါ..."))),
                IconButton(icon: const Icon(Icons.send, color: Colors.teal), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
