import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/services/windows_updater_io.dart';

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

  late HttpServer server;
  late _ReleaseClient client;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = _ReleaseClient(server.port);
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  test('fetches the public release manifest without calling the GitHub API',
      () async {
    server.listen((request) {
      request.response.write(jsonEncode(validManifest()));
      request.response.close();
    });

    final update = await WindowsUpdater.fetchUpdate(
      client,
      currentBuildNumber: 41,
    );

    expect(update?.buildNumber, 42);
    expect(client.requestedUrls, [
      Uri.https(
        'github.com',
        '/mwojtcz/chinese-learning-app/releases/download/windows-latest/windows-update.json',
      ),
    ]);
  });

  test('does not offer an installed or older build', () async {
    server.listen((request) {
      request.response.write(jsonEncode(validManifest()));
      request.response.close();
    });

    for (final build in [42, 43]) {
      expect(
        await WindowsUpdater.fetchUpdate(client, currentBuildNumber: build),
        isNull,
      );
    }
  });

  test('surfaces HTTP failures instead of reporting an up-to-date app', () async {
    server.listen((request) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    });

    await expectLater(
      WindowsUpdater.fetchUpdate(client),
      throwsA(isA<HttpException>()),
    );
  });

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

class _ReleaseClient extends Fake implements HttpClient {
  _ReleaseClient(this.port);

  final int port;
  final _client = HttpClient();
  final requestedUrls = <Uri>[];

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    requestedUrls.add(url);
    return _client.getUrl(Uri.http('127.0.0.1:$port', url.path));
  }

  @override
  void close({bool force = false}) => _client.close(force: force);
}
