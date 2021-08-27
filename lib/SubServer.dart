import 'dart:async';

import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:rxdart/rxdart.dart';
import 'package:servermanagerui/globals.dart';
import 'package:http/http.dart' as http;


class SubServer extends ParseObject {
  StreamSubscription<Future<Null>>? _refreshStream;
  SubServer() : super("Server"){
    init();
  }
  SubServer.clone(): this();

  /// Looks strangely hacky but due to Flutter not using reflection, we have to
  /// mimic a clone
  @override clone(Map<String,dynamic> map) => SubServer.clone()..fromJson(map)..init();

  String? get name => get<String?>("Name");

   set name(String? value) => set<String?>("Name", value);

  final BehaviorSubject<PM2Description?>_description = BehaviorSubject<PM2Description?>();

  Stream<PM2Description?> get descriptionStream => _description.stream;

  void dispose() {
    _description.close();
    if(_refreshStream != null) {
      _refreshStream!.cancel();
    }
  }

  refreshDescription() async {
    try {
      var resp = await ParseCloudFunction("GetServerInfo").execute(parameters: {"ServerId":this.objectId});
      if (resp.success) {
        return PM2Description.fromJson(resp.result);
      }else{
        PM2Description();
      }
    }catch(e){
    }
    return PM2Description();
  }

  init() {
    if(this.objectId != null
    && _refreshStream == null) {
      _refreshStream =
          new Stream.periodic(Duration(seconds: 5), (period) async {
            _description.add(await refreshDescription());
          }).listen((event) {});
    }
  }
}

class PM2Description {

  final PM2DescriptionENV pm2Env;
  final PM2Monit monit;

  PM2Description():
      pm2Env = PM2DescriptionENV(),
      monit = PM2Monit();

  PM2Description.fromJson(Map<String, dynamic> json)
      : pm2Env = PM2DescriptionENV.fromJson(json["pm2_env"]),
        monit = PM2Monit.fromJson(json["monit"]);

  Map<String, dynamic> toJson() => {
    'pm2_evn': pm2Env.toJson(),
    'monit' : monit.toJson()
  };

}

class PM2DescriptionENV {

  final String status;

  PM2DescriptionENV():
    status = "not installed";

  PM2DescriptionENV.fromJson(Map<String, dynamic> json)
      : status = json["status"];

  Map<String, dynamic> toJson() => {
    'status': status
  };

}
class PM2Monit {

  final int cpu;
  final int memory;

  PM2Monit():
        cpu = 0,
        memory = 0;

  PM2Monit.fromJson(Map<String, dynamic> json)
      : cpu = json["cpu"],
        memory = json["memory"];

  Map<String, dynamic> toJson() => {
    'cpu': cpu,
    'memory': memory
  };

}