import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';

Future<void> savePortableFile({
  required String suggestedName,
  required List<int> bytes,
  String mimeType = 'application/json',
}) async {
  final location = await getSaveLocation(suggestedName: suggestedName);
  if (location == null) return;
  await XFile.fromData(
    Uint8List.fromList(bytes),
    mimeType: mimeType,
    name: suggestedName,
  ).saveTo(location.path);
}
