import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:servermanagerui/api_servers.dart';
import 'package:servermanagerui/globals.dart';

class ServerChooser extends StatefulWidget {
  ServerChooser({Key? key}) : super(key: key);

  @override
  _ServerChooserState createState() => _ServerChooserState();
}

class _ServerChooserState extends State<ServerChooser> {
  List<APIServer>? _data;
  var _name = TextEditingController();
  var _host = TextEditingController();
  var _port = TextEditingController(text: "80");
  String _scheme = "http";
  var _path = TextEditingController();

  @override
  Widget build(BuildContext context) {
    getData();
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Server"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (cntx) {
              var _createFromKey = GlobalKey<FormState>();
              return StatefulBuilder(
                builder: (context, setState) {
                  return Dialog(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Center(
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
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButton<String>(
                                      items: <String>['http', 'https']
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: new Text(value),
                                        );
                                      }).toList(),
                                      value: _scheme,
                                      onChanged: (value) {
                                        setState(() {
                                          _scheme = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  hintText:
                                  'Host on which the Server is running',
                                  labelText: 'Host *',
                                ),
                                controller: _host,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a host';
                                  }
                                  return null;
                                },
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  hintText:
                                  'Port on which the Server is running',
                                  labelText: 'Port *',
                                ),
                                controller: _port,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a port';
                                  }
                                  return null;
                                },
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Path on which the Server runs',
                                  labelText: 'Path *',
                                ),
                                controller: _path,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a path';
                                  }
                                  return null;
                                },
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        // Validate returns true if the form is valid, or false otherwise.
                                        if (_createFromKey.currentState!
                                            .validate()) {
                                          Navigator.of(cntx).pop(true);
                                        }
                                      },
                                      child: const Text('Submit'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(cntx).pop(false);
                                      },
                                      child: const Text('Abort'),
                                      style: ElevatedButton.styleFrom(
                                          primary: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ).then((value) async {
            if (value) {
              APIServer server = new APIServer(
                  _name.value.text,
                  _host.value.text,
                  int.parse(_port.value.text),
                  _path.value.text,
                  _scheme);
              String serverJSON = jsonEncode(server.toJson());
              var store = await CoreStoreSharedPrefsImp.getInstance();
              var apiServers = await store.getStringList("APIServers");
              if (apiServers == null) {
                apiServers = new List<String>.empty(growable: true);
              }
              apiServers.add(server.name);
              await store.setString("APIServers-" + server.name, serverJSON);
              await store.setStringList("APIServers", apiServers);
            }
          });
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        child: _data != null
            ? (_data!.length != 0
            ? getList(context)
            : RefreshIndicator(
          child: ListView.builder(
            itemCount: 1,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                child: Center(
                  child: Text("No Data"),
                ),
              );
            },
          ),
          onRefresh: getData,
        ))
            : Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _data!.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _data!.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  buildChilds(BuildContext context, APIServer elementAt) {
    return GestureDetector(
      onTap: () {
        apiServer = elementAt;
        Navigator.pushReplacementNamed(context, "/");
      },
      child: Card(
        child: ListTile(
          leading: FutureBuilder<bool>(
            future: elementAt.isAlive(),
            initialData: false,
            builder: (context, snapshot) => snapshot.data!
                ? Icon(Icons.check_circle_outline, color: Colors.green)
                : Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
          ),
          title: Text(elementAt.name),
          subtitle: Text(elementAt.scheme +
              "://" +
              elementAt.host +
              (elementAt.port != 80 ? ":" + elementAt.port.toString() : "") +
              elementAt.path),
          trailing: MaterialButton(
            onPressed: () {
              showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(25.0, 100.0, 0.0,
                    0.0), //position where you want to show the menu on screen
                items: [
                  PopupMenuItem<String>(
                      child: const Text('Delete'), value: '1'),
                ],
                elevation: 8.0,
              ).then<void>((String? value) async {
                switch (value) {
                  case "1":
                    var store = await CoreStoreSharedPrefsImp.getInstance();
                    var apiServers = await store.getStringList("APIServers");
                    if (apiServers != null) {
                      apiServers.remove(elementAt.name);
                    } else {
                      apiServers = List<String>.empty(growable: true);
                    }
                    await store.setStringList("APIServers", apiServers);
                    await store.remove("APIServers-" + elementAt.name);
                    break;
                }
                return;
              });
            },
            child: Icon(Icons.more_vert),
          ),
        ),
      ),
    );
  }

  Future<void> getData() async {
    var store = await CoreStoreSharedPrefsImp.getInstance();
    var apiServers = await store.getStringList("APIServers");
    if (apiServers == null) {
      _data = List<APIServer>.empty(growable: true);
    } else {
      _data = List<APIServer>.empty(growable: true);
      for (var apiServerName in apiServers) {
        var apiServerJSON =
        await store.getString("APIServers-" + apiServerName);
        APIServer server = APIServer.fromJson(jsonDecode(apiServerJSON!));
        _data!.add(server);
      }
    }

    setState(() {
      _data = _data;
    });
  }
}