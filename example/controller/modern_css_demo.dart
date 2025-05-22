import 'package:quick_server/controller/controller.dart';

class ModernCssDemoController extends Controller{
  ModernCssDemoController({required super.request});
  index(){
    view('modern-css-features.html');
  }
}