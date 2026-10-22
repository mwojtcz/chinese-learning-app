// Native updater implementation selected by the conditional export.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.6.0+7',
);
const appBuildNumber = int.fromEnvironment('APP_BUILD_NUMBER', defaultValue: 0);

class WindowsUpdate {
  const WindowsUpdate({
    required this.version,
    required this.buildNumber,
    required this.sha256,
    required this.downloadUrl,
  });

  final String version;
  final int buildNumber;
  final String sha256;
  final Uri downloadUrl;

  factory WindowsUpdate.fromManifest(Map<String, dynamic> manifest) {
    final buildNumber = manifest['buildNumber'];
    final version = manifest['version'];
    final checksum = manifest['sha256'];
    final archiveUrl = Uri.tryParse(manifest['downloadUrl'] as String? ?? '');
    if (buildNumber is! int ||
        buildNumber < 1 ||
        version is! String ||
        version.trim().isEmpty ||
        checksum is! String ||
        !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(checksum) ||
        archiveUrl == null ||
        archiveUrl.scheme != 'https' ||
        archiveUrl.host != 'github.com' ||
        manifest['archiveName'] != 'ChineseLearningApp-Windows.zip') {
      throw const FormatException('Invalid Windows update manifest fields.');
    }
    return WindowsUpdate(
      version: version,
      buildNumber: buildNumber,
      sha256: checksum.toLowerCase(),
      downloadUrl: archiveUrl,
    );
  }
}

class WindowsUpdater {
  static const _repository = 'mwojtcz/chinese-learning-app';
  static const _releaseTag = 'windows-latest';
  static const _manifestName = 'windows-update.json';
  static const _executableName = 'chinese_learning_app.exe';

  static Future<WindowsUpdate?> checkForUpdate() async {
    if (!Platform.isWindows) return null;

    final client = _newClient();
    try {
      return await fetchUpdate(client);
    } finally {
      client.close(force: true);
    }
  }

  static Future<WindowsUpdate?> fetchUpdate(
    HttpClient client, {
    int currentBuildNumber = appBuildNumber,
  }) async {
    // Release assets do not consume the unauthenticated GitHub API quota.
    final response = await _get(
      client,
      Uri.https(
        'github.com',
        '/$_repository/releases/download/$_releaseTag/$_manifestName',
      ),
    );
    final manifest = jsonDecode(await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 30)));
    if (manifest is! Map<String, dynamic>) {
      throw const FormatException('Invalid Windows update manifest.');
    }
    final update = WindowsUpdate.fromManifest(manifest);
    if (update.buildNumber <= currentBuildNumber) return null;
    return update;
  }

  static Future<void> downloadAndInstall(
    WindowsUpdate update, {
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Windows updates are only available on Windows.');
    }
    final executable = File(Platform.resolvedExecutable);
    final installDirectory = executable.parent;
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) {
      throw StateError('The Windows user data directory is unavailable.');
    }

    final updateDirectory = Directory(
      '$localAppData${Platform.pathSeparator}Cika${Platform.pathSeparator}updates',
    );
    await updateDirectory.create(recursive: true);
    final archive = File(
      '${updateDirectory.path}${Platform.pathSeparator}windows-update-${update.buildNumber}.zip',
    );

    final client = _newClient();
    try {
      final response = await _get(client, update.downloadUrl);
      final expectedLength = response.contentLength;
      var received = 0;
      var lastReportedPercent = -1;
      final sink = archive.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (expectedLength > 0) {
            final percent = (received * 100 / expectedLength).floor();
            if (percent != lastReportedPercent) {
              lastReportedPercent = percent;
              onProgress?.call(received / expectedLength);
            }
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }

    final actualChecksum = await sha256.bind(archive.openRead()).first;
    if (actualChecksum.toString().toLowerCase() != update.sha256) {
      await archive.delete();
      throw const FormatException(
        'Downloaded Windows update failed its SHA-256 integrity check.',
      );
    }

    final script = File(
      '${updateDirectory.path}${Platform.pathSeparator}install-update.ps1',
    );
    await script.writeAsString(_installerScript, encoding: utf8, flush: true);
    final process = await Process.start(
      'powershell.exe',
      [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        script.path,
        '-ArchivePath',
        archive.path,
        '-InstallDirectory',
        installDirectory.path,
        '-ProcessId',
        pid.toString(),
        '-ExecutableName',
        _executableName,
      ],
      mode: ProcessStartMode.detached,
      workingDirectory: updateDirectory.path,
    );
    if (process.pid == 0) {
      throw StateError('Could not start the Windows update helper.');
    }
    exit(0);
  }

  static HttpClient _newClient() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..userAgent = 'Polski-Chinese-Updater';

  static Future<HttpClientResponse> _get(
    HttpClient client,
    Uri uri,
  ) async {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 30));
    request.followRedirects = true;
    final response = await request.close().timeout(const Duration(minutes: 2));
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'GitHub returned HTTP ${response.statusCode} while checking for updates.',
        uri: uri,
      );
    }
    return response;
  }
}

