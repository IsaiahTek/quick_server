import 'dart:io';

class ServerConfig{
  int port;
  bool startImmediately;
  ServerConfig({this.port=0, this.startImmediately = true});
}

class RouteModel{
  Handler handler;
  String path;
  String method;
  List<Map<String, String>>? routeParams;
  Map<String, int>? staticPartsOrder;

  getMatchedParams(String actualPath){
    // Replace each :param with a named capture group using the ref list
    String regexPattern = path;

    for (final param in routeParams??[]) {
      final id = param['id']!;
      regexPattern = regexPattern.replaceFirst(':$id', '(?<$id>[^/]+)');
    }

    final regex = RegExp('^' + regexPattern + r'$', caseSensitive: false);
    final match = regex.firstMatch(actualPath);
    if (match == null) return null;

    return {
      for (final param in routeParams??[])
        param['id']!: match.namedGroup(param['id']!) ?? ''
    };
  }

  RouteModel({required this.handler, required this.path, required this.method, this.routeParams, this.staticPartsOrder});
}

typedef Handler = void Function(HttpRequest req, HttpResponse res, RouteModel? routeInfo);

class Server {
  late String address;
  late int port;
  String? ip;
  HttpServer? _server;

  bool isRunning = false;

  Server(ServerConfig config) {
    port = config.port;
    if (config.startImmediately) {
      start();
    }
  }

  Future<String?> _getLocalIPAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        return addr.address;
      }
    }
    return null;
  }

  Future<bool> start() async => _start();
  Future<bool> _start() async {
    if (isRunning) return true;
    try {
      ip = await _getLocalIPAddress();
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      address = _server!.address.address;
      port = _server!.port;
      isRunning = true;
      print('Server running on http://$address:$port (Local IP: $ip)');
      _listen();
      return true;
    } catch (e, st) {
      print('Failed to start server: $e\n$st');
      return false;
    }
  }

  void _handleStatic(HttpRequest request) async {
    final staticDir = Directory.fromUri(Platform.script.resolve('public/'));
    final path = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final file = File('${staticDir.path}$path');

    if (await file.exists()) {
      final ext = file.path.split('.').last;
      final contentType = {
        'html': ContentType.html,
        'css': ContentType('text', 'css'),
        'js': ContentType('application', 'javascript'),
      }[ext] ?? ContentType.text;

      request.response
        ..headers.contentType = contentType
        ..add(await file.readAsBytes())
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('404 - Not Found $file')
        ..close();
    }
  }

  void _handleWebSocket(HttpRequest request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    print('WebSocket connection established');

    socket.listen((data) {
      print('Received from client: $data');
      socket.add('Echo: $data');
    }, onDone: () {
      print('Client disconnected');
    });
  }

  final List<RouteModel> _routes = [];

  List<Map<String, String>> extractRouteParams(String routePattern) {
    final paramRegex = RegExp(r':(\w+)');
    final matches = paramRegex.allMatches(routePattern);

    return matches.map((match) {
      return {'id': match.group(1)!};
    }).toList();
  }

  Map<String, int> staticParts(String route){
    Map<String, int> x = {};
    List<String> parts = route.split('/');
    for (var part = 0; part < parts.length; part++) {
      if(!parts[part].startsWith(':')){
        x[parts[part]] = part;
      }
    }
    return x;
  }


  void get(String path, Handler handler) {
    List<Map<String, String>> dynamicParamIds = extractRouteParams(path);
    print("Request path: $path, $dynamicParamIds");
    _addRoute('GET', path, handler, dynamicParamIds, staticParts(path));
  }

  void post(String path, Handler handler) {
    _addRoute('POST', path, handler, extractRouteParams(path), staticParts(path));
  }

  void put(String path, Handler handler) {
    _addRoute('PUT', path, handler, extractRouteParams(path), staticParts(path));
  }

  void delete(String path, Handler handler) {
    _addRoute('DELETE', path, handler, extractRouteParams(path), staticParts(path));
  }

  void _addRoute(String method, String path, Handler handler, List<Map<String, String>> paramIds, Map<String, int> starticParts) {
    if(_routes.every((route)=>!(route.path == path && route.method == method))){
      print("Added route: $path; Method: $method");
      _routes.add(RouteModel(handler: handler, path: path, method: method, routeParams: paramIds, staticPartsOrder: starticParts));
    }else{
      print("Couldn't Add route: $path; Method: $method BECAUSE: ${_routes.map((route)=>"${route.path} - ${route.method}").toList()}");
    }
  }

  Map<String, String>? matchRealPath(
    String routePattern,
    String actualPath,
    List<Map<String, String>> paramRefs
  ) {
    // Replace each :param with a named capture group using the ref list
    String regexPattern = routePattern;

    for (final param in paramRefs) {
      final id = param['id']!;
      regexPattern = regexPattern.replaceFirst(':$id', '(?<$id>[^/]+)');
    }

    final regex = RegExp('^' + regexPattern + r'$');
    final match = regex.firstMatch(actualPath);
    if (match == null) return null;

    return {
      for (final param in paramRefs)
        param['id']!: match.namedGroup(param['id']!) ?? ''
    };
  }

  RouteModel? getDynamicRoute(String path){
    List<String> parts = path.split('/');
    bool isSameRoute(Map<String, int> sP){
      return sP.entries.every((sPart)=> parts[sPart.value].toLowerCase() == sPart.key.toLowerCase());
    }
    return _routes.where((route)=>route.path.split('/').length == path.split('/').length && route.routeParams != null && isSameRoute(route.staticPartsOrder!)).firstOrNull;
  }


  void _listen() {
    _server?.listen((HttpRequest req) async {

      final path = req.uri.path;

      final currentRoute = _routes.where((route)=>route.method.toLowerCase() == req.method.toLowerCase() && route.path == path).firstOrNull??getDynamicRoute(path);

      print("ROUTE: ${currentRoute?.method}: ${currentRoute?.path} - ${currentRoute?.routeParams} - ${currentRoute?.getMatchedParams(path)} PATH: $path REQUEST METHOD: ${req.method} REQUEST PATH: ${req.uri.path}");

      final handler = currentRoute?.handler;

      if (handler != null) {
        handler(req, req.response, currentRoute!);
      } else {
        if (req.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(req)) {
          _handleWebSocket(req);
        }else{
          print("Listener found: ${req.requestedUri}");
          _handleStatic(req);
        }
      }

      // if (request.method == 'GET' && request.uri.path == '/up') {
      //   Up(request: request).index();
      // } else if (request.method == 'GET' && request.uri.path == '/down') {
      //   await shotdown();
      //   request.response
      //     ..statusCode = 200
      //     ..write('Server shutting down')
      //     ..close();
      // } else {
      //   if (request.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
      //     _handleWebSocket(request);
      //   } else {
      //     _handleStatic(request);
      //   }
      // }
    });
  }

  Future<bool> shotdown() async => _shotdown();

  Future<bool> _shotdown() async {
    try {
      await _server?.close(force: true);
      isRunning = false;
      print('Server shut down on http://$address:$port (Local IP: $ip)');
      return true;
    } catch (e) {
      print('Error shutting down: $e');
      return false;
    }
  }
}
