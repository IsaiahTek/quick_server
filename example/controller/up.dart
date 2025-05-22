import 'package:quick_server/controller/controller.dart';
import 'package:quick_server/service/server.dart';

class UpController extends Controller {

  UpController({required super.request});

  void index(RouteModel route)async{
    view('health.html', data: {"username": route.getMatchedParams(request.uri.path)['name']});
  }

}