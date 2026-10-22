/// Web/no-filesystem fallback: legacy SQLite files cannot exist here.
Future<bool> legacyFileExists(String path) async => false;
