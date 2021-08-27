
import 'package:flutter/foundation.dart';
import 'package:servermanagerui/api_servers.dart';
APIServer? apiServer = kIsWeb ? new APIServer("Server Manager", Uri.base.host, Uri.base.port, "/api", Uri.base.scheme) : null;