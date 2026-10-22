import 'dart:io';

/// Checks the legacy database file without loading SQLite.
Future<bool> legacyFileExists(String path) => File(path).exists();
