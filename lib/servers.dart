import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:servermanagerui/frame.dart';

import 'SubServer.dart';

class Servers extends StatefulWidget {
  const Servers({Key? key}) : super(key: key);

  @override
  _ServersState createState() => _ServersState();
}

class _ServersState extends State<Servers> {
  var _query = new QueryBuilder<SubServer>(SubServer());

  @override
  Widget build(BuildContext context) {
    return Frame(
        title: "Servers",
        actCB: () {
          showDialog<bool>(
            context: context,
            builder: (context) {
              return StatefulBuilder(builder: (context, setState) {
                return CreateServerDialog(context);
              });
            },
          ).then((value) {
            if (value!) {
            } else {}
          });
        },
        body: Padding(
          padding: EdgeInsets.all(5),
          child: ParseLiveListWidget<SubServer>(
            query: _query,
            lazyLoading: false,
            childBuilder: (context, snapshot) {
              if (snapshot.hasData) {
                return StreamBuilder<PM2Description?>(
                  stream: snapshot.loadedData!.descriptionStream,
                  initialData: null,
                  builder: (context, snapDesc) => snapDesc.data != null
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
                                    0.0), //position where you want to show the menu on screen
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
          ),
        ));
  }
}

class CreateServerDialog extends Dialog {
  CreateServerDialog(context) : super(child: buildChilds(context));

  static buildChilds(context) {
    var _createFromKey = GlobalKey<FormState>();
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Form(
          key: _createFromKey,
          child: Column(
            children: [
              Text("Test"),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Validate returns true if the form is valid, or false otherwise.
                        if (_createFromKey.currentState!.validate()) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
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
  }
}
