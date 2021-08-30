import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:servermanager/SubServer.dart';
import 'package:servermanager/globals.dart';
import 'package:servermanager/server_chooser.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart' as sdk;
import 'package:servermanager/servers.dart';
import 'package:path/path.dart' as path;

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
            : await sdk.CoreStoreSembastImp.getInstance(await dbDirectory(apiServer!.host)));
  }

  static Future<String> dbDirectory(String dbName) async {
    String dbDirectory = '';
    if (!sdk.parseIsWeb &&
        (Platform.isIOS ||
            Platform.isAndroid ||
            Platform.isMacOS ||
            Platform.isLinux ||
            Platform.isWindows)) {
      dbDirectory = (await getApplicationDocumentsDirectory()).path;
    }
    return path.join('$dbDirectory/parse', dbName + '.db');
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
