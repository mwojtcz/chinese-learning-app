import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('display rebranding preserves the Windows preferences directory', () {
    final resources =
        File(path.join('windows', 'runner', 'Runner.rc')).readAsStringSync();
    expect(resources, contains('"CompanyName", "com.example"'));
    expect(resources, contains('"ProductName", "chinese_learning_app"'));
    expect(
        resources, contains('"OriginalFilename", "chinese_learning_app.exe"'));
  });
}
