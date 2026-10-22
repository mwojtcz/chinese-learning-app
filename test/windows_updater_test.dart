import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/services/windows_updater.dart';

void main() {
  Map<String, dynamic> validManifest() => {
        'version': '1.4.0+5',
        'buildNumber': 42,
        'archiveName': 'ChineseLearningApp-Windows.zip',
        'downloadUrl': Uri.https(
          'github.com',
          '/mwojtcz/chinese-learning-app/releases/download/windows-latest/ChineseLearningApp-Windows.zip',
        ).toString(),
        'sha256': 'a' * 64,
      };

  test('parses a valid SHA-256 update manifest', () {
    final update = WindowsUpdate.fromManifest({
      ...validManifest(),
      'sha256': 'A' * 64,
    });

    expect(update.version, '1.4.0+5');
    expect(update.buildNumber, 42);
    expect(update.sha256, 'a' * 64);
    expect(update.downloadUrl.scheme, 'https');
  });

  test('rejects insecure download URLs', () {
    expect(
      () => WindowsUpdate.fromManifest({
        ...validManifest(),
        'downloadUrl': 'http://github.com/example/app.zip',
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed checksums and unexpected archive names', () {
    expect(
      () => WindowsUpdate.fromManifest({
        ...validManifest(),
        'sha256': 'not-a-checksum',
      }),
      throwsFormatException,
    );
    expect(
      () => WindowsUpdate.fromManifest({
        ...validManifest(),
        'archiveName': 'unexpected.zip',
      }),
      throwsFormatException,
    );
  });
}
