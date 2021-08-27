
import 'package:http/http.dart' as http;

class APIServer {

  final String host;
  final int port;
  final String path;
  final String name;
  final String scheme;


  APIServer(this.name, this.host, this.port, this.path, this.scheme);

  APIServer.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        port = json['port'],
        path = json['path'],
        scheme = json['scheme'],
        host = json['host'];

  Map<String, dynamic> toJson() => {
    'host': host,
    'name': name,
    'path': path,
    'scheme': scheme,
    'port': port
  };

  Future<bool> isAlive() async{

    var healthCheck = new Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path + "/health"
    );
    try {
      var resp = await http.Client().get(healthCheck);
      if (resp.statusCode == 200) {
        return true;
      }
    }catch(e){
    }
    return false;
  }

  Uri? getUri() {
    return new Uri(
        scheme: scheme,
        host: host,
        port: port,
        path: path
    );
  }

}