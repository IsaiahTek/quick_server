import 'dart:io';

class Template {
  final String template;

  Template(this.template);

  String render(Map<String, dynamic> context) {
    var output = template;
    for (final key in context.keys) {
      output = output.replaceAll('{{$key}}', context[key].toString());
    }
    return output;
  }

  static Future<Template> fromFile(String path) async {
    final content = await File(path).readAsString();
    return Template(content);
  }
}
