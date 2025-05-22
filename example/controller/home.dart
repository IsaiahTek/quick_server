import 'dart:convert';
import 'dart:io';

import 'package:quick_server/controller/controller.dart';

class HomeController extends Controller {
  HomeController({required super.request});
  
  void index(){
    print("Called index()");
    view('/');
  }

  void ask(HttpRequest request)async{
    request.response.write(await utf8.decoder.bind(request).join());
    request.response.close();
  }
}