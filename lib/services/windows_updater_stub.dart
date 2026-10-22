const appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.4.0+5',
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

  factory WindowsUpdate.fromManifest(Map<String, dynamic> manifest) =>
      throw UnsupportedError('Windows updates are not available on this platform.');
}

class WindowsUpdater {
  static Future<WindowsUpdate?> checkForUpdate() async => null;

  static Future<void> downloadAndInstall(
    WindowsUpdate update, {
    void Function(double progress)? onProgress,
  }) async {
    throw UnsupportedError('Windows updates are not available on this platform.');
  }
}
