import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> saveInvoiceBytes(Uint8List bytes, String filename) async {
  final downloads = await getDownloadsDirectory();
  final baseDirectory = downloads ?? await getApplicationDocumentsDirectory();
  final invoiceDirectory = Directory('${baseDirectory.path}/DoorMart Invoices');
  await invoiceDirectory.create(recursive: true);
  final file = File('${invoiceDirectory.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
