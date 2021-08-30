import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:servermanager/frame.dart';

import 'SubServer.dart';

class Servers extends StatefulWidget {
  const Servers({Key? key}) : super(key: key);

  @override
  _ServersState createState() => _ServersState();
}

class _ServersState extends State<Servers> {
  var _query = new QueryBuilder<SubServer>(SubServer());

  ParseLiveListWidget<SubServer>? liveListWidget;

  @override
  void dispose() {
    liveListWidget = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Frame(
        title: "Servers",
        actCB: () {
          showDialog<SubServer?>(
            context: context,
            builder: (context) {
              return StatefulBuilder(builder: (context, setState) {
                return CreateServerDialog(context);
              });
            },
          ).then((value) async {
            if (value != null) {
              await value.create();
            } else {}
          });
        },
        body: Padding(
          padding: EdgeInsets.all(5),
          child: buildParseLiveListWidget(),
        ));
  }

  ParseLiveListWidget<SubServer> buildParseLiveListWidget() {
    if(liveListWidget == null) {
      liveListWidget = ParseLiveListWidget<SubServer>(
        query: _query,
        lazyLoading: false,
        childBuilder: (context, snapshot) {
          if (snapshot.hasData) {
            return StreamBuilder<PM2Description?>(
              stream: snapshot.loadedData!.descriptionStream,
              initialData: null,
              builder: (context, snapDesc) =>
              snapDesc.data != null
                  ? ListTile(
                leading: snapDesc.data!.pm2Env.status == "online"
                    ? Icon(Icons.check_circle_outline,
                    color: Colors.green)
                    : Tooltip(
                  message: snapDesc.data!.pm2Env.status,
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                ),
                title: Text(snapshot.loadedData!.name!),
                subtitle: Text("CPU: " +
                    snapDesc.data!.monit.cpu.toString() +
                    "% RAM: " +
                    (snapDesc.data!.monit.memory / 8 / 1024 / 1024)
                        .round()
                        .toString() +
                    " MB"),
                trailing: MaterialButton(
                  onPressed: () {
                    showMenu<String>(
                      context: context,
                      position: RelativeRect.fromLTRB(
                          25.0,
                          100.0,
                          0.0,
                          0.0),
                      //position where you want to show the menu on screen
                      items: [
                        PopupMenuItem<String>(
                          child: const Text('Start'),
                          value: '1',
                        ),
                        PopupMenuItem<String>(
                          child: const Text('Stop'),
                          value: '2',
                        ),
                        PopupMenuItem<String>(
                          child: const Text('Install'),
                          value: '3',
                        ),
                      ],
                      elevation: 8.0,
                    ).then<void>((String? value) async {
                      switch (value) {
                        case "1":
                          await ParseCloudFunction("StartServer")
                              .execute(parameters: {
                            "ServerId": snapshot.loadedData!.objectId
                          });
                          break;
                        case "2":
                          await ParseCloudFunction("StopServer")
                              .execute(parameters: {
                            "ServerId": snapshot.loadedData!.objectId
                          });
                          break;
                        case "3":
                          await ParseCloudFunction("InstallServer")
                              .execute(parameters: {
                            "ServerId": snapshot.loadedData!.objectId
                          });
                          break;
                      }
                      setState(() {});
                      return;
                    });
                  },
                  child: Icon(Icons.more_vert),
                ),
              )
                  : Card(child: CircularProgressIndicator()),
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      );
    }
    return liveListWidget!;
  }
}

class CreateServerDialog extends Dialog {
  static var _name = new TextEditingController();

  static var _api_path = new TextEditingController();

  static var _https_port = new TextEditingController(text: "443");
  static var _http_port = new TextEditingController(text: "80");

  static var _https = false;

  static var _database = new TextEditingController();

  static var _appid= new TextEditingController();

  static var _masterkey= new TextEditingController();

  static var _repo= new TextEditingController();

  static var _branch= new TextEditingController();

  static var _cloud_file= new TextEditingController();

  static var _init_file= new TextEditingController();

  CreateServerDialog(context) : super(child: buildChilds(context));

  static buildChilds(context) {
    var _createFromKey = GlobalKey<FormState>();
    return StatefulBuilder(
        builder: (context, setState)
    {
      return Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _createFromKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'Name on which the Server is identified',
                    labelText: 'Name *',
                  ),
                  controller: _name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'Path on which the Server provides is functions',
                    labelText: 'API PATH *',
                  ),
                  controller: _api_path,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a api path';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'HTTPS Port',
                    labelText: 'HTTPS PORT *',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  controller: _https_port,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a port';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'HTTP Port',
                    labelText: 'HTTP PORT *',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  controller: _http_port,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a port';
                    }
                    return null;
                  },
                ),
                CheckboxListTile(
                  title: Text("HTTPs"), //    <-- label
                  value: _https,
                  onChanged: (newValue) {
                    setState(() {
                      _https = newValue!;
                    });
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'database',
                    labelText: 'database *',
                  ),
                  controller: _database,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a database';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'AppId',
                    labelText: 'AppId *',
                  ),
                  controller: _appid,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a appid';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'MasterKey',
                    labelText: 'MasterKey *',
                  ),
                  controller: _masterkey,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a MasterKey';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'Repo',
                    labelText: 'Repo *',
                  ),
                  controller: _repo,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Repo';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'Branch',
                    labelText: 'Branch *',
                  ),
                  controller: _branch,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Branch';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'Cloud File',
                    labelText: 'Cloud File *',
                  ),
                  controller: _cloud_file,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Cloud File';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                    'Init File',
                    labelText: 'Init File *',
                  ),
                  controller: _init_file,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Init File';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Validate returns true if the form is valid, or false otherwise.
                          if (_createFromKey.currentState!.validate()) {
                            SubServer server = new SubServer();
                            server.name = _name.text;
                            server.apiPath = _api_path.text;
                            server.appId = _appid.text;
                            server.branch = _branch.text;
                            server.cloudEntry = _cloud_file.text;
                            server.initModule = _init_file.text;
                            server.database = _database.text;
                            server.httpPort = int.parse(_http_port.text);
                            server.httpsPort = int.parse(_https_port.text);
                            server.https = _https;
                            server.masterKey = _masterkey.text;
                            server.repo = _repo.text;
                            Navigator.of(context).pop(server);
                          }
                        },
                        child: const Text('Submit'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                        },
                        child: const Text('Abort'),
                        style: ElevatedButton.styleFrom(primary: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
