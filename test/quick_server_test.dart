import 'package:quick_server/quick_server.dart';
import 'package:quick_server/service/server.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = QuickServer(ServerConfig());

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isRunning, isTrue);
    });
  });
}
