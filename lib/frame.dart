import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:servermanager/globals.dart';

class Frame extends StatefulWidget {
  final Widget body;

  final String title;

  final Function? actCB;

  const Frame({Key? key, required this.body, required this.title, this.actCB})
      : super(key: key);

  @override
  _FrameState createState() =>
      _FrameState(this.body, this.title, actCB: this.actCB);
}

class _FrameState extends State<Frame> {
  final Widget body;

  final String title;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Function? actCB;

  _FrameState(this.body, this.title, {this.actCB});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: actCB != null
          ? FloatingActionButton(
              onPressed: () async {
                actCB!();
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.blue,
            )
          : null,
      appBar: AppBar(
        title: Text(this.title),
        actions: [
          !kIsWeb
              ? IconButton(
                  onPressed: () async {
                    apiServer = null;
                    Navigator.of(context).popUntil(ModalRoute.withName('/'));
                    Navigator.of(context).pushNamed('/');
                  },
                  icon: const Icon(Icons.list),
                )
              : Container(),
          IconButton(
            onPressed: () async {
              ((await ParseUser.currentUser()) as ParseUser).logout();
              Navigator.of(context).popUntil(ModalRoute.withName('/'));
              Navigator.of(context).pushNamed('/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        leadingWidth: 80,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState!.openDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
            IconButton(
              onPressed: () async {
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.arrow_back),
            ),
          ],
        ),
      ),
      body: this.body,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                apiServer!.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () => nav("/home"),
            ),
            ListTile(
              leading: Icon(Icons.cloud),
              title: Text('Servers'),
              onTap: () => nav("/servers"),
            ),
          ],
        ),
      ),
    );
  }

  void nav(String routeName) {
    Navigator.of(_scaffoldKey.currentContext!).pop();
    if (ModalRoute.of(context)!.settings.name != routeName)
      Navigator.of(context).pushNamed(routeName);
  }
}
