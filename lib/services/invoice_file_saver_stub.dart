import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

Future<String?> saveInvoiceBytes(Uint8List bytes, String filename) async {
  final location = await getSaveLocation(
    suggestedName: filename,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF document', extensions: ['pdf']),
    ],
    confirmButtonText: 'Download',
  );
  if (location == null) return null;

  await XFile.fromData(
    bytes,
    mimeType: 'application/pdf',
    name: filename,
  ).saveTo(location.path);
  return location.path;
}
