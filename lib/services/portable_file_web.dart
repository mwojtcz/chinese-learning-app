import 'dart:async';
import 'dart:typed_data';
// Browser downloads do not expose a native save-location picker.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> savePortableFile({
  required String suggestedName,
  required List<int> bytes,
  String mimeType = 'application/json',
}) async {
  final url = html.Url.createObjectUrlFromBlob(
    html.Blob([Uint8List.fromList(bytes)], mimeType),
  );
  final link = html.AnchorElement(href: url)..download = suggestedName;
  html.document.body!.append(link);
  link.click();
  link.remove();
  Timer(const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
