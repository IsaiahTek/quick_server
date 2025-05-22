import 'package:quick_server/service/server.dart';

import 'controller/home.dart';
import 'controller/modern_css_demo.dart';
import 'controller/up.dart';

void main() {
  final app = Server(ServerConfig(port: 8080));
  app.get('/', (req, res, routeInfo) => HomeController(request: req).index());
  app.get('/health/:name', (req, res, routeInfo) => UpController(request: req).index(routeInfo!));
  app.post('/ask', (req, res, routeInfo)=>HomeController(request: req).ask(req));
  app.get('/modern-css-features', (req, res, routeInfo)=>ModernCssDemoController(request: req).index());
}