const _installerScript = r'''
param(
  [Parameter(Mandatory = $true)][string]$ArchivePath,
  [Parameter(Mandatory = $true)][string]$InstallDirectory,
  [Parameter(Mandatory = $true)][int]$ProcessId,
  [Parameter(Mandatory = $true)][string]$ExecutableName
)
$ErrorActionPreference = 'Stop'
$install = [IO.Path]::GetFullPath($InstallDirectory).TrimEnd('\')
$parent = Split-Path -Parent $install
$leaf = Split-Path -Leaf $install
$token = [Guid]::NewGuid().ToString('N')
$staging = Join-Path $parent ".$leaf-update-$token"
$backup = Join-Path $parent ".$leaf-backup-$token"
$swapped = $false
try {
  Wait-Process -Id $ProcessId -ErrorAction SilentlyContinue
  [IO.Directory]::CreateDirectory($staging) | Out-Null
  Get-ChildItem -LiteralPath $install -Force |
    Copy-Item -Destination $staging -Recurse -Force
  Expand-Archive -LiteralPath $ArchivePath -DestinationPath $staging -Force
  if (-not (Test-Path -LiteralPath (Join-Path $staging $ExecutableName))) {
    throw 'The downloaded package does not contain the application executable.'
  }
  Move-Item -LiteralPath $install -Destination $backup
  try {
    Move-Item -LiteralPath $staging -Destination $install
    $swapped = $true
    $started = Start-Process -FilePath (Join-Path $install $ExecutableName) -WorkingDirectory $install -PassThru
    Start-Sleep -Seconds 10
    $started.Refresh()
    if ($started.HasExited) {
      throw 'The updated application did not remain running.'
    }
  } catch {
    if ($swapped -and (Test-Path -LiteralPath $install)) {
      Remove-Item -LiteralPath $install -Recurse -Force
    }
    if (Test-Path -LiteralPath $backup) {
      Move-Item -LiteralPath $backup -Destination $install
      Start-Process -FilePath (Join-Path $install $ExecutableName)
    }
    throw
  }
  try {
    Remove-Item -LiteralPath $backup -Recurse -Force
  } catch {
    Write-Warning "The update succeeded but the old app backup could not be removed: $backup"
  }
} catch {
  $logPath = Join-Path $env:LOCALAPPDATA 'Cika\update-error.log'
  [IO.Directory]::CreateDirectory((Split-Path -Parent $logPath)) | Out-Null
  [IO.File]::WriteAllText($logPath, $_.ToString())
  try {
    Add-Type -AssemblyName PresentationFramework
    $message = "The update could not be installed. Your previous app version was restored if needed."
    $message += "`n`n$($_.Exception.Message)`n`nDetails: $logPath"
    [System.Windows.MessageBox]::Show(
      $message,
      'Polski - Chinese update',
      'OK',
      'Error'
    ) | Out-Null
  } catch {}
} finally {
  if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force
  }
  if (Test-Path -LiteralPath $ArchivePath) {
    Remove-Item -LiteralPath $ArchivePath -Force
  }
}
''';
