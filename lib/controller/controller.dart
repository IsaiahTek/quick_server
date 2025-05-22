import 'dart:io';

import 'package:quick_server/service/template_service.dart';

abstract class Controller {
  late HttpRequest request;
  late HttpResponse response;
  Controller({required this.request});

  void view(String path, {Map<String, dynamic>? data})async{
    print("Routing: $path");
    if(data != null){
      int startedAt = DateTime.now().millisecondsSinceEpoch;
      final templateDir = Directory.fromUri(Platform.script.resolve('template/'));
      Template template = await Template.fromFile("${templateDir.path}$path");
      request.response.headers.contentType = ContentType.html;
      request.response.statusCode = HttpStatus.ok;
      int duration = DateTime.now().millisecondsSinceEpoch - startedAt;
      data = {...data, "durationInMilliseconds": duration};
      final result = template.render(data);
      request.response.write(result);
      request.response.close();
    }else{
      final staticDir = Directory.fromUri(Platform.script.resolve('public/'));
      final composedPath = request.uri.path == '/' ? 'index.html' : path;
      final file = File('${staticDir.path}$composedPath');

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
  }

  static void index(){}

  void show(){}

  void create(){}

  void edit(){}

  void update(){}

  void delete(){}
}