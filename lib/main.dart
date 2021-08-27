import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:servermanagerui/SubServer.dart';
import 'package:servermanagerui/globals.dart';
import 'package:servermanagerui/server_chooser.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart' as sdk;
import 'package:servermanagerui/servers.dart';

import 'dashboard.dart';
import 'login.dart';

void main() {
  runApp(ServerManagerApp());
}

class ServerManagerApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => kIsWeb || !kIsWeb && apiServer != null
            ? HomeScreen()
            : ServerChooser(),
        "/home": (context) => Dashboard(),
        "/servers": (context) => Servers()
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Future<Parse> parseInit;

  HomeScreen({Key? key})
      : parseInit = _initParse(),
        super(key: key);
  static Future<Parse> _initParse() async {
    return await Parse().initialize(
        "com.mabenan.servermanager", apiServer!.getUri().toString(),
        liveQueryUrl: apiServer!.getUri()!.replace(scheme: "ws", path: "").toString(),
        registeredSubClassMap: {  'Server': () => SubServer(), },
        coreStore: kIsWeb
            ? await CoreStoreSharedPrefsImp.getInstance()
            : await sdk.CoreStoreSembastImp.getInstance(apiServer!.host));
  }

  @override
  _HomeScreenState createState() => _HomeScreenState(parseInit);
}

class _HomeScreenState extends State<HomeScreen> {
  final Future<Parse> parseInit;

  _HomeScreenState(this.parseInit);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Parse>(
      future: parseInit,
      builder: (context, snapshot) => snapshot.data != null
          ? LoginWidget(
              loginCB: (value) {
                setState(() {
                  if(value == "login")
                  Navigator.of(context).pushReplacementNamed("/home");
                  else
                    Navigator.of(context).pushReplacementNamed("/");

                });
              },
            )
          : CircularProgressIndicator(),
    );
  }
}
