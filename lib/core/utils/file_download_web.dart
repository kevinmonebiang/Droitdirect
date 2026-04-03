import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> downloadPdfBytes({
  required List<int> bytes,
  required String fileName,
}) async {
  final data = Uint8List.fromList(bytes);
  final blob = html.Blob([data], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = fileName;
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
